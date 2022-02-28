## Count BINs for each sample, and how many of those BINs belong to specific taxa, Redlist categories, etc.
## 24.02.2022 LH@AIM

library(readxl)
setwd("/home/laur/Desktop/LFU_AUM_counting/")
data1 <- read_excel("LFU_AUM_custom_2022_results_JM3.xlsx", sheet=1, n_max=1)

library(dplyr)

cnames <- data1 %>%
  slice(1) %>%
  unlist(., use.names=FALSE)

data1 <- read_excel("LFU_AUM_custom_2022_results_JM3.xlsx", sheet=1, skip = 1, col_names = cnames)
warnings()
data1

#Delete first row because it is the headers (doesn't read in without them, due to blank cells in first row)
data1 <- data1[-1, ]

## Sample columns (25-704)
splcols <- data1[, 25:704]
splnames <- names(splcols)
data1[,25:704] <- sapply(data1[,25:704],as.numeric)

#How many unique BINs does the first sample have? (BIN_Rich)
BINsInSpl1 <- data1$BOLD_BIN_uri[which(data1$WMD00001>0)]
unique(BINsInSpl1[!is.na(BINsInSpl1)]) #177
##Do that for all samples.

##Rich_Diptera - how many unique BINs correspond to Diptera?
data1$BOLD_BIN_uri[which(data1$WMD00001>0)]
data1$adjusted_Order_BOLD[which(data1$WMD00001>0)]
data1$BOLD_BIN_uri[which(data1$WMD00001>0)]


subset3 <- function(x, condition){
  condition_call <- substitute(condition)
  r <- eval(condition_call, x)
  x[, r]
}

subset3(data1, splnames[1])
splcol <- subset3(data1, splnames[1])

subset2 <- function(x, condition){
  condition_call <- substitute(condition)
  r <- eval(condition_call, x)
  x[r, ]
}

subset2(data1, splcol>0)
ss <- subset2(data1, splcol>0)

## Combine and output as table
dat <- NULL

