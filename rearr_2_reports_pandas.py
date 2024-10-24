# Create combined tsv report file from two original tsv report files. It will be input for the aggregation script.
import pandas as pd
import sys

df1 = pd.read_csv(sys.argv[1], sep='\t', header=0)
df2 = pd.read_csv(sys.argv[2], sep='\t', header=0)

result = pd.concat([df1, df2])

result.fillna(0, inplace=True, downcast='infer')

result.to_csv('combined_2_orig_reports_pd.tsv', sep='\t', index=False)

