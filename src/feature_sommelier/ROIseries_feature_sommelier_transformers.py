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
from scipy import stats
from sklearn.base import TransformerMixin
from math import pi


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

    feature_time = [(i.rsplit("_", 1)[0], float(i.rsplit("_", 1)[1]))
                    for i in df.columns]

    df.columns = pd.MultiIndex.from_tuples(
            feature_time, names=["feature", "time"])

    if df.index.name is None:
        df.index.name = 'original_id'

    result = df.stack('time').unstack(df.index.name)

    if result.index.is_unique:
        return result
    else:
        raise ValueError("The time is not unique for each feature and id")


def reltime_from_absdate(time_array, sign_digits=0):
    """
    Transform a numeric 1D array with (array-min(array)) / mode(diff(array))

    This transformer has the following assumption
    - mode == min for time difference between adjacent time events

    Parameters
    ----------
    time_array : a 1D numeric array e.g.
        array([ 35.5, 45.5, 55.5, 65.5])
    sign_digits: int
        the number of significant digits in the time array. Try smaller values
        if mode != min error occurs.

    Returns
    -------
    The transformed 1D numeric array e.g.
        array([0, 1, 2, 3])
    """

    time_sortedSet = np.unique(time_array)
    time_sortedSet_sig = np.round(time_sortedSet, decimals=sign_digits)
    time_intervall = np.diff(time_sortedSet_sig)
    time_intervall_mode = stats.mode(time_intervall)[0][0]

    if time_intervall_mode == np.min(time_intervall):
        print("detected time base: {}".format(time_intervall_mode))
    else:
        raise ValueError("Mode and Min of differences of adjacent time events "
                         "must be equal")

    time_array = np.round(time_array, decimals=sign_digits)
    time_array_shifted = (time_array - np.min(time_array))

    if any(time_array_shifted % time_intervall_mode):
        raise ValueError("The difference of adjacent time events must be "
                         "a multile of the time_interval_mode "
                         "(considering sign_digits)")
    else:
        return((time_array_shifted/time_intervall_mode).astype(int))


def TRF_transform(df, shift_dict):
    """
    Transforms the features in a DataFrame from TAF to TRF

    Parameters
    ----------
    df : DataFrame of structure: time (index) * features (columns)
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

    # just make sure that dates are sorted
    df.sort_index(inplace=True, ascending=True)

    # to realize the inuition that a negative shift results in referencing an
    # earlier point in time, swap all signs
    shift_dict = {k: v*-1 for k, v in shift_dict.items()}

    # with the current implementation this is wrong: shift across all features
    # results in shifting features into each other!

    shifted_dfs = []

    for k, v in shift_dict.items():

        # v == 0 makes shift return the same dataframe and not the desired copy
        if v == 0:
            df_shifted = df.copy()
        else:
            df_shifted = df.shift(v)

        df_shifted["trf_label"] = k
        df_shifted.set_index("trf_label", append=True, inplace=True)
        shifted_dfs.append(df_shifted)

    shifted_dfs = pd.concat(shifted_dfs)

    return shifted_dfs.unstack("trf_label")


class TAFtoTRF(TransformerMixin):
    """
    Transform a DataFrame holding TAF to TRF

    Example
    -------
    # get the csvs
    >>> csv = file_search("C:/Users/keck/Desktop/delete_if_unknown/",".csv")
    >>> df_list = [pd.read_csv(i,index_col = 0) for i in csv] #)
    >>> df = pd.concat(df_list,axis=1)

    # make sure that index is string, else: some strange stack MultiIndex error
    >>> df.index = df.index.astype(str)
    >>> shift_dict = dict(zip(["m3","m2","m1","p1","p2","p3"],[-2,-1,0,1,2,3]))

    # do the transforation in a pipeline
    >>> t1=TAFtoTRF(shift_dict)
    >>> p1 = make_pipeline(t1)
    >>> dfx = p1.fit_transform(df)
    """
    def __init__(self, shift_dict):
        self.shift_dict = shift_dict

    def fit(self, shift_dict):
        return(self)

    def transform(self, df):
        # use time in column for row indices and stack columns
        df_timeindex = timeindex_from_colsuffix(df)

        # transform the absolute date into relative dates and add it to index
        reltime = reltime_from_absdate(df_timeindex.index.get_values())
        df_timeindex.set_index(reltime, append=True, inplace=True)

        new_names = list(df_timeindex.index.names[0:-1])
        new_names.append("reltime")
        df_timeindex = df_timeindex.rename_axis(new_names, axis="rows")

        # Do the TRF transformation and bring the 'R_ID' back into the index
        # resulting in (time,R_ID) * (features,TRF_name)
        result = TRF_transform(df_timeindex, self.shift_dict)
        return result.stack('R_ID')


def DOY_to_DOYcircular(doy):
    """
    Transfors day of the year to a circular representation.

    example
    -------
    >>> from matplotlib import pyplot as plt
    >>> DOY = np.arange(365,step=10)
    >>> DOYcircular = DOY_to_DOYcircular(DOY)
    >>> plt.plot(DOY,".")
    >>> plt.plot(DOYcircular['doy_sin'],DOYcircular['doy_cos'],".")
    >>> plt.axes().set_xlabel('doy_sin')
    >>> plt.axes().set_ylabel('doy_cos')

    >>> verify that all differences are euqal:
    >>> doy_sin_diff = np.diff(DOYcircular['doy_sin'])**2
    >>> doy_cos_diff = np.diff(DOYcircular['doy_cos'])**2
    >>> distance = np.sqrt(doy_sin_diff + doy_cos_diff)
    >>> np.unique(np.round(distance,5))
    """
    doy_t = 2 * pi * doy/365

    return dict(zip(["doy_sin", "doy_cos"], [np.sin(doy_t), np.cos(doy_t)]))
