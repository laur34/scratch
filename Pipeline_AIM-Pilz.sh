#!/usr/bin/bash

#For multiple fastq paired-end barcode reads that need to be unzipped, merged, combined into a single fastq, converted to fasta, clustered
#November 2016, Laura Hardulak

#First get all your fastq files into your working directory.

#Unzip gzipped fastq files:
gunzip *.fastq.gz

#Merge:
for i in $(ls *_R1_001.fastq | cut -f 1-3 -d "_"); do bash /home/laur/bbmap/bbmerge.sh in1=${i}_R1_001.fastq in2=${i}_R2_001.fastq out=${i}_merged.fastq outu1=${i}_unmerged1.fastq outu2=${i}_unmerged2.fastq; done

#Convert fastq to fasta:
for i in $(ls *_merged.fastq | cut -f1 -d"."); do
	seqtk seq -A ${i}.fastq > ${i}.fasta
done

#add sample names to fasta headers
for i in $(ls *_merged.fasta | cut -f 1-3 -d "_"); do sed -i "s/^>/>${i}|/" ${i}_merged.fasta; done

#Then we can put all fasta files into one big fasta file and cluster it.
cat ./*_merged.fasta >> ./NuCombo/all.fasta

#Cluster
cdhit-est -i all.fasta -o all_cl98 -c 0.98 -n 10 -M 2000 -d 0

#Now create a file containing just the cluster id's and their respective representative sequence id's:
egrep '>Cl|\*' all_cl98.clstr > all_ClAndRepSeq

#Make this file to have one line per entry:
awk '/>Cluster [0-9]+$/ {printf("%s\t", $0); next} 1' all_ClAndRepSeq > all_ClAndRepSeq1line

#Next we will prepare a tab separated file showing how many sequences are in each cluster.
#How to get the counts of sequences in each cluster: an awk program called NumbersInClusters
~/Dropbox/NewComputer/Pipeline/NumbersInClusters all_cl98.clstr > all_NumsInClusters

#Pate the two files we made together into a file with cluster id's, starred sequences, and counts of seqs in clusters:
paste all_ClAndRepSeq1line all_NumsInClusters > all_RepSeqsWithInfo


#To make input for the pivot table, we convert the .clstr file created by CD-HIT to be all in columns, by an awk script called reformatClstrFile
~/Dropbox/NewComputer/Pipeline/reformatClstrFile all_cl98.clstr > all_clstrInColumns

#Formatting steps:
sed 's/|/\t/' all_clstrInColumns > all_clstrInColumns2

sed -e 's/,\s/,\t/' all_clstrInColumns2 > all_clstrInColumns3

#Get rid of column we don't need:
cut -f 1,4,5 all_clstrInColumns3 > all_clstrInColumns4

#Get counts of sequences in clusters by sample:
cut -f 1-2 all_clstrInColumns4 | sort | uniq -c > $$; mv $$ all_clstrInColumns4

#Put a tab insted of space between first and 2nd columns and get rid of the > :
sed 's/[[:space:]]>Cl/\tCl/' all_clstrInColumns4 > all_clstrInColumns5
sed -i 's/>//' all_clstrInColumns5

#Sort in desecending numerical order by number of sequences, then you can take only the ones with 10 or more.
sort -rn all_clstrInColumns5 >> $$; mv $$ all_clstrInColumns5

#This sheet and RepSeqsWithInfo can be imported into EXCEL or LO and matched by cluster number to obtain the representative sequence ID, and then BINs.

