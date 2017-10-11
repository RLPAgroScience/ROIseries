import io
import ROIseries as rs
import pandas as pd
import pytest
from pandas.util.testing import assert_frame_equal
from sklearn.pipeline import make_pipeline
from sklearn.metrics import confusion_matrix
import numpy as np

# ----------------------------------------------------------------------------------------------------------------------
# Fixtures
# note: as DataFrames are mutable do not use scope="module" to prevent interactions between tests
@pytest.fixture()
def df():
    df1 = pd.DataFrame([[311, 312, 313, 314, 315, 316], [71, 72, 73, 74, 75, 76], [351, 352, 353, 354, 355, 356]],
                       ["ID_1", "ID_7", "ID_5"],
                       ["Feature_1_2457350.0000000000", "Feature_1_2457362.0000000000",
                        "Feature_1_2457374.0000000000", "Feature_1_2457386.0000000000",
                        "Feature_1_2457398.0000000000", "Feature_1_2457410.0000000000"])

    df2 = pd.DataFrame([[317, 318, 319, 320, 321, 322], [77, 78, 79, 80, 81, 82], [357, 358, 359, 360, 361, 362]],
                       ["ID_1", "ID_7", "ID_5"],
                       ["Feature_2_2457350.0000000000", "Feature_2_2457362.0000000000",
                        "Feature_2_2457374.0000000000", "Feature_2_2457386.0000000000",
                        "Feature_2_2457398.0000000000", "Feature_2_2457410.0000000000"])

    df = pd.concat([df1, df2], axis=1)
    df.index.names = ['ID']
    df.columns.names = ['Feature_Time']
    return df


@pytest.fixture()
def time(df):
    df_time = rs.feature_transformers.timeindex_from_colsuffix(df)
    time = df_time.index.get_level_values('time')
    return time


@pytest.fixture()
def df_trf():
    csv = """,ID_1,ID_1,ID_1,ID_1,ID_1,ID_1,ID_7,ID_7,ID_7,ID_7,ID_7,ID_7,ID_5,ID_5,ID_5,ID_5,ID_5,ID_5
,Feature_1,Feature_1,Feature_1,Feature_2,Feature_2,Feature_2,Feature_1,Feature_1,Feature_1,Feature_2,Feature_2,Feature_2,Feature_1,Feature_1,Feature_1,Feature_2,Feature_2,Feature_2
,m1,m2,p1,m1,m2,p1,m1,m2,p1,m1,m2,p1,m1,m2,p1,m1,m2,p1
2015-11-23,311,NA,312,317,NA,318,71,NA,72,77,NA,78,351,NA,352,357,NA,358
2015-12-05,312,311,313,318,317,319,72,71,73,78,77,79,352,351,353,358,357,359
2015-12-17,313,312,314,319,318,320,73,72,74,79,78,80,353,352,354,359,358,360
2015-12-29,314,313,315,320,319,321,74,73,75,80,79,81,354,353,355,360,359,361
2016-01-10,315,314,316,321,320,322,75,74,76,81,80,82,355,354,356,361,360,362
2016-01-22,316,315,NA,322,321,NA,76,75,NA,82,81,NA,356,355,NA,362,361,NA
"""

    df_trf = pd.read_csv(io.StringIO(csv), index_col=[0], header=[0, 1, 2])
    df_trf.index = pd.DatetimeIndex(df_trf.index, name='time', freq='12D')
    df_trf.columns.names = ['ID', 'feature', 'trf_label']

    rs.sub_routines.sort_index_columns_inplace(df_trf)
    df_trf = df_trf.stack('ID')

    return df_trf


@pytest.fixture()
def metrics():
    s_1_true = [True, True, False, False, False, False, False, False, False, True, True, True, True, True]
    s_1_pred = [True, True, False, False, False, False, False, False, True, False, False, False, False, False]
    s_1_tn, s_1_fp, s_1_fn, s_1_tp = confusion_matrix(s_1_true, s_1_pred).ravel()
    s_1_n = len(s_1_true)

    s_2_true = [True, True, True, True, False, False, False, False, False, False, False, False, False, False, False, True, True, True, True, True, True, True]
    s_2_pred = [True, True, True, True, False, False, False, False, False, False, False, False, True, True, True, False, False, False, False, False, False, False]
    s_2_tn, s_2_fp, s_2_fn, s_2_tp = confusion_matrix(s_2_true, s_2_pred).ravel()
    s_2_n = len(s_2_true)

    y_true = pd.Series(np.array(s_1_true + s_2_true),
                        index=pd.Index(np.array(['s_1'] * len(s_1_true) + ['s_2'] * len(s_2_true)), name='strata'))
    y_pred = np.array(s_1_pred + s_2_pred)

    metrics = {'y_true':y_true, 'y_pred':y_pred,
               "s_1_tn":s_1_tn, "s_1_fp":s_1_fp, "s_1_fn":s_1_fn, "s_1_tp":s_1_tp, "s_1_n":s_1_n,
               "s_2_tn":s_2_tn, "s_2_fp":s_2_fp, "s_2_fn":s_2_fn, "s_2_tp":s_2_tp, "s_2_n":s_2_n}

    return metrics

