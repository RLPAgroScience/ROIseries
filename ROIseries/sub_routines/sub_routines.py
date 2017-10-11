import os
import pandas as pd

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
