#
#  ROIseries_feature_somelier_transformers: transform input data from ROIseries
#  Copyright (C) 2017 Niklas Keck
#
#  This file is part of ROIseries.
#
#  ROIseries is free software: you can redistribute it and/or modify
#  it under the terms of the GNU Affero General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  ROIseries is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU Affero General Public License for more details.
#
#  You should have received a copy of the GNU Affero General Public License
#  along with ROIseries.  If not, see <http://www.gnu.org/licenses/>.
#

# TAF to TRF transformation
import pandas as pd
import numpy as np
from sklearn.base import BaseEstimator, TransformerMixin
import calendar
import ROIseries as rs


def timeindex_from_colsuffix(df):
    """
    Transform DataFrame from ID * feature_time format to time * (feature,id)

    Parameters
    ----------
    df : a DataFrame in the form ID * feature_time e.g.
          B_MEAN_RAW_2457633.9  B_MEAN_RAW_2457663.9
    R_ID
    1              2041.910891            803.970297
    3              1687.019608            1088.754902
    2              2388.691489            1005.478723
    4              1756.762162            698.162162
    """
    df = df.copy()

    cols = np.array([i.rsplit("_", 1) for i in df.columns])
    # since julian date origin is at noon, subtract 12 hours = half a day
    feature_time = list(zip(cols[:, 0],
                            pd.to_datetime(np.float32(cols[:, 1])-0.5,
                                           unit='D',
                                           origin='julian')))

    df.columns = pd.MultiIndex.from_tuples(
            feature_time, names=["feature", "time"])

    if df.index.name is None:
        df.index.name = 'original_id'

    rs.sub_routines.sort_index_columns_inplace(df)
    df = df.stack("feature").transpose()

    if df.index.is_unique:
        return df
    else:
        raise ValueError("The time is not unique for each feature and id")


def reltime_from_absdate(DatetimeIndex):
    """
    Transform a numeric 1D array with (array-min(array)) / mode(diff(array))

    This transformer has the following assumption
    - mode == min for time difference between adjacent time events

    Parameters
    ----------
    time_array : a 1D numeric array e.g.
        array([ 35.5, 45.5, 55.5, 65.5])

    Returns
    -------
    The transformed 1D numeric array e.g.
        array([0, 1, 2, 3])
    """

    if not DatetimeIndex.is_unique:
        raise ValueError("DatetimeIndex must be unique")

    t_delta = (DatetimeIndex[1:] - DatetimeIndex[0:-1])
    delta_mode = t_delta.to_series().mode()[0]

    if delta_mode == min(t_delta):
        print("detected time base: {}".format(delta_mode))
    else:
        raise ValueError("Mode and Min of differences of adjacent time events "
                         "must be equal")

    if any([i%delta_mode for i in t_delta]):
        raise ValueError("The difference of adjacent time events must be "
                         "a multiple of the delta_mode "
                         "(considering sign_digits)")
    else:
        reltime = (DatetimeIndex - min(DatetimeIndex)) / delta_mode
        # Found no option for direct delta_mode (pd.Timedelta) -> frequency conversion: detour via dummy time series:
        freq = pd.infer_freq([DatetimeIndex[0], DatetimeIndex[0] + delta_mode, DatetimeIndex[0] + delta_mode * 2])
        reltime.name = 'reltime'
        return reltime, freq


class TAFtoTRF(BaseEstimator, TransformerMixin):
    # TODO: This transformer should be split up into multiple transformers!
    """
    Transform a DataFrame holding TAF to TRF

    Example
    -------
    # get the csvs
    >>> import ROIseries as rs
    >>> import pandas as pd
    >>> csv = rs.sub_routines.file_search("C:/Users/keck/Desktop/delete_if_unknown/",".csv")
    >>> df_list = [pd.read_csv(i,index_col = 0) for i in csv] #)
    >>> df = pd.concat(df_list,axis=1)

    # make sure that index is string, else: some strange stack MultiIndex error
    >>> df.index = df.index.astype(str)
    >>> shift_dict = dict(zip(["m3","m2","m1","p1","p2","p3"],[-2,-1,0,1,2,3]))

    # do the transformation in a pipeline
    >>> from sklearn.pipeline import make_pipeline
    >>> t1=TAFtoTRF(shift_dict)
    >>> p1 = make_pipeline(t1)
    >>> dfx = p1.fit_transform(df)
    """
    def __init__(self, shift_dict, id_colname):
        self.shift_dict = shift_dict
        self.id_colname = id_colname

    def fit(self, x, y=None):
        return self

    def transform(self, x, y=None):
        """
            Transforms the features in a DataFrame from TAF to TRF

            Parameters
            ----------
            x : DataFrame of structure: time (index) * features (columns)
                multiple objects with different ids have to be represented as part
                of a MulitiIndex in the Column Headers e.g.

                feature              B_MAX_RAW                           B_MEAN_RAW
                R_ID                         1       3       2       4            1
                time         reltime
                2.457364e+06 0           902.0  1139.0   895.0  1071.0   580.702970
                2.457374e+06 1          9524.0  8508.0  8554.0  8599.0  8327.247525
                2.457384e+06 2          1119.0  1392.0  1187.0  1287.0   859.069307

            shift_dict: Dictionary that defines the names and the shifts applied in
                the TRF transformation. e.g. in the following example m2 -1 means that
                TRFs with a shift of -1 (1 step back in time from t0) are renamed to
                featureName_m1.
                {'m1': 0, 'm2': -1, 'm3': -2, 'p1': 1, 'p2': 2, 'p3': 3}
            """
        df = x.copy()

        rs.sub_routines.sort_index_columns_inplace(df)
        df = df.unstack(self.id_colname)

        trf_label = 'trf_label'

        shift_dict = {k: v * -1 for k, v in self.shift_dict.items()}
        shifted_dfs = []
        for k, v in shift_dict.items():

            # v == 0 makes shift return the same dataframe and not the desired copy
            if v == 0:
                df_shifted = df.copy()
            else:
                df_shifted = df.shift(v)

            df_shifted[trf_label] = k
            df_shifted.set_index(trf_label, append=True, inplace=True)
            shifted_dfs.append(df_shifted)

        shifted_dfs = pd.concat(shifted_dfs)

        rs.sub_routines.sort_index_columns_inplace(shifted_dfs)
        shifted_dfs = shifted_dfs.stack(self.id_colname)
        df = shifted_dfs.unstack(trf_label)

        # indexing a smaller DataFrame (x) with a larger DataFrame's index (df.index) (both have unique indices),
        # results in the smaller DataFrame being ?broadcasted? to the size of the larger. Where df.index is not in
        # x.index nan rows added created. These should_not_exist! Therefore return only valid subset
        # should_not_exist = (x.loc[df.index, :]).loc[df.drop(x.index).index, :]
        return df.loc[x.index, :]

