# Script to automate creation of samplesheet.txt file for use with vsearch script for fusion primers and paired-ends.
# 18.11.2019 LH
# Needs to be run in Python3
# Warning! Underscores in sample names will cause problems.

import csv

# Define a function for reverse-complementing.
def revcomp(seq):
    return seq.translate(str.maketrans('ACGTacgtRYMKrymkVBHDvbhd', 'TGCAtgcaYRKMyrkmBVDHbvdh'))[::-1]


# Read in csv exported from sample sheet from the lab.
with open('sample_sheet.csv') as csvfile:
    fieldnames = ['sample_name', 'fusion_F', 'fusion_R']
    reader = csv.DictReader(csvfile, delimiter=',')
#    writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
    for row in reader:
        r_rc = revcomp(row['fusion_R'])
#        print(row['sample_name'], row['fusion_F'], r_rc, file=open("output.csv","a"))
        print(row['sample_name'], row['fusion_F'], r_rc)


        



'''
##################### INPUT 2 ##########################
import os

# Get core file names of the raw fastq files.
c = os.popen("ls *_R1_001.fastq | cut -f1 -d '_' ")
corenames = c.read()
# Print them into what will be the first column (for joining).
#print(corenames.split('\n')[0])
print(corenames)
#########################################################
'''
