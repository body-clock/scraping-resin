import pandas as pd

df = pd.read_csv("ohio.csv")
df_clean = df.drop_duplicates(subset=['phone'])
df_clean.to_csv("ohio_clean.csv")