def doy_circular(DatetimeIndex):
    """
    Transforms rle  day of the year to a circular representation.

    example
    -------
    >>> from matplotlib import pyplot as plt
    >>> import ROIseries as rs
    >>> import pandas as pd
    #
    # 2015: no leap, 2016: leap
    >>> DatetimeIndex = pd.date_range('2015-01-01','2016-12-31')
    >>> doy_circular = rs.feature_transformers.doy_circular(DatetimeIndex)
    >>> doy = DatetimeIndex.dayofyear
    >>> plt.plot(doy,".")
    >>> plt.title('DOY: jump between years 2015 and 2016')
    >>> plt.axes().set_xlabel('doy for 2015 [1:365], 2016 [366:731]')
    >>> plt.axes().set_ylabel('doy')
    >>> plt.figure()
    >>> plt.plot(doy_circular['doy_sin'],doy_circular['doy_cos'],".")
    >>> plt.title('DOY circular: no jump between years 2015 and 2016')
    >>> plt.axes().set_xlabel('doy_sin')
    >>> plt.axes().set_ylabel('doy_cos')

    >>> #verify that all differences are euqal:
    >>> doy_sin_diff = np.diff(doy_circular['doy_sin'])**2
    >>> doy_cos_diff = np.diff(doy_circular['doy_cos'])**2
    >>> distance = np.sqrt(doy_sin_diff + doy_cos_diff)
    >>> np.unique(np.round(distance,5))
    >>> # there the distances in a leap year are a little bit smaller due to more days / year
    """
    doy = np.array(DatetimeIndex.dayofyear,dtype=np.float32)
    leap_bol = np.array([calendar.isleap(y) for y in DatetimeIndex.year])

    # Aim: Transform DOY (1, 365) to a circular coordinate system
    # => 2 pi = 1 circle
    # => Number of days/year: 366 (leap year), 365 (normal year)
    # => Multiply 2 pi by a factor:
    # ==> first doy: 0
    # ==> last doy: (#DoyPerYear-1)/#DoyPerYear to ensure: sine and cosine functions do not return
    #               the same value for first and last day.
    # => Use this set of values between 0 and (just below) 2 pi to calculate sine and cosine.
    #    Distances within this Coordinate System (cp. https://en.wikipedia.org/wiki/Unit_circle) should be a valid
    #    metric for the temporal distances between days seamlessly across years (no 365 to 1 jump as in ordinary DOY)
    doy[leap_bol] = 2 * np.pi * ((doy[leap_bol]-1) / 366)
    doy[~leap_bol] = 2 * np.pi * ((doy[~leap_bol]-1) / 365)

    return dict(zip(["doy_sin", "doy_cos"], [np.sin(doy), np.cos(doy)]))


class DropCorrelated(BaseEstimator, TransformerMixin):
    def __init__(self, x_corr, correlation_threshold, absolute_correlation=False):
        self.x_corr = x_corr
        self.correlation_threshold = correlation_threshold
        self.absolute_correlation = absolute_correlation

    def fit(self, x, y=None):
        return self

    def transform(self, x, y=None):

        if self.absolute_correlation:
            self.x_corr = (self.x_corr).abs()
        n_vars = self.x_corr.shape[1]

        # set the upper right half and diagonal of the correlation matrix to 0
        (self.x_corr).iloc[rs.sub_routines.idx_corners(n_vars, 'up_right')] = 0

        # get indices for sub-setting: rows must stay the same number!
        var_idx = np.broadcast_to(np.arange(n_vars), (n_vars, n_vars)).transpose()

        # get index of correlated variables
        remove_arr = np.array(var_idx[(self.x_corr).get_values() > self.correlation_threshold])
        remove_set = set(remove_arr[~np.isnan(remove_arr)])
        keep = set(range(n_vars)) - remove_set
        print("{} % where dropped with correlation_threshold of {}".format(round((len(remove_set)/n_vars)*100),
                                                                           self.correlation_threshold))

        return x.iloc[:, list(keep)].copy()
