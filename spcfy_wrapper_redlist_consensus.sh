#!/bin/bash
# a script to merge BLAST results - current script works only for COI data (animal metabarcoding)
# author: VB@AIM, 30.07.2019

# path to current version of the BOLD combined table (large, around 7 GB) - this table contains all of the information for individual animal COI entries (a.k.a. Process IDs) in the BOLD database - these were obtained by passing taxonomic group names as arguments to the BOLD API - this is the only way to obtain data from BOLD in bulk; the sequence information from this table is also used to create BOLD BLAST databases
BOLD_COMBINED_TSV=$(echo "/home/laur/Desktop/pipeline_utils/Animalia_03_02_2021_bold_combined.tsv")

# script needs an argument for job (project) name
confirm(){
        read -r -p "${1:-Continue? [y/N]} " response
        case "$response" in
                [yY][eE][sS]|[yY])
        	        true
                	;;
        	*)
                	false
			exit 1
                	;;
        esac
}

DATE=$(date | cut -d ' ' -f 2,3,6 | perl -pe 's/ /_/g' | perl -pe 's/\.//g')
DEFAULT=$(echo "Project_${DATE}")

if [[ $# -eq 0 ]]; then
	echo "$0: you provided no arguments to the script"
	echo "assign $DEFAULT as project name?"
	ARG1=$DEFAULT
	confirm
elif [[ $# -eq 1 ]]; then
	ARG1=$1
	echo "assign $1 as project name?"
	confirm
fi

PROJECT=$ARG1

# names of BLAST result files exported from the software Geneious by default contain spaces, which need to be replaced by underscores
GENEIOUS_BOLD_ANIMALIA_RESULTS=$(ls *Animalia* | perl -pe 's/ /_/g')
GENEIOUS_NCBI_RESULTS=$(ls *nt\ * | perl -pe 's/ /_/g')
find . -maxdepth 1 -name '*Animalia*' -exec mv {} $GENEIOUS_BOLD_ANIMALIA_RESULTS \;
find . -maxdepth 1 -name '*nt\ *' -exec mv {} $GENEIOUS_NCBI_RESULTS \;
sleep 1

# remove subfamilies from Animalia BLAST results - including the subfamilies had caused some bugs in the previous version of the script, which have not been resolved yet
cut -d, -f6 --complement $GENEIOUS_BOLD_ANIMALIA_RESULTS > temp
rm $GENEIOUS_BOLD_ANIMALIA_RESULTS
mv temp $GENEIOUS_BOLD_ANIMALIA_RESULTS 

# edit NCBI BLAST results - remove ".1" from the end of Genbank Accession IDs and remove "_" from the start of the "Description" column - these are peculiarities of the FASTA file used as an input to create the NCBI blasting database
#perl -pi -e 's/%\t" /%\t"/g' $GENEIOUS_NCBI_RESULTS
#perl -pi -e 's/^(.*)\.1\t/\1\t/g' $GENEIOUS_NCBI_RESULTS

# create intermediate tables containing the "Query" field (i.e. OTU IDs) and the "Grade-%-ID" from Geneious; remove "Grade" from the exported BLAST results for compatibility with the former version of the script
cut -f4,5 $GENEIOUS_BOLD_ANIMALIA_RESULTS > BLAST_BOLD_Grades.tsv
cut -f4 --complement $GENEIOUS_BOLD_ANIMALIA_RESULTS > temp
rm $GENEIOUS_BOLD_ANIMALIA_RESULTS
mv temp $GENEIOUS_BOLD_ANIMALIA_RESULTS

cut -f4,5 $GENEIOUS_NCBI_RESULTS > BLAST_NCBI_Grades.tsv
cut -f4 --complement $GENEIOUS_NCBI_RESULTS > temp
rm $GENEIOUS_NCBI_RESULTS
mv temp $GENEIOUS_NCBI_RESULTS

perl -pi -e 's/Grade/Grade_BOLD/g' BLAST_BOLD_Grades.tsv
perl -pi -e 's/Grade/Grade_NCBI/g' BLAST_NCBI_Grades.tsv

# reformat the BLAST results table exported from Geneious (NCBI Genbank BLAST)
paste -d '\t' <(cut -f 3 $GENEIOUS_NCBI_RESULTS | tail -n +2 | perl -pe 's/"//g' | perl -pe 's/\|/ /g' | perl -pe 's/(\w+) (\w+).*/\1 \2/g' | perl -pe 's/ sp/ sp./g') <(paste -d '\t' <(tail -n +2 $GENEIOUS_NCBI_RESULTS | cut -f 1,3) <(tail -n +2 $GENEIOUS_NCBI_RESULTS | cut -f 2,4,5) | perl -pe 's/"//g' | perl -pe 's/\|/ /g' | perl -pe 's/;size/\tsize/g') | awk -v FS="\t" '{print $2"\t"$1"\t"$4"\t"$3"\t"$7"\t"$6"\t"$5}' > ${PROJECT}_NCBI_nt_blast_result.reformatted.tsv
sleep 1

# reformat the BLAST results table exported from Geneious (BOLD Animalia BLAST)
paste -d ',' <(tail -n +2 $GENEIOUS_BOLD_ANIMALIA_RESULTS | cut -f 1) <(tail -n +2 $GENEIOUS_BOLD_ANIMALIA_RESULTS | cut -f 3 | perl -pe 's/" //g' | perl -pe 's/"//g' | perl -pe 's/ /_/g' | cut -d ',' -f 2-7) <(tail -n +2 $GENEIOUS_BOLD_ANIMALIA_RESULTS | cut -f 3 | perl -pe 's/" //g' | perl -pe 's/"//g' | perl -pe 's/ /_/g' | cut -d ',' -f 1) <(tail -n +2 $GENEIOUS_BOLD_ANIMALIA_RESULTS | cut -f 2) <(tail -n +2 $GENEIOUS_BOLD_ANIMALIA_RESULTS | cut -f 4 | perl -pe 's/;size/,size/g') <(tail -n +2 $GENEIOUS_BOLD_ANIMALIA_RESULTS | cut -f 5) | awk --field-separator="," '{print $10,$11,$1,$8,$9,$12,$2,$3,$4,$5,$6,$7}' | perl -pe 's{\d+\.\d+%}{$&/100}eg' > Animalia_BOLD_Geneious_results.reformatted

# remove occurrences of "MOTU" - they introduce bugs downstream when grepping
perl -pi -e 's/_MOTU_\d+//g' Animalia_BOLD_Geneious_results.reformatted
perl -pi -e 's/MOTU_\d+//g' Animalia_BOLD_Geneious_results.reformatted
perl -pi -e 's/_MOTU\d+//g' Animalia_BOLD_Geneious_results.reformatted
perl -pi -e 's/MOTU\d+//g' Animalia_BOLD_Geneious_results.reformatted

# join the raw OTU table (coming from the vsearch (preprocessing) pipeline) with the reformatted BOLD BLAST results table
# TODO: implement a check of whether the OTU table exists in the "results" (i.e. working) folder and whether it is named appropriately
otutab_cols=$(awk -F'\t' '{print NF; exit}' otu_table_0.98.txt);
join_out=$(seq 2 1 $otutab_cols | perl -pe 's/(\d+)\n/1.\1,/g' | perl -pe 's/\,$/\n/g');
join -t $'\t' -1 1 -2 1 <(tail -n +2 otu_table_0.98.txt | sort -t $'\t' -k1,1) <(perl -pe 's/ /\t/g' Animalia_BOLD_Geneious_results.reformatted | sort -t $'\t' -k1,1) -o 1.1,2.2,2.3,2.4,2.5,2.6,2.7,2.8,2.9,2.10,2.11,2.12,$join_out | perl -pe 's/\t/ /g' > BOLD_merge_OTU_table.temp

# reformat the joined table
cat <(paste -d ' ' <(echo "processid bin_uri %_identity phylum_name class_name order_name family_name genus_name species_name OTU;cluster_size") <(head -1 otu_table_0.98.txt | cut -f 2-)) <(paste -d ' ' <(cut -d ' ' -f 3-5 BOLD_merge_OTU_table.temp) <(cut -d ' ' -f 7-12 BOLD_merge_OTU_table.temp) <(cut -d ' ' -f 1-2 BOLD_merge_OTU_table.temp | perl -pe 's/ /;/g') <(cut -d ' ' -f 13- BOLD_merge_OTU_table.temp)) > input_for_BINsharing_script.temp

# use the BOLD API to interactively query BOLD for information on BINs in the current dataset
# this is an old part of the pipeline - since 2019, instead of using the API, we grep the previously downloaded BOLD combined table
# this was implemented because of the changes to the way we do BLAST (using Geneious, where we used BOLD API for blasting before), as well as because of changes done between BOLD v.3 and v.4 which made the API very unstable, breaking the connection frequently
# the zombie part of the script is still necessary to create some input files for grepping the BOLD combined table - this should be reimplemented
perl -pe 's/ /\t/g' input_for_BINsharing_script.temp > ${PROJECT}_BOLD_merge_OTU_table.tsv
echo
echo "Constructing the API calls to query BOLD for BINs' information ..."
echo
sleep 1
NUM_MERGED_BINS=$(tail -n +2 ${PROJECT}_BOLD_merge_OTU_table.tsv | wc -l)
if [ $NUM_MERGED_BINS -le 500 ]
then
	NUM_MERGED_BINS=500
fi
SPLIT_CMD=$(seq 500 500 $NUM_MERGED_BINS)
BIGGEST=$(echo $SPLIT_CMD | perl -pe 's/ /\n/g' | tail -1)
let REMAINDER=$NUM_MERGED_BINS-$BIGGEST
for s in $SPLIT_CMD; do
	tail -n +2 ${PROJECT}_BOLD_merge_OTU_table.tsv | head -n $s | tail -500 | cut -f 2 | perl -pe 's/\n/|/g' > mergedBINs_to${s}.txt
done
if [ $NUM_MERGED_BINS -gt 500 ]
then
	tail -n +2 ${PROJECT}_BOLD_merge_OTU_table.tsv | tail -n $REMAINDER | cut -f 2 | perl -pe 's/\n/|/g' > mergedBINs_to${NUM_MERGED_BINS}.txt
fi
for s in $SPLIT_CMD; do
	paste <(echo "http://boldsystems.org/index.php/API_Public/combined?bin=") <(cat mergedBINs_to${s}.txt) <(echo "&format=tsv") | perl -pe 's/\t//g' | perl -pe 's/\|\&format/\&format/g' > mergedBINs_to${s}_cmd.txt
done
echo "Checking if there are more than 500 records in the provided sample ..."
echo
sleep 1
if [ $NUM_MERGED_BINS -gt 500 ]
then
	NUMBER_ACTUAL=$(tail -n +2 ${PROJECT}_BOLD_merge_OTU_table.tsv | wc -l)
	echo "Number of records is greater than 500 ($NUMBER_ACTUAL). Splitting API commands ..."
else
	NUMBER_ACTUAL=$(tail -n +2 ${PROJECT}_BOLD_merge_OTU_table.tsv | wc -l)
	echo "Number of records is smaller than 500 ($NUMBER_ACTUAL). Proceeding with a single API command ..."
fi
if [ $NUM_MERGED_BINS -gt 500 ]
then
	paste <(echo "http://boldsystems.org/index.php/API_Public/combined?bin=") <(cat mergedBINs_to${NUM_MERGED_BINS}.txt) <(echo "&format=tsv") | perl -pe 's/\t//g' | perl -pe 's/\|\&format/\&format/g' > mergedBINs_to${NUM_MERGED_BINS}_cmd.txt
fi
sleep 2
echo
#echo "Passing API calls to curl ..."
#
#for cmd in *cmd.txt; do
#	fnamecore=$(cut -d_ -f2 <<< "$cmd")
#	curl --url $(cat $cmd) > mergedBINs_${fnamecore}_bold_result.txt
#done
echo "HACK - avoid BOLD API. Instead, parse the big bold combined table for BINs ..."
echo

# temp line for testing
#mv mergedBINs_to13171_cmd.txt cmd.tmp; rm mergedBINs_*_cmd.txt; mv cmd.tmp mergedBINs_to13171_cmd.txt

#date
#for cmd in *cmd.txt; do
#	echo "Processing BINs from file $cmd"
#	echo
#	fnamecore=$(cut -d_ -f2 <<< "$cmd")
#	BINS_LIST=$(cut -d '=' -f 2 $cmd | cut -d '&' -f 1 | perl -pe 's/\|/\n/g' | grep -v "NA" | sort | uniq)
#	for bin in $BINS_LIST; do
#		echo "grepping BIN $bin"
#		echo -en "\e[1A"		
#		grep "$bin" $BOLD_COMBINED_TSV >> mergedBINs_${fnamecore}_bold_result.txt
#	done
#done
#date

# parallelize in a very primitive way
echo "Copying BOLD combined table ..."
cp $BOLD_COMBINED_TSV ../
echo
sleep 1
echo "Parallelizing ..."
echo
sleep 1
echo "Creating scripts ..."
echo
cat *cmd.txt | cut -d '=' -f 2 $cmd | cut -d '&' -f 1 | perl -pe 's/\|/\n/g' | grep -v "NA" | sort | uniq > dev_BINs_all_uniq.txt

NUM_BINS=$(cat *cmd.txt | cut -d '=' -f 2 $cmd | cut -d '&' -f 1 | perl -pe 's/\|/\n/g' | grep -v "NA" | sort | uniq | wc -l)
if [ $NUM_BINS -gt 99 ]; then
	SPLIT_CMD_BINS=$(seq 100 100 $NUM_BINS)
else
	SPLIT_CMD_BINS=$NUM_BINS
fi
BIGGEST_BINS=$(echo $SPLIT_CMD_BINS | perl -pe 's/ /\n/g' | tail -1)
let REMAINDER_BINS=$NUM_BINS-$BIGGEST_BINS
for s in $SPLIT_CMD_BINS; do
	head -n $s dev_BINs_all_uniq.txt | tail -100 > split_cmd_bins_to${s}.txt
	echo '#!/bin/bash' >> get_bininfo_to${s}.sh
	nbins=$s
	echo 'BINS_LIST=$(cat split_cmd_bins_to_.txt)' >> get_bininfo_to${s}.sh
	perl -pi -e "s/_to_/_to${nbins}/g" get_bininfo_to${s}.sh
	echo 'for bin in $BINS_LIST; do' >> get_bininfo_to${s}.sh
	echo 'grep "$bin" ../Animalia_03_02_2021_bold_combined.tsv >> mergedBINs_to_bold_result.txt' >> get_bininfo_to${s}.sh
	perl -pi -e "s/_to_bold_/_to${nbins}_bold_/g" get_bininfo_to${s}.sh
	echo 'done' >> get_bininfo_to${s}.sh
done
if [ $NUM_BINS -gt 100 ]
then
	tail -n $REMAINDER_BINS dev_BINs_all_uniq.txt > split_cmd_bins_to${NUM_BINS}.txt
	echo '#!/bin/bash' >> get_bininfo_to${NUM_BINS}.sh
	nbins=$NUM_BINS
	echo 'BINS_LIST=$(cat split_cmd_bins_to_.txt)' >> get_bininfo_to${NUM_BINS}.sh
	perl -pi -e "s/_to_/_to${nbins}/g" get_bininfo_to${NUM_BINS}.sh
	echo 'for bin in $BINS_LIST; do' >> get_bininfo_to${NUM_BINS}.sh
	echo 'grep "$bin" ../Animalia_03_02_2021_bold_combined.tsv >> mergedBINs_to_bold_result.txt' >> get_bininfo_to${NUM_BINS}.sh
	perl -pi -e "s/_to_bold_/_to${nbins}_bold_/g" get_bininfo_to${NUM_BINS}.sh
	echo 'done' >> get_bininfo_to${NUM_BINS}.sh
fi
date
for script in get_bininfo_to*.sh; do
	echo "running $script ..."
	bash $script &
done
wait
date

#maintenance
if [ -e mergedBINs_countries_uniq.txt ]
then
	rm mergedBINs_countries_uniq.txt
fi
if [ -e mergedBINs_countries_uniq.txt ]
then
	rm mergedBINs_species_uniq.txt
fi
#the columns of the results are:
#head -1 mergedBINs_to500_bold_result.txt | perl -pe 's/\t/\n/g' | awk '{printf("%d %s\n"), NR, $0}'
echo
echo "Parsing the results ..."
sleep 2
for res in *to*_bold_result.txt; do
	tail -n +2 $res | cut -f 8,55 | sort | uniq | perl -pe 's/ /_/g' >> mergedBINs_countries_uniq.txt
done
for res in *to*_bold_result.txt; do
	tail -n +2 $res | cut -f 8,22 | sort | uniq | perl -pe 's/ /_/g' >> mergedBINs_species_uniq.txt
done
awk '{if($2!=""){print $0}}' mergedBINs_countries_uniq.txt | sort | uniq | awk '{if(a[$1])a[$1]=a[$1]"|"$2; else a[$1]=$2;}END{for (i in a)print i, a[i];}' > mergedBINs_countries_grouped.txt
awk '{if($2!=""){print $0}}' mergedBINs_species_uniq.txt | sort | uniq | awk '{if(a[$1])a[$1]=a[$1]"|"$2; else a[$1]=$2;}END{for (i in a)print i, a[i];}' > mergedBINs_species_grouped.txt
awk '{a=gsub(/\|/,""); if($2!="") b=a+1; else b=a; print $1,b}' mergedBINs_species_grouped.txt | perl -pe 's/(.*) 0$/\1 unknown/g' | perl -pe 's/(.*) 1$/\1 no/g' | perl -pe 's/(.*) \d+$/\1 yes/g' > mergedBINs_species_binsharing.txt
#explanation of previous awk one-liner: gsub counts the occurrence of | chars, which is put between species names, and thus corresponds to number of species minus one (e.g., one "|" for two species); $2! checks if there is exactly one species for the current BIN (i.e. if there is anything in column $2 at all), and if there is, it increases the count by 1 -> otherwise, empty columns and columns with one species would give the same result, because neither has any "|" chars
echo
echo "Retrieving % identity from second input file ..."
cut -f 1-3 ${PROJECT}_BOLD_merge_OTU_table.tsv > ${PROJECT}_ID_BIN_%identity.tsv
sleep 2
#convert %s to floats
cat ${PROJECT}_ID_BIN_%identity.tsv | perl -pe 's{\d+\.\d+%}{$&/100}eg' | perl -pe 's/\t/,/g' > %intofloat.temp
#get %range for each unique BIN:
#first, group all %s by BIN
awk -F ',' '{if(a[$2])a[$2]=a[$2]","$3; else a[$2]=$3;}END{for (i in a)print i, a[i];}' %intofloat.temp | perl -pe 's/ /,/g' > floatsgrouped.temp
#second, get the minimum and maximum %s
#to print all but the last line of file: sed \$d
#cat floatsgrouped.temp | perl -pe 's/,/\t/g' | awk '{min=$2;for(i=1;i<=NF;i++)if($i<min)min=$i;print $1, min}'
#cat floatsgrouped.temp | perl -pe 's/,/\t/g' | awk '{max=$2;for(i=2;i<=NF;i++)if($i>max)max=$i;print $1, max}'
awk -F ',' '{min=$2;max=$2;a=0;for (i=2;i<=NF;i++) {a+=$i;if ($i < min){min=$i};if ($i > max){max=$i}};print $1, min*100"%", "to", max*100"%"}' floatsgrouped.temp | perl -pe 's/ to /_to_/g' | perl -pe 's/ /\t/g' > %range.temp
#generate URLs
#maintenance
if [ -e URLs.temp ]
then
	rm URLs.temp
fi
for bin in $(cut -d ' ' -f 1 mergedBINs_species_binsharing.txt); do
	paste -d '' <(echo "http://www.boldsystems.org/index.php/Public_BarcodeCluster?clusteruri=") <(echo $bin) >> URLs.temp
done
paste -d '\t' <(cut -d ' ' -f 1 mergedBINs_species_binsharing.txt) <(cat URLs.temp) > mergedBINs_URLs.temp

#put everything together
echo
echo "Adding % identity information to the grouped species, countries, and binsharing information ..."
sleep 2
join -1 1 -2 1 -o 1.1,1.2,2.2 mergedBINs_species_binsharing.txt mergedBINs_species_grouped.txt | perl -pe 's/ /,/g' | perl -pe 's/^(.*),(.*),(.*)/\1\t\2,\3/g' > joined_speciesgroups_binsharing.csv.temp
join -1 1 -2 1 -o 1.1,1.2,1.3,2.2 <(sort -k1,1 joined_speciesgroups_binsharing.csv.temp) <(cat mergedBINs_countries_grouped.txt | perl -pe 's/ /\t/g' | sort -k1,1) | perl -pe 's/^(.*) (.*)  (.*)$/\1\t\2,\3/g' > joined_countriesgroups_speciesgroups_binsharing.temp
join -1 1 -2 1 -o 1.1,1.2,2.2 <(sort -k1,1 joined_countriesgroups_speciesgroups_binsharing.temp) <(sort -k1,1 %range.temp) > joined_%range.temp
join -1 1 -2 1 -o 1.1,1.2,1.3,2.2 <(sort -k1,1 joined_%range.temp) <(sort -k1,1 mergedBINs_URLs.temp) | perl -pe 's/ /,/g' > joined_URL.temp
echo "BIN sharing?,BIN species,BIN countries,HIT%ID range,BOLD link" > header_joined_URL.temp
head -1 ${PROJECT}_BOLD_merge_OTU_table.tsv | perl -pe 's/\t/,/g' > header_${PROJECT}_BOLD_merge_OTU_table.tsv
tail -n +2 ${PROJECT}_BOLD_merge_OTU_table.tsv | perl -pe 's/\t/,/g' | perl -pe 's/ /_/g' | awk -F ',' '{print $2,"\t",$0}' > ${PROJECT}_format_for_joining.temp
NUM_COLS_OTUTAB=$(awk -F'\t' '{print NF; exit}' otu_table_0.98.txt)
let DELIM_ONE=$NUM_COLS_OTUTAB+10 # +11 fields (ID, BIN, phyl. etc.) - 1 field (OTU)
let DELIM_TWO=$NUM_COLS_OTUTAB+12 # skip one field (empty field)
let DELIM_THREE=$NUM_COLS_OTUTAB+16 # get rid of last two fields (empty fields)
join -1 1 -2 1 -o 1.1,1.2,2.2,2.3,2.4 <(sort -k1,1 ${PROJECT}_format_for_joining.temp) <(perl -pe 's/^(.*?)(?=,)/\1\t/g' joined_URL.temp | sort -k1,1) | perl -pe 's/ /,/g' | perl -pe 's/_/ /g' | perl -pe 's/Public Barcode/Public_Barcode/g' | perl -pe 's/OTU /OTU_/g' | cut -d, -f2-$DELIM_ONE,$DELIM_TWO-$DELIM_THREE > ${PROJECT}_noheader.csv
sleep 1
head -1 ${PROJECT}_BOLD_merge_OTU_table.tsv > header_${PROJECT}_BIN_merged.txt
cat <(paste -d ',' <(cat header_${PROJECT}_BIN_merged.txt) <(cat header_joined_URL.temp)) <(cat ${PROJECT}_noheader.csv) > ${PROJECT}_final.csv
# TODO: implement the maintenance of unnecessary intermediate files

# ========================================================================================================
# in this section a bug is corrected which is introduced somewhere upstream, but has not been identified
# the bug fails to join the extra information retrieved by grepping the BOLD combined table for some BINs
# this is part 1 of the bugfix
# ========================================================================================================
PROJECT=$(ls *final.csv | perl -pe 's/^(.*)_final\.csv/\1/g')
echo "retrieving missing BIN information..."

comm -13 <(tail -n +2 ${PROJECT}_final.csv | cut -d, -f10 | sort | uniq) <(tail -n +2 input_for_BINsharing_script.temp | cut -d ' ' -f10 | sort | uniq) > diff_OTUs_input_BINsharing.temp
GETRECS=$(cat diff_OTUs_input_BINsharing.temp)
for rec in $GETRECS ; do grep $rec input_for_BINsharing_script.temp >> recs_from_missing_OTUs.temp ; done
cut -d ' ' -f 1 recs_from_missing_OTUs.temp | sort | uniq > procIDs_from_missing_OTUs.txt
NUM_PROCIDS=$(cat procIDs_from_missing_OTUs.txt | wc -l)
if [ $NUM_PROCIDS -gt 99 ]; then
	for i in $(seq 100 100 $NUM_PROCIDS); do head -n $i procIDs_from_missing_OTUs.txt | tail -n 100 | perl -pe 's/\n/|/g' | perl -pe 's/\|$/\n/g' > to_${i}.proc.ids; done
	LAST_PROCID=$(seq 100 100 $NUM_PROCIDS | tail -1)
else
	perl -pe 's/\n/|/g' procIDs_from_missing_OTUs.txt | perl -pe 's/\|$/\n/g' > to_${NUM_PROCIDS}.proc.ids
	LAST_PROCID=$NUM_PROCIDS
fi
let FINAL_PROCID=$NUM_PROCIDS-$LAST_PROCID
if [ $NUM_PROCIDS -gt 99 ]; then
	tail -n $FINAL_PROCID procIDs_from_missing_OTUs.txt | perl -pe 's/\n/|/g' | perl -pe 's/\|$/\n/g' > to_${NUM_PROCIDS}.proc.ids
fi
for input in $(ls *.proc.ids); do paste -d '' <(echo "http://v4.boldsystems.org/index.php/API_Public/specimen?&ids=") <(cat $input) <(echo "&format=tsv") > ${input}.cmd; done

# grep the BOLD combined table the second time, this time for Process-ID information
cat *.proc.ids.cmd | cut -d '=' -f 2 | cut -d '&' -f 1 | perl -pe 's/\|/\n/g' | grep -v "NA" | sort | uniq > dev_PIDs_all_uniq.txt
echo "Parallelizing process ID retrieval ..."
echo
sleep 1
echo "Creating scripts ..."
echo
date
NUM_PIDS=$(cat *cmd.txt | cut -d '=' -f 2 $cmd | cut -d '&' -f 1 | perl -pe 's/\|/\n/g' | grep -v "NA" | sort | uniq | wc -l)
if [ $NUM_PIDS -gt 99 ]; then
	SPLIT_CMD_PIDS=$(seq 100 100 $NUM_PIDS)
else
	SPLIT_CMD_PIDS=$NUM_PIDS
fi
BIGGEST_PIDS=$(echo $SPLIT_CMD_PIDS | perl -pe 's/ /\n/g' | tail -1)
let REMAINDER_PIDS=$NUM_PIDS-$BIGGEST_PIDS
for s in $SPLIT_CMD_PIDS; do
	head -n $s dev_PIDs_all_uniq.txt | tail -100 > split_cmd_pids_to${s}.txt
	echo '#!/bin/bash' >> get_pidinfo_to${s}.sh
	npids=$s
	echo 'PIDS_LIST=$(cat split_cmd_pids_to_.txt)' >> get_pidinfo_to${s}.sh
	perl -pi -e "s/_to_/_to${npids}/g" get_pidinfo_to${s}.sh
	echo 'for pid in $PIDS_LIST; do' >> get_pidinfo_to${s}.sh
	echo 'grep "$pid" ../Animalia_03_02_2021_bold_combined.tsv >> mergedPIDs_to_bold_result.txt' >> get_pidinfo_to${s}.sh
	perl -pi -e "s/_to_bold_/_to${npids}_bold_/g" get_pidinfo_to${s}.sh
	echo 'done' >> get_pidinfo_to${s}.sh
done
if [ $NUM_PIDS -gt 100 ]
then
	tail -n $REMAINDER_PIDS dev_PIDs_all_uniq.txt > split_cmd_pids_to${NUM_PIDS}.txt
	echo '#!/bin/bash' >> get_pidinfo_to${NUM_PIDS}.sh
	npids=$NUM_PIDS
	echo 'PIDS_LIST=$(cat split_cmd_pids_to_.txt)' >> get_pidinfo_to${NUM_PIDS}.sh
	perl -pi -e "s/_to_/_to${npids}/g" get_pidinfo_to${NUM_PIDS}.sh
	echo 'for pid in $PIDS_LIST; do' >> get_pidinfo_to${NUM_PIDS}.sh
	echo 'grep "$pid" ../Animalia_03_02_2021_bold_combined.tsv >> mergedPIDs_to_bold_result.txt' >> get_pidinfo_to${NUM_PIDS}.sh
	perl -pi -e "s/_to_bold_/_to${npids}_bold_/g" get_pidinfo_to${NUM_PIDS}.sh
	echo 'done' >> get_pidinfo_to${NUM_PIDS}.sh
fi
date
for script in get_pidinfo_to*.sh; do
	echo "running $script ..."
	bash $script &
done
wait
date
echo "Finished retrieving process ID metadata."
echo
if [ -e ../Animalia_03_02_2021_bold_combined.tsv ]; then
	rm ../Animalia_03_02_2021_bold_combined.tsv
fi
if [ -e missing_OTUs_bold_combined.tsv ]; then
	rm missing_OTUs_bold_combined.tsv
fi
cat mergedPIDs_*_bold_result.txt >> missing_OTUs_bold_combined.tsv

# ========================================================================================================
# in this section a bug is corrected which is introduced somewhere upstream, but has not been identified
# the bug fails to join the extra information retrieved by grepping the BOLD combined table for some BINs
# this is part 2 of the bugfix
# ========================================================================================================
join -t $'\t' -a 1 -1 1 -2 1 -o 1.1,2.22,2.55,2.8 <(perl -pe 's/ /\t/g' recs_from_missing_OTUs.temp | sort -t $'\t' -k1,1) <(sort -t $'\t' -k1,1 missing_OTUs_bold_combined.tsv) | perl -pe 's/^/no\t/g' | perl -pe 's/\tBOLD:(\w+)/\thttp:\/\/www.boldsystems.org\/index.php\/Public_BarcodeCluster\?clusteruri\=BOLD:\1\tBOLD:\1/g' > missing_OTUs_joined_dupl_BINsh_sp_country_link.temp

#1# cut column containing BINs and paste over BIN column of file recs_from_missing_OTUs.temp - done by joining the BIN col
NUM_COLS_OTUTAB=$(awk -F'\t' '{print NF; exit}' otu_table_0.98.txt)
let CUTOFF_OTUS=$NUM_COLS_OTUTAB+9 # there are 10 columns in the recs file preceding the OTU read counts columns
output_cols_otus=$(seq 11 1 $CUTOFF_OTUS | perl -pe 's/(\d+)\n/1.\1,/g' | perl -pe 's/\,$/\n/g') # getting the cols of otu counts
#2# remove the column containing process IDs - joining on process ID, but not outputting it; BIN col is 2.6
join -a 1 -t $'\t' -1 1 -2 2 -o 1.1,2.6,1.3,1.4,1.5,1.6,1.7,1.8,1.9,1.10,$output_cols_otus,2.1,2.3,2.4,2.5 <(perl -pe 's/ /\t/g' recs_from_missing_OTUs.temp | sort -t $'\t' -k1,1) <(sort -t $'\t' -k2,2 missing_OTUs_joined_dupl_BINsh_sp_country_link.temp) | sort | uniq | perl -pe 's/^(.*)http(.*)$/\1\thttp\2/g' > missing_OTUs_with_recs.temp
#3# last perl statement inserts an empty column in the file missing_OTUs_joined_dupl_BINsh_sp_country_link.temp between BIN countries and BOLD link (tab-sep)

#4# concatenate the resulting file with the file ${PROJECT}_final.csv and sort on BIN
cat <(tail -n +2 ${PROJECT}_final.csv) <(perl -pe 's/\t/,/g' missing_OTUs_with_recs.temp) | sort -t ',' -k2,2 > all_OTUs_with_recs.temp
#5# remove from records without a BIN the columns BIN sharing and BIN species
awk_otu_cols=$(echo $output_cols_otus | perl -pe 's/1\.//g')
let country_field=$CUTOFF_OTUS+3
cat <(awk -F ',' -v OFS="," '{if($NF!=""){print $0}}' all_OTUs_with_recs.temp) <(paste -d ',' <(awk -F ',' -v OFS="," '{if($NF==""){print $0}}' all_OTUs_with_recs.temp | cut -d ',' -f 1-10,${awk_otu_cols} | perl -pe 's/^(.*)$/\1,,/g') <(awk -F ',' -v OFS="," '{if($NF==""){print $0}}' all_OTUs_with_recs.temp | cut -d ',' -f ${country_field}) | perl -pe 's/^(.*)$/\1,,/g') > all_OTUs_with_recs.final

#6# output resulting columns BIN and BIN %ID into file bins_with_%id_input.temp
awk -F ',' -v OFS="," '{if($NF!=""){print $0}}' all_OTUs_with_recs.temp | sort -t ',' -k2,2 | cut -d ',' -f 2,3 | perl -pe 's/,/\t/g' > bins_with_%id_input.temp

# get the correct %range
perl -pe 's/\t/,/g' bins_with_%id_input.temp | awk -F ',' '{if(a[$1])a[$1]=a[$1]","$2; else a[$1]=$2;}END{for (i in a)print i, a[i];}' | perl -pe 's/ /,/g' | awk -F ',' '{min=$2;max=$2;a=0;for (i=2;i<=NF;i++) {a+=$i;if ($i < min){min=$i};if ($i > max){max=$i}};print $1"\t"min*100"%", "to", max*100"%"}' | grep 'BOLD' | sort | uniq > bins_%range_uniq.temp
join -t $'\t' -a 1 -1 1 -2 1 -o 2.2 <(sort -t $'\t' -k1,1 bins_with_%id_input.temp) <(sort -t $'\t' -k1,1 bins_%range_uniq.temp) > dupl_%range.temp

# paste this over original %s in the BINsharing table after sorting on BIN
let bold_link_field=$country_field+2
paste -d ',' <(cut -d ',' -f 1-${country_field} all_OTUs_with_recs.final) <(cat dupl_%range.temp) <(cut -d ',' -f ${bold_link_field} all_OTUs_with_recs.final) > all_OTUs_with_recs.csv

# checking for correct BIN sharing information and for correct countries information
tail -n +2 missing_OTUs_bold_combined.tsv | cut -f 8,55 | sort | uniq | perl -pe 's/ /_/g' > missing_OTUs_countries_uniq.txt
tail -n +2 missing_OTUs_bold_combined.tsv | cut -f 8,22 | sort | uniq | perl -pe 's/ /_/g' > missing_OTUs_species_uniq.txt
awk '{if($2!=""){print $0}}' missing_OTUs_countries_uniq.txt | sort | uniq | awk '{if(a[$1])a[$1]=a[$1]"|"$2; else a[$1]=$2;}END{for (i in a)print i, a[i];}' > missing_OTUs_countries_grouped.txt
awk '{if($2!=""){print $0}}' missing_OTUs_species_uniq.txt | sort | uniq | awk '{if(a[$1])a[$1]=a[$1]"|"$2; else a[$1]=$2;}END{for (i in a)print i, a[i];}' > missing_OTUs_species_grouped.txt
awk '{a=gsub(/\|/,""); if($2!="") b=a+1; else b=a; print $1,b}' missing_OTUs_species_grouped.txt | perl -pe 's/(.*) 0$/\1 unknown/g' | perl -pe 's/(.*) 1$/\1 no/g' | perl -pe 's/(.*) \d+$/\1 yes/g' > missing_OTUs_species_binsharing.txt
join -1 1 -2 1 -o 1.1,1.2,2.2 missing_OTUs_species_binsharing.txt missing_OTUs_species_grouped.txt | perl -pe 's/ /,/g' | perl -pe 's/^(.*),(.*),(.*)/\1\t\2,\3/g' > missing_OTUs_joined_speciesgroups_binsharing.csv.temp
join -1 1 -2 1 -o 1.1,1.2,1.3,2.2 <(sort -k1,1 missing_OTUs_joined_speciesgroups_binsharing.csv.temp) <(cat missing_OTUs_countries_grouped.txt | perl -pe 's/ /\t/g' | sort -k1,1) | perl -pe 's/^(.*) (.*)  (.*)$/\1\t\2,\3/g' > missing_OTUs_joined_countriesgroups_speciesgroups_binsharing.temp

# first loop iterates over all OTUs where countries have to be corrected
# second loop iterates over every OTU of the particular BIN and echoes the correct countries as many times as there are OTUs in that BIN ("wc -l" statement)
# inside grep matches the BIN, while outside grep uses that to fetch the lines from the original file that contain those BINs
# the result is a list of countries that is to be then joined (pasted) over those same records in the original file
for j in $(seq 1 1 $(grep '|' missing_OTUs_countries_grouped.txt | wc -l)); do for i in $(seq 1 1 $(grep $(grep '|' missing_OTUs_countries_grouped.txt | head -n $j | tail -1 | cut -d ' ' -f 1) all_OTUs_with_recs.csv | wc -l)); do echo $(grep '|' missing_OTUs_countries_grouped.txt | head -n $j | tail -1 | cut -d ' ' -f 2); done; done > countries_for_pasting.temp
# next, create two sub-tables from table "all_OTUs_with_recs.csv", one with just the BINs that need to be corrected, and one with all the other BINs - the first one is then joined with the corrected countries, and subsequently concatenated again with the second
for i in $(seq 1 1 $(grep '|' missing_OTUs_countries_grouped.txt | wc -l)); do grep $(grep '|' missing_OTUs_countries_grouped.txt | head -n $i | tail -1 | cut -d ' ' -f 1) all_OTUs_with_recs.csv; done >> subtable_target_otus_tobecorrected.temp
comm -13 <(sort subtable_target_otus_tobecorrected.temp) <(sort all_OTUs_with_recs.csv) > subtable_remaining_otus_withcorrectcountries.temp
let species_field=$country_field-1
let perc_field=$country_field+1
paste -d ',' <(cut -d ',' -f 1-${species_field} subtable_target_otus_tobecorrected.temp) <(cat countries_for_pasting.temp) <(cut -d ',' -f ${perc_field}- subtable_target_otus_tobecorrected.temp) > subtable_corrected_countries.temp
cat subtable_corrected_countries.temp subtable_remaining_otus_withcorrectcountries.temp | sort -t ',' -k2,2 > uncleaned_BIN_sharing_table.temp

# make cleaned BIN sharing table - run otu_table_cleaning.sh - get the headers and OTU names from uncorrected OTU table
cp ~/Desktop/pipeline_utils/otu_table_cleaning.sh .
bash otu_table_cleaning.sh
paste -d '\t' <(cut -f 1 otu_table_0.98.txt) <(cat <(head -1 otu_table_0.98.txt | cut -f 2-) otu_table_0.98_cleaned.txt) > temp
rm otu_table_0.98_cleaned.txt
mv temp otu_table_0.98_cleaned.txt
# copy all OTUs to file "under_0.97_OTUs.temp" - copy only the OTU;size column
cut -d ',' -f 10 uncleaned_BIN_sharing_table.temp > under_0.97_OTUs.temp
NUM_COLS_OTUTAB=$(awk -F'\t' '{print NF; exit}' otu_table_0.98.txt)
let CUTOFF_ONE=$NUM_COLS_OTUTAB
# join read numbers from cleaned file on these OTUs
output_cols=$(seq 2 1 $CUTOFF_ONE | perl -pe 's/(\d+)\n/2.\1,/g' | perl -pe 's/\,$/\n/g')
join -a 1 -t $'\t' -1 1 -2 1 <(perl -pe 's/;size/\tsize/g' under_0.97_OTUs.temp | sort -t $'\t' -k1,1) <(tail -n +2 otu_table_0.98_cleaned.txt | sort -t $'\t' -k1,1) -o $output_cols > under_0.97_cleaned_OTUs.temp

# paste the contents of "under_0.97_cleaned_OTUs.temp" over the original read counts of the file "uncleaned_BIN_sharing_table.temp"
# make sure the OTUs in the input files are sorted on column OTU;cluster_size
NUM_COLS_OTUTAB=$(awk -F'\t' '{print NF; exit}' otu_table_0.98.txt)
let CUTOFF_BININFO=$NUM_COLS_OTUTAB+10
perl -pe 's/,/\t/g' uncleaned_BIN_sharing_table.temp | perl -pe 's/OTU_/OTU\t/g' | perl -pe 's/;size/\t;size/g' | sort -t $'\t' -d -k11,11 | perl -pe 's/OTU\t/OTU_/g' | perl -pe 's/\t;size/;size/g' | cut -f 1-10 > uncleaned_BIN_sharing_OTU_info.temp
perl -pe 's/,/\t/g' uncleaned_BIN_sharing_table.temp | perl -pe 's/OTU_/OTU\t/g' | perl -pe 's/;size/\t;size/g' | sort -t $'\t' -d -k11,11 | perl -pe 's/OTU\t/OTU_/g' | perl -pe 's/\t;size/;size/g' | cut -f $CUTOFF_BININFO- > uncleaned_BIN_sharing_BIN_info.temp
cat <(head -1 ${PROJECT}_final.csv | perl -pe 's/,/\t/g') <(paste -d '\t' <(cat uncleaned_BIN_sharing_OTU_info.temp) <(cat under_0.97_cleaned_OTUs.temp) <(cat uncleaned_BIN_sharing_BIN_info.temp)) > cleaned_BIN_sharing_table.temp
# copy columns "ProcID" through "OTU;cluster_size" into an empty file, name it "from_xlsx_cleaned_OTUs.input", and save in the "results" subfolder
cut -f 1-10 cleaned_BIN_sharing_table.temp > from_xlsx_cleaned_OTUs.input
# then, join the table with NCBI BLAST results
join -a 1 -t $'\t' -1 10 -2 7 <(tail -n +2 from_xlsx_cleaned_OTUs.input | perl -pe 's/;size/\tsize/g' | sort -t $'\t' -k10,10) <(perl -pe 's{\d+\.\d+%}{$&/100}eg' ${PROJECT}_NCBI_nt_blast_result.reformatted.tsv | perl -pe 's/ /_/g' | perl -pe 's/OTU_/OTU\t/g' | sort -n -t $'\t' -k8,8 | perl -pe 's/OTU\t/OTU_/g' | sort -t $'\t' -k7,7) -o 1.1,1.2,1.3,1.4,1.5,1.6,1.7,1.8,1.9,1.10,1.11,2.1,2.2,2.3,2.4 | perl -pe 's/\tsize/;size/g' > from_xlsx_cleaned_OTUs.joinedNCBI

# insert five empty columns before the sample columns, and after the column "OTU;cluster_size"
# making sure the OTUs are sorted on the "OTU;cluster_size" column, copy the data from the file "from_xlsx_cleaned_OTUs.joinedNCBI" over the BIN_sharing_table
paste -d '\t' <(cat <(paste -d '\t' <(head -1 cleaned_BIN_sharing_table.temp | cut -f 1-10) <(echo "NCBI_nt,Species,%_identity,Description" | perl -pe 's/,/\t/g')) from_xlsx_cleaned_OTUs.joinedNCBI) <(cut -f 11- cleaned_BIN_sharing_table.temp) > cleaned_BIN_sharing_NCBI_table.temp
# insert an empty column just after the "%_identity" column, and copy over the "Seq_length" column from the file (table) "BOLD_merge_OTU_table.temp"
# name the empty column just preceding the sample count columns "sum_reads_per_OTU", and in it, sum over the read numbers in the following sample count columns
let NUM_SAMPLES=$NUM_COLS_OTUTAB-1
# previous line subtracts 1 because under_0.97_cleaned_OTUs.temp does not have an "#OTU;cluster_size" column
awk -v var="$NUM_SAMPLES" '{for(i=1;i<=var;i++) sum+=$i; print sum; sum=0}' under_0.97_cleaned_OTUs.temp > sum_reads_per_OTU.temp
paste -d '\t' <(cut -f 1-3 cleaned_BIN_sharing_NCBI_table.temp) <(cat <(echo "Seq_length") <(cut -d ' ' -f 6 BOLD_merge_OTU_table.temp)) <(cut -f 4-14 cleaned_BIN_sharing_NCBI_table.temp) <(cat <(echo "sum_reads_per_OTU") sum_reads_per_OTU.temp) <(cut -f 15- cleaned_BIN_sharing_NCBI_table.temp) > cleaned_BIN_sharing_seqlen_NCBI_sumreads_table.tsv

# filter out OTUs with Seq_length < 100 and with 0 total reads after 0.01% cleaning
tail -n +2 cleaned_BIN_sharing_seqlen_NCBI_sumreads_table.tsv | awk -F'\t' '$16 > 0' | awk -F'\t' '$4 > 99' > filtered_BIN_sharing_seqlen_NCBI_sumreads_table.nohead
# get its header back
cat <(head -1 cleaned_BIN_sharing_seqlen_NCBI_sumreads_table.tsv) filtered_BIN_sharing_seqlen_NCBI_sumreads_table.nohead > filtered_BIN_sharing_seqlen_NCBI_sumreads_table.tsv

# ========================================================================================================
# COI classifier
# ========================================================================================================

# run the COI classifier algorithm
echo "Assigning taxonomy using the COI-trained RDP classifier algorithm..."
java -Xmx8g -jar ~/Downloads/COI_classifier/rdp_classifier_2.12/dist/classifier.jar \
classify -t ~/Downloads/COI_classifier/CO1v3_2_trained/mydata_trained/rRNAClassifier.properties \
-o RDPClass_${PROJECT}_combined.out \
../otus_0.98.fasta

# reformat the output, subsetting some columns
cut -f 1,4-6,8-9,11-12,14-15,17-18,20-21,23-24,26-27,29 RDPClass_${PROJECT}_combined.out > RDPClass_${PROJECT}_combined.subset.cols

# join with big table ("cleaned_BIN_sharing_seqlen_NCBI_sumreads_table.tsv")
 # first, get the column numbers for joining
  # first 15 cols of big table
COLS_PHYL=$(seq 1 1 15 | perl -pe 's/(\d+)\n/1.\1,/g' | perl -pe 's/\,$/\n/g')
  # classifier cols
COLS_CLASSIF=$(seq 4 1 19 | perl -pe 's/(\d+)\n/2.\1,/g' | perl -pe 's/\,$/\n/g')
  # cols 16-end of big table (BIN info cols)
NUM_COLS_OTUTAB=$(awk -F'\t' '{print NF; exit}' otu_table_0.98.txt)
let COLS_TOT=$NUM_COLS_OTUTAB+20
COLS_BININFO=$(seq 16 1 $COLS_TOT | perl -pe 's/(\d+)\n/1.\1,/g' | perl -pe 's/\,$/\n/g')
 # then, join the three parts together 
#join -a 1 -t $'\t' -1 11 -2 1 <(tail -n +2 filtered_BIN_sharing_seqlen_NCBI_sumreads_table.tsv | sort -t $'\t' -k11,11) <(sort -t $'\t' -k1,1 RDPClass_Weisser_combined_fwd.subset.cols) -o $COLS_PHYL,$COLS_CLASSIF,$COLS_BININFO > filtered_BIN_sharing_seqlen_NCBI_sumreads_table.joinedRDP
join -a 1 -t $'\t' -1 11 -2 1 <(tail -n +2 filtered_BIN_sharing_seqlen_NCBI_sumreads_table.tsv | sort -t $'\t' -k11,11) <(sort -t $'\t' -k1,1 RDPClass_${PROJECT}_combined.subset.cols) -o $COLS_PHYL,$COLS_CLASSIF,$COLS_BININFO > filtered_BIN_sharing_seqlen_NCBI_sumreads_table.joinedRDP
 # make the appropriate header
paste -d '\t' <(head -1 filtered_BIN_sharing_seqlen_NCBI_sumreads_table.tsv | cut -f 1-15) <(echo "RDP_Domain,RDP_Domain_support,RDP_Kingdom,RDP_Kingdom_support,RDP_Phylum,RDP_Phylum_support,RDP_Class,RDP_Class_support,RDP_Order,RDP_Order_support,RDP_Family,RDP_Family_support,RDP_Genus,RDP_Genus_support,RDP_Species,RDP_Species_support" | perl -pe 's/,/\t/g') <(head -1 filtered_BIN_sharing_seqlen_NCBI_sumreads_table.tsv | cut -f 16-) > header_RDP_joining.temp
 # concatenate
cat header_RDP_joining.temp filtered_BIN_sharing_seqlen_NCBI_sumreads_table.joinedRDP > cleaned_BIN_sharing_NCBI_RDP.tsv

PROJECT=$(ls *final.csv | perl -pe 's/^(.*)_final\.csv/\1/g')

# NCBI taxonomy
tail -n +2 cleaned_BIN_sharing_NCBI_RDP.tsv | cut -f 12 > ${PROJECT}_accessions_all.txt

NUM_ACCS=$(cat ${PROJECT}_accessions_all.txt | wc -l)
if [ $NUM_ACCS -gt 99 ]; then
	SPLIT_CMD_ACCS=$(seq 100 100 $NUM_ACCS)
else
	SPLIT_CMD_ACCS=$NUM_ACCS
fi
BIGGEST_ACCS=$(echo $SPLIT_CMD_ACCS | perl -pe 's/ /\n/g' | tail -1)
let REMAINDER_ACCS=$NUM_ACCS-$BIGGEST_ACCS
for s in $SPLIT_CMD_ACCS; do
	head -n $s ${PROJECT}_accessions_all.txt | tail -100 > split_cmd_accs_to${s}.txt
	echo '#!/bin/bash' >> get_ncbitaxacc_to${s}.sh
	naccs=$s
	echo 'cat split_cmd_accs_to_.txt | while read ACC; do bash get_ncbi_taxonomy.sh "$ACC"; done > to__NCBI_taxonomy.tsv' >> get_ncbitaxacc_to${s}.sh
	perl -pi -e "s/to_/to${naccs}/g" get_ncbitaxacc_to${s}.sh
done
if [ $NUM_ACCS -gt 100 ]
then
	tail -n $REMAINDER_ACCS ${PROJECT}_accessions_all.txt > split_cmd_accs_to${NUM_ACCS}.txt
	echo '#!/bin/bash' >> get_ncbitaxacc_to${NUM_ACCS}.sh
	naccs=$NUM_ACCS
	echo 'cat split_cmd_accs_to_.txt | while read ACC; do bash get_ncbi_taxonomy.sh "$ACC"; done > to__NCBI_taxonomy.tsv' >> get_ncbitaxacc_to${NUM_ACCS}.sh
	perl -pi -e "s/to_/to${naccs}/g" get_ncbitaxacc_to${NUM_ACCS}.sh
fi

workingdir=$(pwd)
cd ~/Desktop/pipeline_utils/NCBI_taxonomy/
cp $workingdir/split_cmd_accs_to*.txt .
cp $workingdir/get_ncbitaxacc_to*.sh .

date
for script in get_ncbitaxacc_to*.sh; do
	echo "running $script"	
	bash $script &
done
wait
date

cat to*_NCBI_taxonomy.tsv > ${PROJECT}_NCBI_taxonomy.tsv

rm split_cmd_accs_to*.txt
rm get_ncbitaxacc_to*.sh

cp ${PROJECT}_NCBI_taxonomy.tsv $workingdir
cd $workingdir

# format fields for joining - big table 1-13, ncbi table, big table 14-
out_fields_bigtab_to13=$(seq 1 1 13 | \
	perl -pe 's/^(.*)\n$/1\.\1,/g' | \
	perl -pe 's/,$/\n/g')
NUM_COLS_BIGTAB=$(awk -F'\t' '{print NF; exit}' cleaned_BIN_sharing_NCBI_RDP.tsv)
out_fields_bigtab_14to=$(seq 14 1 $NUM_COLS_BIGTAB | \
	perl -pe 's/(\d+)\n/1.\1,/g' | \
	perl -pe 's/\,$/\n/g')
# in the next line, we grep the Drosophila lines because they contain the longest possible taxonomy (because NCBI taxonomy is of inconsistent depth depending on the specific taxon - some taxa contain subfamilies, suborders, infraorders, etc. - while other taxa do not)
#NUM_COLS_NCBITAX=$(grep 'Drosophila' ${PROJECT}_NCBI_taxonomy.tsv | \
#	perl -pe 's/;/\t/g' | \
#	awk -F'\t' '{print NF-1; exit}')
# better version - tr | wc -L make sure that the longest line is counted for columns + this approach is universally applicable
NUM_COLS_NCBITAX=$(perl -pe 's/;/|/g' ${PROJECT}_NCBI_taxonomy.tsv | \
	perl -pe 's/\t/|/g' | \
	perl -pe 's/ /_/g' | \
	tr -dc $'\n|' | \
	wc -L)
out_fields_ncbitab=$(seq 2 1 $NUM_COLS_NCBITAX | \
	perl -pe 's/(\d+)\n/2.\1,/g' | \
	perl -pe 's/\,$/\n/g')
# join
join -a 1 -t $'\t' -1 12 -2 1 <(tail -n +2 cleaned_BIN_sharing_NCBI_RDP.tsv | sort -t $'\t' -k12,12) <(perl -pe 's/;/\t/g' ${PROJECT}_NCBI_taxonomy.tsv | sort -t $'\t' -k1,1) -o $out_fields_bigtab_to13,$out_fields_ncbitab,$out_fields_bigtab_14to | uniq > results_noheader_raw.tsv
# add header
header_ncbitax_to09=$(seq 1 1 9 | \
	perl -pe 's/(\d+)\n/NCBI_taxon_0\1,/g' | \
	perl -pe 's/\,$/\n/g')
# to format the headers for NCBI taxonomy correctly, we need to subtract 1 from the total number of fields from the NCBI tax tab because its first field is the Accession ID
let NCBI_taxa_number=$NUM_COLS_NCBITAX-1
header_ncbitax_10to=$(seq 10 1 $NCBI_taxa_number | \
	perl -pe 's/(\d+)\n/NCBI_taxon_\1,/g' | \
	perl -pe 's/\,$/\n/g')
paste -d '\t' <(head -1 cleaned_BIN_sharing_NCBI_RDP.tsv | cut -f 1-13) <(paste -d '\t' <(echo $header_ncbitax_to09 | perl -pe 's/,/\t/g') <(echo $header_ncbitax_10to | perl -pe 's/,/\t/g')) <(head -1 cleaned_BIN_sharing_NCBI_RDP.tsv | cut -f 14-) > header_results_raw.tsv
# concatenate
cat header_results_raw.tsv results_noheader_raw.tsv > results_raw.tsv

# make sure that the species field does not contain spaces
awk 'BEGIN{FS=OFS="\t"} {gsub(/\ /, "_", $10)} 1' results_raw.tsv > temp
rm results_raw.tsv
mv temp results_raw.tsv

# incorporate red list information (join on species)
REDLIST_FILE=redlist_Mueller_2020_grouped.tsv
cp ~/Downloads/Red_list/Joerg_Mueller_version/${REDLIST_FILE} .
NUM_COLS_RESRAW=$(awk -F'\t' '{print NF; exit}' results_raw.tsv)
out_fields_results_raw=$(seq 1 1 $NUM_COLS_RESRAW | \
	perl -pe 's/(\d+)\n/1.\1,/g' | \
	perl -pe 's/\,$/\n/g')
NUM_COLS_REDL=$(awk -F'\t' '{print NF; exit}' ${REDLIST_FILE})
out_fields_red_list=$(seq 1 1 $NUM_COLS_REDL | \
	perl -pe 's/(\d+)\n/2.\1,/g' | \
	perl -pe 's/\,$/\n/g')
join -a 1 -t $'\t' -1 10 -2 1 <(tail -n +2 results_raw.tsv | perl -pe 's/ /_/g' | sort -t $'\t' -k10,10) <(tail -n +2 ${REDLIST_FILE} | perl -pe 's/ /_/g' | sort -t $'\t' -k1,1) -o $out_fields_results_raw,$out_fields_red_list > noheader_redlist_results_raw.csv
cat <(paste -d '\t' <(head -1 results_raw.tsv) <(head -1 ${REDLIST_FILE})) noheader_redlist_results_raw.csv > redlist_results_raw.csv

sed -i 's/%_identity/pct_identity/' redlist_results_raw.csv
sed -i 's/BIN sharing\?/BIN_sharing/' redlist_results_raw.csv
sed -i 's/pct_identity/%_identity/' redlist_results_raw.csv
sed -i 's/BIN_sharing/BIN sharing?/' redlist_results_raw.csv

# report
cp ~/Downloads/aim-report/Feathertheme.tex ..
cp ~/Desktop/scripts/edit_LaTeX_for_pdf_Report.sh ..


 #######                                                 
 #       #    #  ####  ###### #                          
 #        #  #  #    # #      #                          
 #####     ##   #      #####  #                          
 #         ##   #      #      #                          
 #        #  #  #    # #      #                          
 ####### #    #  ####  ###### ######                     
                                                         
  #####                                                  
 #     # #    #  ####  #####  ####  #    # ###### #####  
 #       #    # #        #   #    # ##  ## #      #    # 
 #       #    #  ####    #   #    # # ## # #####  #    # 
 #       #    #      #   #   #    # #    # #      #####  
 #     # #    # #    #   #   #    # #    # #      #   #  
  #####   ####   ####    #    ####  #    # ###### #    # 
                                                         
 ######                                                  
 #     # ###### #####   ####  #####  #####               
 #     # #      #    # #    # #    #   #                 
 ######  #####  #    # #    # #    #   #                 
 #   #   #      #####  #    # #####    #                 
 #    #  #      #      #    # #   #    #                 
 #     # ###### #       ####  #    #   #                 
                                                         
         #####                                           
 #    # #     #                                          
 #    #       #                                          
 #    #  #####                                           
 #    # #                                                
  #  #  #                                                
   ##   #######                                          

######################################################################################################################
              
<< 'INPUTS'
0. install taxonkit: tar -xzvf taxonkit_linux_amd64.tar.gz; sudo cp taxonkit /usr/local/bin/; cd; taxonkit genautocomplete
1. BLAST_BOLD_Grades.tsv - columns 4-5 from Geneious exported BLAST results when including "Grade" in the output dialog (BOLD BLAST results)
2. BLAST_NCBI_Grades.tsv - columns 4-5 from Geneious exported BLAST results when including "Grade" in the output dialog (NCBI BLAST results)
3. redlist_results_raw.tsv - former final output wrapper.sh script, with neg. controls
4. otu_table_0.98.txt - the OTU table is necessary to count the number of samples
5. ~/Desktop/pipeline_utils/NCBI_taxonomy/acc_taxid.dmp - big relational table containing NCBI accessions and taxIDs used to retrieve NCBI taxonomy by dev_wrapper.sh
6. unzipped inputs for taxonkit - citations.dmp, delnodes.dmp, division.dmp, gencode.dmp, merged.dmp, names.dmp, nodes.dmp, gc.prt, readme.txt - got them by running "wget ftp://ftp.ncbi.nih.gov/pub/taxonomy/taxdump.tar.gz; tar -xzvf taxdump.tar.gz; rm taxdump.tar.gz"
7. the script edit_custom_string_for_consensus_taxonomy.sh - helper script
8. CUSTOM_STRING_TEMPLATE.txt - template for another (customized) helper script to be edited by above helper script => result is "CUSTOM_STRING_EDITED.sh" that then gets run by the main script
INPUTS

<< 'OUTPUTS'
Intermediate files:
1. redlist_grade_B.temp - redlist with the BOLD "Grade" added as the 3rd column
2. redlist_grade_NandB.temp - redlist with the BOLD "Grade" added as the 3rd column and NCBI "Grade" as the 51st
3. redlist_taxID.temp - added taxID by joining from big relational table
4. redlist_taxonkit.temp - added long taxonomy to end of file using taxonkit lineage
5. redlist_taxonkit_short.temp - added short taxonomy to end of file using taxonkit reformat
6. redlist_taxonkit_final.temp - NCBI long taxonomy replaced by NCBI short taxonomy using taxonkit
7. redlist_binshfix.temp - added penalty to BOLD "Grade" if BIN sharing? = yes
8. redlist_filtered_B.temp - BOLD taxonomy filtered based on the "Grade" value
9. redlist_filtered_N.temp - NCBI taxonomy filtered based on the "Grade" value
10. CUSTOM_STRING_EDITED.sh - 
10. redlist_taxcompared.temp - 
11. redlist_scores.temp - 
12. redlist_consensus.temp - 
13. redlist_reordered_nohead.tsv - 
Final output: redlist_reordered_raw.tsv
OUTPUTS

# copy over the helper script and the template for it
cp '/home/laur/Desktop/pipeline_utils/NCBI_taxonomy/edit_custom_string_for_consensus_taxonomy.sh' .
cp '/home/laur/Desktop/pipeline_utils/NCBI_taxonomy/CUSTOM_STRING_TEMPLATE.txt' .
# location of the directory containing the files taxonkit needs
DATADIR="/home/laur/Desktop/pipeline_utils/NCBI_taxonomy/taxonkit_files/"

# join Grades data to redlist_results_raw, first BOLD, then NCBI:
REDLIST=redlist_results_raw.csv
NUM_COLS_TOT=$(awk -F'\t' '{print NF; exit}' $REDLIST)
GRADE_B=BLAST_BOLD_Grades.tsv
JOIN_OUT=$(seq 4 1 $(awk -F'\t' '{print NF; exit}' $REDLIST) | perl -pe 's/(\d+)/1.\1/g' | perl -pe 's/\n/,/g' | perl -pe 's/,$/\n/g')
OTU_ID_REDLIST=11
OTU_ID_GRADE=2
join -a 1 -t $'\t' -1 $OTU_ID_REDLIST -2 $OTU_ID_GRADE <(tail -n +2 $REDLIST | sort -t $'\t' -k11,11) <(tail -n +2 $GRADE_B | sort -t $'\t' -k2,2) -o 1.1,1.2,1.3,2.1,${JOIN_OUT} > redlist_grade_B.temp
GRADE_N=BLAST_NCBI_Grades.tsv
# calculate the column number of the NCBI ID%
NUM_COLS_OTUTAB=$(awk -F'\t' '{print NF; exit}' otu_table_0.98.txt)
let NUM_SAMPLES=$NUM_COLS_OTUTAB-1
NUM_OTHER_COLS=60
NUM_COLS_BEFORE_NCBITAX=14
let COL_NCBI_PERCENT=$NUM_COLS_TOT-$NUM_SAMPLES-$NUM_OTHER_COLS+$NUM_COLS_BEFORE_NCBITAX+1
# format the output fields for joining
awk -F $'\t' '{ OFS=FS; gsub(/\%/,"",$3) }1' $REDLIST | awk -F $'\t' '{ OFS=FS; pct=$3*100; $3=pct"%" }1' | awk -F $'\t' -v grade="$COL_NCBI_PERCENT" '{ OFS=FS; gsub(/\%/,"",$grade) }1' | awk -F $'\t' -v grade="$COL_NCBI_PERCENT" '{ OFS=FS; pct=$grade*100; $grade=pct"%" }1' > temp
rm $REDLIST
mv temp $REDLIST
JOIN_OUT_P1=$(seq 1 1 $COL_NCBI_PERCENT | perl -pe 's/(\d+)/1.\1/g' | perl -pe 's/\n/,/g' | perl -pe 's/,$/\n/g')
let COL_NCBI_GRADE=$COL_NCBI_PERCENT+1
JOIN_OUT_P2=$(seq $COL_NCBI_GRADE 1 $(awk -F'\t' '{print NF; exit}' $REDLIST) | perl -pe 's/(\d+)/1.\1/g' | perl -pe 's/\n/,/g' | perl -pe 's/,$/\n/g')
REDLIST=redlist_grade_B.temp
awk -F $'\t' '{ OFS=FS; gsub(/\%/,"",$3) }1' $REDLIST | awk -F $'\t' '{ OFS=FS; pct=$3*100; $3=pct"%" }1' | awk -F $'\t' -v grade="$COL_NCBI_PERCENT" '{ OFS=FS; gsub(/\%/,"",$grade) }1' > temp
rm $REDLIST
mv temp $REDLIST
REDLIST=redlist_grade_B.temp
OTU_ID_REDLIST=12
# join
join -a 1 -t $'\t' -1 $OTU_ID_REDLIST -2 $OTU_ID_GRADE <(sort -t $'\t' -k12,12 $REDLIST) <(tail -n +2 $GRADE_N | sort -t $'\t' -k2,2) -o ${JOIN_OUT_P1},2.1,${JOIN_OUT_P2} > redlist_grade_NandB.temp
# join the taxID
REDLIST=redlist_grade_NandB.temp
awk -F $'\t' -v grade="$COL_NCBI_PERCENT" '{ OFS=FS; gsub(/\%/,"",$grade) }1' $REDLIST | awk -F $'\t' -v grade="$COL_NCBI_PERCENT" '{ OFS=FS; pct=$grade*100; $grade=pct"%" }1' > temp
rm $REDLIST
mv temp $REDLIST
REDLIST=redlist_grade_NandB.temp
ACCESSION_REDLIST=13
BIGTAB=/home/laur/Desktop/pipeline_utils/NCBI_taxonomy/acc_taxid.dmp
ACCESSION_BIGTAB=1
JOIN_OUT_P1=$(seq 1 1 $ACCESSION_REDLIST | perl -pe 's/(\d+)/1.\1/g' | perl -pe 's/\n/,/g' | perl -pe 's/,$/\n/g')
JOIN_OUT_P2=$(seq 15 1 $(awk -F'\t' '{print NF; exit}' $REDLIST) | perl -pe 's/(\d+)/1.\1/g' | perl -pe 's/\n/,/g' | perl -pe 's/,$/\n/g')
join -a 1 -t $'\t' -1 $ACCESSION_REDLIST -2 $ACCESSION_BIGTAB <(sort -t $'\t' -k13,13 $REDLIST) <(sort -t $'\t' -k1,1 $BIGTAB) -o ${JOIN_OUT_P1},2.2,${JOIN_OUT_P2} > redlist_taxID.temp
# replace the long taxonomy with the short one using taxonkit
cat redlist_taxID.temp | awk -F'\t' '{print $14"\t"$0}' | taxonkit --data-dir $DATADIR lineage > redlist_taxonkit.temp
REDLIST=redlist_taxonkit.temp
paste -d '\t' <(cut -f1 $REDLIST) <(cut -f $(awk -F'\t' '{print NF; exit}' $REDLIST) $REDLIST) <(cut -f 2-$(awk -F'\t' '{print NF-1; exit}' $REDLIST) $REDLIST) | taxonkit --data-dir $DATADIR reformat | cut -f 3- > redlist_taxonkit_short.temp
# calculate the column number of the NCBI ID%
REDLIST=redlist_taxonkit_short.temp
NUM_COLS_TOT=$(awk -F'\t' '{print NF; exit}' $REDLIST)
NUM_COLS_OTUTAB=$(awk -F'\t' '{print NF; exit}' otu_table_0.98.txt)
let NUM_SAMPLES=$NUM_COLS_OTUTAB-1
NUM_OTHER_COLS=62
NUM_COLS_BEFORE_NCBITAX=14
let COL_NCBI_PERCENT=$NUM_COLS_TOT-$NUM_SAMPLES-$NUM_OTHER_COLS+$NUM_COLS_BEFORE_NCBITAX+1
paste -d '\t' <(cut -f 1-$NUM_COLS_BEFORE_NCBITAX $REDLIST) <(cut -f $NUM_COLS_TOT $REDLIST | perl -pe 's/;/\t/g') <(cut -f $COL_NCBI_PERCENT- $REDLIST) | rev | cut -f 2- | rev > redlist_taxonkit_final.temp
# if species exists, Grade is > 97% and BIN sharing exists, give a penalty to Grade (reduce it to 94.99%)
let BINSH_COL=42+$NUM_SAMPLES
awk -F $'\t' '{ OFS=FS; gsub(/\%/,"",$4) }1' redlist_taxonkit_final.temp | awk -F $'\t' '{ OFS=FS; gsub(/\%/,"",$3) }1' | awk -F $'\t' '{ OFS=FS; gsub(/\%/,"",$22) }1' | awk -F $'\t' '{ OFS=FS; gsub(/\%/,"",$23) }1' | awk -F $'\t' -v var="$BINSH_COL" '{ OFS=FS; if ($3<97 && $4>=97) {$4="96.99"}; if ($var ~ /yes/ && $4>=97) {$4="96.99"}; $3=$3"%"; $4=$4"%"; if ($22<97 && $23>=97) {$23="96.99"}; $22=$22"%"; $23=$23"%"; print $0 }' > redlist_binshfix.temp
awk -F $'\t' '{ OFS=FS; gsub(/\%/,"",$4) }1' redlist_binshfix.temp | awk -F $'\t' '{ OFS=FS; gsub(/ /,"_",$21) }1' | awk -F $'\t' '{ OFS=FS; gsub(/ /,"_",$39) }1' | awk -F $'\t' '{ OFS=FS; if ($4>=100) { $0=$0 } else if ($4>=97) { $0=$0 } else if ($4>=95 && $4<97) { $11="" } else if ($4>=90 && $4<95) { $10=""; $11="" } else if ($4>=85 && $4<90) { $9=""; $10=""; $11="" } else if ($4>=80 && $4<85) { $8=""; $9=""; $10=""; $11="" } else if ($4>=75 && $4<80) { $7=""; $8=""; $9=""; $10=""; $11="" } else { $6=""; $7=""; $8=""; $9=""; $10=""; $11="" }; $4=$4"%"; print $0 }' > redlist_filtered_B.temp
# filter NCBI taxonomy based on the %value of "Grade" (column 23)
awk -F $'\t' '{ OFS=FS; gsub(/\%/,"",$23) }1' redlist_filtered_B.temp | awk -F $'\t' '{ OFS=FS; if ($23>=100) { $0=$0 } else if ($23>=97) { $0=$0 } else if ($23>=95 && $23<97) { $21="" } else if ($23>=90 && $23<95) { $20=""; $21="" } else if ($23>=85 && $23<90) { $19=""; $20=""; $21="" } else if ($23>=80 && $23<85) { $18=""; $19=""; $20=""; $21="" } else if ($23>=75 && $23<80) { $17=""; $18=""; $19=""; $20=""; $21="" } else { $16=""; $17=""; $18=""; $19=""; $20=""; $21="" }; $23=$23"%"; print $0 }' > redlist_filtered_N.temp
# make consensus
bash edit_custom_string_for_consensus_taxonomy.sh
wait
# calculate scores
awk -F $'\t' '{ OFS=FS; TC=0; if ($7!="") {TC=7} else if ($6!="") {TC=6} else if ($5!="") {TC=5} else if ($4!="") {TC=4} else if ($3!="") {TC=3} else if ($2!="") {TC=2} else if ($1!="") {TC=1}; BN=0; if ($14!="") {BN=7} else if ($13!="") {BN=6} else if ($12!="") {BN=5} else if ($11!="") {BN=4} else if ($10!="") {BN=3} else if ($9!="") {BN=2} else if ($8!="") {BN=1}; NR=0; if ($21!="") {NR=7} else if ($20!="") {NR=6} else if ($19!="") {NR=5} else if ($18!="") {NR=4} else if ($17!="") {NR=3} else if ($16!="") {NR=2} else if ($15!="") {NR=1}; if (TC == BN && TC == NR) { SCORE = "A" } else if (BN > TC && BN > NR) { SCORE = "B" } else { SCORE = "C" }; print TC,BN,NR,SCORE,$0 }' redlist_taxcompared.temp > redlist_scores.temp
# calculate consensus
awk -F $'\t' '{ OFS=FS; if ($4 ~ "C") { DOM=$19; PHY=$20; CLA=$21; ORD=$22; FAM=$23; GEN=$24; SPE=$25 } else if ($4 ~ "B") { DOM=$12; PHY=$13; CLA=$14; ORD=$15; FAM=$16; GEN=$17; SPE=$18 } else { DOM=$5; PHY=$6; CLA=$7; ORD=$8; FAM=$9; GEN=$10; SPE=$11 }; print DOM,PHY,CLA,ORD,FAM,GEN,SPE,$0 }' redlist_scores.temp > redlist_consensus.temp
# reorder: $33-$44 (BOLD stuff, OTU),$1-$11 (consensus+scores),$73 (sum),$74-?(samples),$45-$72 (NCBI stuff, RDP),$12-$32 (three consensus building taxonomies),?- (BOLD metadata, redlist)
# COL_FIRST_SAMPLE is the column where the OTU table starts
COL_FIRST_SAMPLE=74
NUM_COLS_OTUTAB=$(awk -F'\t' '{print NF; exit}' otu_table_0.98.txt)
let NUM_SAMPLES=$NUM_COLS_OTUTAB-1
let COL_LAST_SAMPLE=$COL_FIRST_SAMPLE+$NUM_SAMPLES-1
let COL_BINSHARING=$COL_FIRST_SAMPLE+$NUM_SAMPLES
REDLIST=redlist_consensus.temp
paste -d "\t" <(cut -f 33-44 $REDLIST) <(cut -f 1-11 $REDLIST) <(cut -f 73-${COL_LAST_SAMPLE} $REDLIST) <(cut -f 45-72 $REDLIST) <(cut -f 12-32 $REDLIST) <(cut -f ${COL_BINSHARING}- $REDLIST) | perl -pe 's/\t(\d+)%/\t\1.0%/g; s/_to_(\d+)%/_to_\1.0%/g' > redlist_reordered_nohead.tsv
# add header
HEADER_P1=$(echo "BOLD_Process_ID,BOLD_BIN_uri,BOLD_HIT%ID,BOLD_Grade%ID,BOLD_hit_Seq_Length,adjusted_Phylum_BOLD,adjusted_Class_BOLD,adjusted_Order_BOLD,adjusted_Family_BOLD,adjusted_Genus_BOLD,adjusted_Species_BOLD,OTU_ID;cluster_size,consensus_Domain,consensus_Phylum,consensus_Class,consensus_Order,consensus_Family,consensus_Genus,consensus_Species,tax_depth_triple_consensus,tax_depth_BOLD+NCBI_cons,tax_depth_NCBI+RDP_cons,consensus_score,sum_reads_per_OTU" | perl -pe 's/,/\t/g')
SAMPLE_NAMES=$(head -1 otu_table_0.98.txt | cut -f 2-)
HEADER_P2=$(echo "NCBI_Accession_ID,NCBI_tax_ID,adjusted_Domain_NCBI,adjusted_Phylum_NCBI,adjusted_Class_NCBI,adjusted_Order_NCBI,adjusted_Family_NCBI,adjusted_Genus_NCBI,adjusted_Species_NCBI,NCBI_HIT%ID,NCBI_Grade%ID,NCBI_Description,RDP_Domain,RDP_Domain_Bootstrap_Support,RDP_Kingdom,RDP_Kingdom_Bootstrap_Support,RDP_Phylum,RDP_Phylum_Bootstrap_Support,RDP_Class,RDP_Class_Bootstrap_Support,RDP_Order,RDP_Order_Bootstrap_Support,RDP_Family,RDP_Family_Bootstrap_Support,RDP_Genus,RDP_Genus_Bootstrap_Support,RDP_Species,RDP_Species_Bootstrap_Support,triple_consensus_Domain,triple_consensus_Phylum,triple_consensus_Class,triple_consensus_Order,triple_consensus_Family,triple_consensus_Genus,triple_consensus_Species,BOLD+NCBI_consensus_Domain,BOLD+NCBI_consensus_Phylum,BOLD+NCBI_consensus_Class,BOLD+NCBI_consensus_Order,BOLD+NCBI_consensus_Family,BOLD+NCBI_consensus_Genus,BOLD+NCBI_consensus_Species,NCBI+RDP_consensus_Domain,NCBI+RDP_consensus_Phylum,NCBI+RDP_consensus_Class,NCBI+RDP_consensus_Order,NCBI+RDP_consensus_Family,NCBI+RDP_consensus_Genus,NCBI+RDP_consensus_Species,BIN_sharing?,BIN_species,BIN_countries,HIT%ID_range,BOLD_link,Gattung_Art,Ordnung,Autor,Name_Deutsch,RLB,RLD,Art_ID,Synonym,Art_ID_Gueltig,FFH_Anh2,FFH_Anh4,FFH_Anh5,VSR_Anh1,Status_IUCN,Schutz_BNatSchG,Ausgabesperre,Statistiksperre,Eingabesperre,saP,rang,sensu,id_agg,prio" | perl -pe 's/,/\t/g')
REDLIST=redlist_reordered_nohead.tsv
cat <(paste -d "\t" <(echo $HEADER_P1) <(echo $SAMPLE_NAMES) <(echo $HEADER_P2) | perl -pe 's/ /\t/g') $REDLIST > redlist_reordered_raw.tsv

################### Chop off the existing redlist part from nohead step and call it results_reordered_cut.tsv
let COL_BOLD_LINK=$COL_BINSHARING+4
cut -f1-$COL_BOLD_LINK redlist_reordered_raw.tsv > redlist_reordered_cut.tsv
#
NUM_COLS_RESCUT=$(awk -F'\t' '{print NF; exit}' redlist_reordered_cut.tsv)
out_fields_results_cut=$(seq 1 1 $NUM_COLS_RESCUT | \
	perl -pe 's/(\d+)\n/1.\1,/g' | \
	perl -pe 's/\,$/\n/g')
NUM_COLS_REDL=$(awk -F'\t' '{print NF; exit}' ${REDLIST_FILE})
out_fields_red_list=$(seq 1 1 $NUM_COLS_REDL | \
	perl -pe 's/(\d+)\n/2.\1,/g' | \
	perl -pe 's/\,$/\n/g')


#join
join -a 1 -t $'\t' -1 19 -2 1 <(tail -n +2 redlist_reordered_cut.tsv | perl -pe 's/ /_/g' | sort -t $'\t' -k19,19) <(tail -n +2 ${REDLIST_FILE} | perl -pe 's/ /_/g' | sort -t $'\t' -k1,1) -o $out_fields_results_cut,$out_fields_red_list > noheader_redlist_reordered_raw.tsv
#add header
cat <(paste -d "\t" <(echo $HEADER_P1) <(echo $SAMPLE_NAMES) <(echo $HEADER_P2) | perl -pe 's/ /\t/g') noheader_redlist_reordered_raw.tsv > redlist_reordered_raw.tsv
echo "Finished."