# ----------------------------------------------------------------------------------------------------------------------
# Tests
def test_timeindex_from_colsuffix_SideEffects(df):
    df_copy = df.copy()
    _ = rs.feature_transformers.timeindex_from_colsuffix(df)
    assert_frame_equal(df, df_copy)


def test_timeindex_from_colsuffix_datetime(df):
    result = rs.feature_transformers.timeindex_from_colsuffix(df)
    assert type(result.index) == pd.core.indexes.datetimes.DatetimeIndex


def test_reltime_from_absdate_freq(time):
    reltime, freq = rs.feature_transformers.reltime_from_absdate(time)
    assert freq == '12D'


def test_reltime_from_absdate_reltime(time):
    reltime, freq = rs.feature_transformers.reltime_from_absdate(time)
    assert reltime.equals(pd.Index([0.0, 1.0, 2.0, 3.0, 4.0, 5.0], dtype='float64', name='reltime'))


def test_trf_SideEffects(df, df_trf):
    df_copy = df.copy()
    df_time = rs.feature_transformers.timeindex_from_colsuffix(df)
    shift_dict = dict(zip(["m2", "m1", "p1"], [-1, 0, 1]))
    t1 = rs.feature_transformers.TAFtoTRF(shift_dict)
    p1 = make_pipeline(t1)
    result = p1.fit_transform(df_time)
    assert_frame_equal(df, df_copy)


def test_trf_result(df, df_trf):
    df_time = rs.feature_transformers.timeindex_from_colsuffix(df)
    shift_dict = dict(zip(["m2", "m1", "p1"], [-1, 0, 1]))
    t1 = rs.feature_transformers.TAFtoTRF(shift_dict)
    p1 = make_pipeline(t1)
    result = p1.fit_transform(df_time)
    # integers are converted to float during shifting to allow NaN values, which is expected behaviour
    assert_frame_equal(result, df_trf, check_dtype=False)


def test_trf_exclusion(df, df_trf):
    df_time = rs.feature_transformers.timeindex_from_colsuffix(df)

    rs.sub_routines.sort_index_columns_inplace(df_time)
    df_time = df_time.stack('ID')

    shift_dict = dict(zip(["m2", "m1", "p1"], [-1, 0, 1]))
    t1 = rs.feature_transformers.TAFtoTRF(shift_dict, exclude=(slice('ID_5','ID_5'),slice('Feature_1')))
    p1 = make_pipeline(t1)
    result = p1.fit_transform(df_time)
    # integers are converted to float during shifting to allow NaN values, which is expected behaviour
    assert_frame_equal(result, df_trf, check_dtype=False)


def test_doy_circular():
    """ doy_circular should return evenly distributed euclidean 2D distances across (leap) years """
    doy_circular = rs.feature_transformers.doy_circular(pd.date_range('2015-01-01', '2016-12-31'))
    doy_sin_diff = np.diff(doy_circular['doy_sin']) ** 2
    doy_cos_diff = np.diff(doy_circular['doy_cos']) ** 2
    distance = np.sqrt(doy_sin_diff + doy_cos_diff)

    # leap / no leap years have a slightly different distance between days, which is expected:
    leap_diff = ((1 / 365) - (1 / 366)) * np.pi

    # figure out the significant number of digits: position of the first decimal place where leap_diff is not 0
    sign_digit = (np.where(np.array([int((10 ** i) * leap_diff) for i in range(1, 10)])))[0][0]

    # assert that there is only one unique distances (considering the sign_digits)
    assert len(np.unique(np.round(distance, sign_digit))) == 1


def test_errors_per_stratum_count(metrics):
    m = metrics

    # n_errors, n_samples = ([s_1_fp + s_1_fn, s_2_fp + s_2_fn], [len(s_1_true), len(s_2_true)])
    n_errors = rs.scoring_metrics.errors_per_stratum_count(m["y_true"], m["y_pred"], "strata")
    assert n_errors == np.mean([m["s_1_fp"] + m["s_1_fn"], m["s_2_fp"] + m["s_2_fn"]])


def test_errors_per_stratum_count_normalize(metrics):
    m = metrics

    normalize_denominator = 7  # e.g. days/week
    fraction_s_1 = m['s_1_n'] / normalize_denominator
    fraction_s_2 = m['s_2_n'] / normalize_denominator
    normalized_errors = np.mean([(m["s_1_fp"] + m["s_1_fn"]) / fraction_s_1,
                         (m["s_2_fp"] + m["s_2_fn"]) / fraction_s_2])

    n_errors = rs.scoring_metrics.errors_per_stratum_count(m["y_true"], m["y_pred"], "strata",
                                                           normalize_denominator=normalize_denominator)

    assert n_errors == normalized_errors
