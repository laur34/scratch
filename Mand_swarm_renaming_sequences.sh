#test of SWARM using Mandery NGS data
#Now we must rename the representative sequences as OTU_, as well as the otu table, accordingly.
FASTA=all.nonchimeras.derep_1f_representatives.fas
PROJECT=Mandery_test
TBL="otu_table_0.98.txt"
NUM_SEQS=$(grep -c '^EC' $TBL)
paste <(grep "^EC" otu_table_0.98.txt | cut -f1) <(seq 1 1 $NUM_SEQS| perl -pe 's/(\d+)\n/OTU_\1,/g'| perl -pe 's/\,$/\n/g' | perl -pe 's/,/\n/g') > rel_tbl.tsv #This could be a start for a relational naming table
#For each sequence name in the fasta, look it up in the rel table, and create a new fasta with the corresponding OTU_ names and sequences.

cat "${FASTA}" | while read SEQNAME OTU; do
	echo -n "${OTU}"
	grep -A 1 ${SEQNAME}\; "${FASTA}"
done > tmp.fa


perl -pe 's/^OTU_(\d+)>.*;size/>OTU_\1;size/' tmp.fa > otus_swarmed.fasta

#Now the SWARM representative sequences are in an "otus_swarmed.fasta" file according to the format we customarily use (but with semicolons on end).

#Next, substitute the sequence names in the otu_table from the swarm pipeline with their correct OTU_ names so the otu table and otu fasta will übereinstimmen.
#Then you can run the wrapper script.
cat rel_tbl.tsv | while read SEQNAME OTU; do
	echo -n "${OTU}"
	grep -w ${SEQNAME} otu_table_0.98.txt
done > tmp.tsv

perl -i -pe 's/^(OTU_(\d+))\S*/$1/' tmp.tsv
#add header
cat <(head -n1 otu_table_0.98.txt) tmp.tsv > otu_table.tmp

mv otu_table_0.98.txt otu_table_0.98.orig
mv otu_table.tmp otu_table_0.98.txt
mv otus.swarmed.fasta > otus_0.98.fasta


