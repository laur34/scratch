#2020 samples
rename 's/run2020-20-(.*)(-E(\d+))/run2020-20$2-$1/' *.fastq

rename 's/run2020-23-(.*)(-E(\d+))/run2020-23$2-$1/' *.fastq

#Do the splsht csv file
perl -p -i.bak -e 's/run2020_20_(.*)(_E(\d+))/run2020_20$2_$1/' samplesheet_FT_Esser_renamed.csv
perl -p -i.bak -e 's/run2020_23_(.*)(_E(\d+))/run2020_23$2_$1/' samplesheet_FT_Esser_renamed.csv

#2021 samples
rename 's/run2021-11-(.*)(-E(\d+))/run2021-11$2-$1/' *.fastq

#Do the splsht csv file
perl -p -i.bak -e 's/run2021_11_(.*)(_E(\d+))/run2021_11$2_$1/' samplesheet_FT_Esser_run13r.csv

