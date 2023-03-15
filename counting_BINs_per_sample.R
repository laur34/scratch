## Count consensus species detected for each sample, and also numbers of BINs with matches >= 97% and 95% Grade.
## 15.03.2023 LH

library(readxl)
setwd("/home/laur/Desktop/Schachtl_LFU_Teilprojekts_A_B_C_FT/Teilprojekt_C_FT")
datan <- read_excel("Teilprojekt C - LFU Schachtl_FT.xlsx", sheet=1, n_max=1, skip=1)
data2 <- read_excel("Teilprojekt C - LFU Schachtl_FT.xlsx", sheet=1, skip=2)

last_spl_col <- 67
splnames <- names(datan)[26:last_spl_col]

library(dplyr)

## Sample columns
splcols <- data2[, 26:last_spl_col]
names(data2)[26:last_spl_col] <- names(datan[26:last_spl_col])
#splnames <- names(splcols)
data2[,26:last_spl_col] <- sapply(data2[,26:last_spl_col],as.numeric)

## Convert columns with percent signs to numeric
data2$`BOLD_Grade%ID` <- as.numeric(sub("%", "", data2$`BOLD_Grade%ID`))/100

#How many unique BINs does the first sample have? (BIN_Rich)
BINsInSpl1 <- data2$BOLD_BIN_uri[which(data2$by007mf_2022_01>0)]
unique(BINsInSpl1[!is.na(BINsInSpl1)]) #354
##Do that for all samples.

######## define and test functions on dataset ################
subset3 <- function(x, condition){
  condition_call <- substitute(condition)
  r <- eval(condition_call, x)
  x[, r]
}

subset3(data2, splnames[1])
splcol <- subset3(data2, splnames[1])

subset2 <- function(x, condition){
  condition_call <- substitute(condition)
  r <- eval(condition_call, x)
  x[r, ]
}

subset2(data2, splcol>0)
ss <- subset2(data2, splcol>0)

###################################################################

## Combine and output as table
dat <- NULL

for(i in 1:length(splnames)){
  splcol <- subset3(data2, splnames[i])
  ss <- subset2(data2, splcol>0)
  #Total BINs - 95% +
  BIN_grad_ss <- ss[,c("BOLD_BIN_uri", "BOLD_Grade%ID")]
  BIN_grad_ss95 <- BIN_grad_ss[which(BIN_grad_ss$`BOLD_Grade%ID` >= 0.95), ]
  BINs95 <- BIN_grad_ss95$BOLD_BIN_uri
  BINs95_ct = length(unique(na.omit(BINs95)))
  print(unique(BINs95))
  # Total unique consensus_species
  cons_ss <- ss[,"consensus_Species"]
  ttl_cons_spp = length(unique(na.omit(cons_ss$consensus_Species)))
  # Total BINs - 97% +
  BIN_grad_ss <- ss[,c("BOLD_BIN_uri", "BOLD_Grade%ID")]
  BIN_grad_ss97 <- BIN_grad_ss[which(BIN_grad_ss$`BOLD_Grade%ID` >= 0.97), ]
  BINs97 <- BIN_grad_ss97$BOLD_BIN_uri
  BINs97_ct = length(unique(na.omit(BINs97)))
  print(unique(BINs97))
  #
  dat = rbind(dat, data.frame(ttl_cons_spp, BINs97_ct, BINs95_ct))
}


dat
row.names(dat) <- splnames
Teil <- "C"

file_name <- paste0("summary_samples_Teilprojekt ", Teil, " - LFU Schachtl_FT.tsv")

write.table(dat, file=file_name, sep = "\t", col.names = NA)

