import numpy as np


def errors_per_stratum_count(y_true, y_pred, strata_level_name, summary_stat=np.mean, normalize_denominator=None):
    strata = y_true.index.get_level_values(strata_level_name)
    errors = (y_true != y_pred)
    strata_uniq, strata_integer = np.unique(strata, return_inverse=True)
    n_errors = np.bincount(strata_integer, weights=errors)

    if normalize_denominator is not None:
        count_per_stratum = np.bincount(strata_integer, weights=np.ones(len(strata_integer)))
        count_factor = count_per_stratum / normalize_denominator
        n_errors = n_errors / count_factor

    return summary_stat(n_errors)
