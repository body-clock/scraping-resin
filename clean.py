import pandas as pd

df = pd.read_csv("illinois.csv")
df_clean = df.drop_duplicates(subset=['phone'])
df_clean.to_csv("illinois_clean.csv")