for(i in 1:length(splnames)){
  splcol <- subset3(data1, splnames[i])
  ss <- subset2(data1, splcol>0)
  #"Total_BIN_Richness"
  ord_ss <- ss[,c("BOLD_BIN_uri","adjusted_Order_BOLD")]
  ord_ss <- ord_ss[which(!is.na(ord_ss$adjusted_Order_BOLD)), ]
  BINsHas <- ord_ss$BOLD_BIN_uri
  BIN_rich_total = length(unique(na.omit(BINsHas)))
  print(unique(BINsHas))
  # Diptera BIN counts
  #ord_ss <- ss[,c("BOLD_BIN_uri","adjusted_Order_BOLD")]
  ord_ss_d <- ord_ss[ord_ss$adjusted_Order_BOLD=="Diptera", ]
  rich_Diptera <- length(unique(na.omit(ord_ss_d$BOLD_BIN_uri)))
  # Hymenoptera BIN countsor
  ord_ss_hy <- ord_ss[ord_ss$adjusted_Order_BOLD=="Hymenoptera", ]
  rich_Hymenoptera <- length(unique(na.omit(ord_ss_hy$BOLD_BIN_uri)))
  # Hemiptera BIN counts
  ord_ss_he <- ord_ss[ord_ss$adjusted_Order_BOLD=="Hemiptera", ]
  rich_Hemiptera <- length(unique(na.omit(ord_ss_he$BOLD_BIN_uri)))
  # Coleoptera BIN counts
  ord_ss_c <- ord_ss[ord_ss$adjusted_Order_BOLD=="Coleoptera", ]
  rich_Coleoptera <- length(unique(na.omit(ord_ss_c$BOLD_BIN_uri)))
  # Lepidoptera BIN counts
  ord_ss_l <- ord_ss[ord_ss$adjusted_Order_BOLD=="Lepidoptera", ]
  rich_Lepidoptera  <- length(unique(na.omit(ord_ss_l$BOLD_BIN_uri)))
  # Orthoptera BIN counts
  ord_ss_o <- ord_ss[ord_ss$adjusted_Order_BOLD=="Orthoptera", ]
  rich_Orthoptera <- length(unique(na.omit(ord_ss_o$BOLD_BIN_uri)))
  # Rich rest - BIN counts not belonging to above orders
  ord_ss_r <- ord_ss[ord_ss$adjusted_Order_BOLD!="Diptera" & ord_ss$adjusted_Order_BOLD!="Lepidoptera" & ord_ss$adjusted_Order_BOLD!="Hymenoptera" & ord_ss$adjusted_Order_BOLD!="Hemiptera" & ord_ss$adjusted_Order_BOLD!="Coleoptera" & ord_ss$adjusted_Order_BOLD!="Orthoptera", ]
  print(ord_ss_r$BOLD_BIN_uri)
  rich_rest <- length(unique(na.omit(ord_ss_r$BOLD_BIN_uri)))
  # BIN Red listed - BIN counts in which there is an entry in first column of Red list data
  red_ss <- ss[, c("BOLD_BIN_uri", "Gattung_Art")]
  red_ss_listed <- red_ss[!is.na(red_ss$Gattung_Art), ]
  BIN_red_listed <- length(unique(na.omit(red_ss_listed$BOLD_BIN_uri)))
  # Consensus rich total -- total unique consensus_species
  cons_ss <- ss[,c("consensus_Species","consensus_Order")]
  cons_ss <- cons_ss[which(!is.na(cons_ss$consensus_Order)), ]
  conspec_has <- cons_ss$consensus_Species
  con_rich_total <- length(unique(na.omit(conspec_has)))
  # Consensus Diptera richness
  cons_ss_d <- cons_ss[cons_ss$consensus_Order=="Diptera", ]
  con_rich_Diptera <- length(unique(na.omit(cons_ss_d$consensus_Species)))
  # Hymenoptera cons counts
  cons_ss_hy <- cons_ss[cons_ss$consensus_Order=="Hymenoptera", ]
  con_rich_Hymenoptera <- length(unique(na.omit(cons_ss_hy$consensus_Species)))
  # Hemiptera cons counts
  cons_ss_he <- cons_ss[cons_ss$consensus_Order=="Hemiptera", ]
  con_rich_Hemiptera <- length(unique(na.omit(cons_ss_he$consensus_Species)))
  # Coleoptera cons counts
  cons_ss_c <- cons_ss[cons_ss$consensus_Order=="Coleoptera", ]
  con_rich_Coleoptera <- length(unique(na.omit(cons_ss_c$consensus_Species)))
  # Lepidoptera cons counts
  cons_ss_l <- cons_ss[cons_ss$consensus_Order=="Lepidoptera", ]
  con_rich_Lepidoptera <- length(unique(na.omit(cons_ss_l$consensus_Species)))
  # Orthoptera cons counts
  cons_ss_o <- cons_ss[cons_ss$consensus_Order=="Orthoptera", ]
  con_rich_Orthoptera <- length(unique(na.omit(cons_ss_o$consensus_Species)))
  # Rich rest - cons counts not belonging to above orders
  cons_ss_r <- cons_ss[cons_ss$consensus_Order!="Diptera" & cons_ss$consensus_Order!="Lepidoptera" & cons_ss$consensus_Order!="Hymenoptera" & cons_ss$consensus_Order!="Hemiptera" & cons_ss$consensus_Order!="Coleoptera" & cons_ss$consensus_Order!="Orthoptera", ]
  con_rich_rest <- length(unique(na.omit(cons_ss_r$consensus_Species)))
  # cons Red listed - cons counts in which there is an entry in first column of Red list data
  redc_ss <- ss[, c("consensus_Species", "Gattung_Art")]
  redc_ss_listed <- redc_ss[!is.na(redc_ss$Gattung_Art), ]
  con_rich_redlist <- length(unique(na.omit(redc_ss_listed$consensus_Species)))
  #
  dat = rbind(dat, data.frame(BIN_rich_total,rich_Diptera,rich_Hymenoptera,rich_Hemiptera,rich_Coleoptera,rich_Lepidoptera,rich_Orthoptera,rich_rest,BIN_red_listed,con_rich_total,con_rich_Diptera,con_rich_Hymenoptera,con_rich_Hemiptera,con_rich_Coleoptera,con_rich_Lepidoptera,con_rich_Orthoptera,con_rich_rest,con_rich_redlist))
}

dat
row.names(dat) <- splnames




write.table(dat, file="summary_samples_LFU_AUM_custom_2022.tsv", sep = "\t", col.names = NA)

#Whenever I subset like this with string comparisons, it gets rid of th "NA" Order rows.
#See the difference:
ord_ss$adjusted_Order_BOLD
#vs
ord_ss$adjusted_Order_BOLD[which(ord_ss$adjusted_Order_BOLD != "Diptera")]
#So, just get rid of the NA's in the first place, since I can't figure out how to include them in the subsets.
