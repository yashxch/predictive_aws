import pandas as pd
import os

def preprocess():
    # Get the path to the data file relative to this script
    script_dir = os.path.dirname(os.path.abspath(__file__))
    parent_dir = os.path.dirname(script_dir)
    data_path = os.path.join(parent_dir, "data", "data.csv")

    df = pd.read_csv(data_path)
    df = df.dropna()
    df['cpu_memory_ratio'] = df['cpu'] / df['memory']
    return df