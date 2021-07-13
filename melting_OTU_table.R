#Create a long-form data table from our OTU table.
#17.5.2021 LH

setwd("/home/laur/Downloads/")
setwd("/media/laur/Extreme_SSD/Esser_NGSeco03052019_combined")
setwd("/home/laur/Desktop/FT_Esser_NGSeco03052019/")

data <- read.table(file="kubiaktest_forDT.csv", header=T, stringsAsFactors = F)
data <- read.table(file="cleaned_OTU_table.tsv", header=T, stringsAsFactors = F)
data <- read.table(file="otu_table_nc_cleaned_from_xl.txt", header=T, stringsAsFactors = F)
#head(data)
#setDT(data)
#head(data)
#DT.ml <- melt(data, id.vars = "OTU_ID", measure.vars = c("NGSeco21062019_B_005", "NGSeco21062019_B_006",  "NGSeco21062019_B_007", "NGSeco21062019_B_008", "NGSeco21062019_B_009", "NGSeco21062019_B_010"))

#write.csv(DT.ml, file="kubiaktest_melt.csv")

library(tidyr)
DT.g <- gather(data, variable, value, -OTU_ID)

library(dplyr)
data_long <- DT.g %>% arrange(variable, -(value))
write.table(data_long, file="cleaned_OTU_tbl_FT_Esser_gathered.tsv", sep="\t", row.names = T, col.names = NA)
write.table(data_long, file="cleaned_OTU_tbl_FT_Esser_gatheredn.tsv", sep="\t", row.names =F, col.names = c("OTU_ID", "sample", "nr_seqs"))
