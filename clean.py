import pandas as pd

df = pd.read_csv("output.csv")
df_clean = df.drop_duplicates(subset=['phone'])
df_clean.to_csv("output_clean.csv")
