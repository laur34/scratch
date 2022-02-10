## Create numbers for 1) unique consensus species 2) unique BINs >= 97% 3) unique BINs >= 95%
## 10.02.2022 LH@AIM

library(readxl)
setwd("/home/laur/Desktop/Rohlfs_EC_2021_117/EC_2021_117/")
data1 <- read_excel("Rohlfs_EC-2021-117_results_LH.xlsx", n_max=3)

library(dplyr)

cnames <- data1 %>%
  slice(2) %>%
  unlist(., use.names=FALSE)

data1 <- read_excel("Rohlfs_EC-2021-117_results_LH.xlsx", skip = 2, col_names = cnames)
warnings()
data1

#It worked, except that the header is duplicated in the first row. For now, I'll remove the first row.
data1 <- data1[-1, ]

## 1
length(data1$consensus_Species) #1542
length(unique(na.omit(data1$consensus_Species))) #305

## 2
data1$BOLD_BIN_uri
data1$`BOLD_HIT%ID` <- as.numeric(gsub("[\\%,]", "", data1$`BOLD_HIT%ID`))

allBINsAbove97 <- data1$BOLD_BIN_uri[which(data1$`BOLD_HIT%ID` >= 97)]
length(unique(na.omit(allBINsAbove97))) #614

## 3
allBINsAbove95 <- data1$BOLD_BIN_uri[which(data1$`BOLD_HIT%ID` >= 95)]
length(unique(na.omit(allBINsAbove95)))

###### Sample-by-sample ########
##cols 26-50

## Unique consensus species
sample1 <- subset(data1, data1$`1.1.0`>0)
unique(na.omit(sample1$consensus_Species))
length(unique(na.omit(sample1$consensus_Species))) #42

## Unique BINs above 97%
#sample1 <- subset(data1, data1$`1.1.0`>0)
sample1$BOLD_BIN_uri[sample1$`BOLD_HIT%ID` >= 97]
BINsInSpl <- unique(na.omit(sample1$BOLD_BIN_uri[sample1$`BOLD_HIT%ID` >= 97]))
length(BINsInSpl) #81

## Unique BINs above 95%
#sample1 <- subset(data1, data1$`1.1.0`>0)
sample1$BOLD_BIN_uri[sample1$`BOLD_HIT%ID` >= 95]
BINsInSpl <- unique(na.omit(sample1$BOLD_BIN_uri[sample1$`BOLD_HIT%ID` >= 95]))
length(BINsInSpl) #93
