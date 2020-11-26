#!/bin/bash

# A script to prepare sequence files for the vsearch pipeline, when fastq files do not have the correct names.
# Given fastq files zipped into their own folders, and the folders have names we want (with additional hex strings),
# changes the fastq files to have the corresponding desired names--but without underscores in the core names.

# 2.12.2019 LH@AIM, VB@AIM, last change 26.11.2020 LH

confirm(){
        # call this function with a prompt string or use the default value
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

# check if subfolders are present
subdircount=`find . -maxdepth 1 -type d | wc -l`

if [ $subdircount -eq 2 ]
then
    echo "Warning: no subfolders found in current folder."
    echo "Have you forgotten to copy over the sequence files?"
    echo
    exit 1
fi


#Create a file where the names of the fastq folders are next to the names of the fastq files.
ls */* |  cut -d"/" -f1,2 --output-delimiter=' ' > mapping_names_to_nums.txt

#cp ~/Desktop/pipeline_utils/prepare_files.sh .
#bash prepare_files.sh
echo "Moving ..."
echo
find . -mindepth 2 -type f -print -exec mv {} . \;
sleep 2

# delete the now empty subfolders
echo
echo "Performing maintenance ..."
echo
find . -type d -empty -delete
sleep 2

# unzip all sequence files
echo "Unzipping ..."
echo
gunzip *
echo
echo "Done."
echo
sleep 2

# Sort to make the order correspond to the alphabetically sorted order produced by ls:
sort -k2,2 mapping_names_to_nums.txt > mapping_names_to_nums_sorted.txt

# Create a file of the desired new names for the fastq files:
## replace underscores with hyphens in the folder names:
cut -d" " -f1 mapping_names_to_nums_sorted.txt

cut -d" " -f1 mapping_names_to_nums_sorted.txt | sed 's/-ds.*$//' | sed 's/_/-/g' > newnamesfirsthalves.txt
cut -d" " -f2 mapping_names_to_nums_sorted.txt | sed 's/^[0-9]\+//' > newnamessecondhalves.txt
paste -d" " newnamesfirsthalves.txt newnamessecondhalves.txt > newnames.txt
#oops I did something wrong. Too many L001's.
sed -i 's/ //' newnames.txt
sed -i 's/-L001//' newnames.txt 
# and forgot to remove .gz on the ends
sed -i 's/.gz$//' newnames.txt

# create name mapping file and rename:
for file in ./*.fastq; do echo "${file##*/}"; done > oldnames.txt
paste oldnames.txt newnames.txt > old_to_new_names.tsv
xargs -a old_to_new_names.tsv -n 2 mv

# clean up
echo "Deleting intermediate files ..."
rm mapping*.txt
rm new*.txt
rm old*.txt
rm old*.tsv
echo "Finished."
