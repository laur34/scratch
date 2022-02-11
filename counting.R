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
length(unique(na.omit(allBINsAbove95))) #652

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

#####
## Sample names needed as input
sample_names <- names(data1)[26:50]

uniq_cons_spec <- function(df, sample){
  #print(sample)
  pars <- as.list(match.call()[-1])
  ss <- df[as.character(pars$sample) != 0, ]
#  print(ss)
  print(ss[c(19,26)])
#  p <- as.list(match.call()[-1])
#  u <- unique(na.omit(samp$consensus_Species))
}

################## Implement Consensus Species Counts as a Function #######################
data <- as.data.frame(data1)
sample_names <- names(data)[26:50]

subset2 <- function(x, condition){
  condition_call <- substitute(condition)
  r <- eval(condition_call, x)
  x[r, ]
}

subset3 <- function(x, condition){
  condition_call <- substitute(condition)
  r <- eval(condition_call, x)
  x[, r]
}

col <- subset3(data, sample_names[1])

#ss <- subset2(data, data$`1.1.0`>0)
ss <- subset2(data, col>0)
##########################
ss$consensus_Species
#lcs <- length(unique(na.omit(ss$consensus_Species)))
con_spec <- ss$consensus_Species[!is.na(ss$consensus_Species)]
length(unique(con_spec))
print(sample_names[1])

########################## Implement BIN count above 97% as a function ######################
ss$BOLD_BIN_uri
BINs97 <- ss$BOLD_BIN_uri[ss$`BOLD_HIT%ID` >= 97]
unique(BINs97[!is.na(BINs97)])
print(length(unique(BINs97[!is.na(BINs97)]))) #81

########################## Implement BIN count above 95% as a function ######################
ss$BOLD_BIN_uri
BINs <- ss$BOLD_BIN_uri[ss$`BOLD_HIT%ID` >= 95]
length(unique(BINs[!is.na(BINs)])) #93
bg95 <- length(unique(BINs[!is.na(BINs)]))
print(bg95)

