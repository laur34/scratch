# Script to convert fasta file produced from Sanger sequecing into a file resembling our otus_0.98.fasta file and create a dummy otu table.
# Must do this BEFORE BLAST-ing, since the otu fasta file created by this script is the one to BLAST, in order for spcfy_wrapper.sh to work correctly.
# 24.11.2020 LH

# Version 1.1 - includes variables

# Set project variable
FASTA_ORIG='20201020AIMSEQ-A.fas'                                   ############## CHANGE ACCORDINGLY!! #################
PROJECT_NAME="20201020AIMSEQ-A"                                     ############## CHANGE ACCORDINGLY!! #################


#################################### Pre-BLAST-ing steps #########################################

# Convert the fasta file into a new one, called otus_0.98.fasta, in which the seq ids say OTU_XX, like usual.
perl -pe 's/>(.*)_(\d+)/>OTU_\2/' $FASTA_ORIG > otus_0.98.fasta
# Add the size labels to the pseudo otus fasta file
sed -i 's/^>.*/&;size=10/' otus_0.98.fasta

####### BLAST the above created file ##########

#################################### Post BLAST-ing steps #########################################
# Remove Windows carriage returns.
sed -i 's/\r$//g' *.tsv

# Create dummy OTU table
grep '^>' otus_0.98.fasta | sed 's/;.*//' | sed 's/^>//g' > otu_table_0.98.txt
sed -i 's/^OTU_.*/&\t10/' otu_table_0.98.txt
mv otu_table_0.98.txt tmp; cat <(echo "#OTU ID;${PROJECT_NAME}" | perl -pe 's/;/\t/g') tmp >  otu_table_0.98.txt
rm tmp

# As usual, create backup_results folder
# Put in it:  BLAST results you're using, otu_table_0.98.txt, CUSTOM_STRING_TEMPLATE.txt, edit_custom_string_for_consensus_taxonomy.sh, and, ofc the script,
# Desktop/pipeline_utils/spcfy_wrapper.sh

# As usual, make results dir in main project dir; copy everything from backup_results to results, get rid of any unnecessary BLAST results,
# and run the script.
