import os
import pandas as pd
import numpy as np

def file_search(top_dir, extension):

    result = []
    for dir_path,dir_names,files in os.walk(top_dir):
        for name in files:
            if name.lower().endswith(extension):
                result.append(os.path.join(dir_path, name))
    return result


def sort_index_columns_inplace(df):
    for i in [0, 1]:
        df.sort_index(axis=i, inplace=True)


def idx_corners(n_vars, direction):
    idx_range = np.arange(n_vars)
    x = np.repeat(idx_range, (idx_range + 1)[::-1])
    y = np.concatenate([idx_range[i:] for i in range(n_vars)])

    if direction == 'up_right':
        x = x
        y = y
    elif direction == 'down_right':
        x = (n_vars - 1) - x
        y = y
    elif direction == 'down_left':
        x = (n_vars - 1) - x
        y = (n_vars - 1) - y
    elif direction == 'up_left':
        x = x
        y = (n_vars - 1) - y
    else:
        raise ValueError("direction not in "
                         "['up_right','down_left','up_left','up_right']")

    return [x, y]
