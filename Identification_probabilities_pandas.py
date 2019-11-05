#Filtering combined BLAST and other results table by likelihood that matches are correct to highest level.
#5.11.2019 LH

import pandas
blst = pandas.read_csv('redlist_results_raw_pct_bs.csv', header=0, delimiter="\t", converters={"pct_identity":float})

print blst.columns
print blst.shape
print blst.head()

#high probability matches
high = blst[(blst['pct_identity']>=0.97) & (blst['BIN_sharing']!="yes")]
#write it
high.to_csv(r'high_probabilities.tsv', header=1, index=None, sep='\t')

#medium
medium = blst[(blst['pct_identity']>=0.95) & (blst['pct_identity'] < 0.97)]

medium.to_csv(r'medium_probabilities.tsv', header=1, index=None, sep='\t')

#family
family_level = blst[(blst['pct_identity']>=0.9) & (blst['pct_identity']<0.95)]

family_level.to_csv(r'family_level_probabilities.tsv', header=1, index=None, sep='\t')

#order
order_level = blst[(blst['pct_identity']>=0.85) & (blst['pct_identity']<0.9)]

order_level.to_csv(r'order_level_probabilities.tsv', header=1, index=None, sep='\t')

#rest
supplementary = blst[(blst['pct_identity']<0.85)]
supplementary.to_csv(r'supplementary_probabilities.tsv', header=1, index=None, sep='\t')
