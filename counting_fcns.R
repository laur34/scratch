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

## Convert tibble to data frame
data <- as.data.frame(data1)
## Sample names needed as input
sample_names <- names(data)[26:50]
## Convert percentages to usable numbers
data$`BOLD_HIT%ID` <- as.numeric(gsub("[\\%,]", "", data$`BOLD_HIT%ID`))

##### Create column and row sub-setting functions that will work with variable names passed to them as arguments.
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

#### Grab the values of the sample column of interest ...hard coded number
col <- subset3(data, sample_names[1])

#### Grab the rows of the df which are nonzero for the above sample
ss <- subset2(data, col>0)
########################## Unique consensus species ####################

con_spec <- ss$consensus_Species[!is.na(ss$consensus_Species)]
length(unique(con_spec))
print(sample_names[1])

########################## BIN count above 97% ######################
BINs97 <- ss$BOLD_BIN_uri[ss$`BOLD_HIT%ID` >= 97]
unique(BINs97[!is.na(BINs97)])
print(length(unique(BINs97[!is.na(BINs97)]))) #81

########################## BIN count above 95% ######################

BINs95 <- ss$BOLD_BIN_uri[ss$`BOLD_HIT%ID` >= 95]
length(unique(BINs95[!is.na(BINs95)])) #93

###### Combine #########
df <- NULL

for(i in 1:25){
  col <- subset3(data, sample_names[i])
  ss <- subset2(data, col>0)
  #
  con_spec <- ss$consensus_Species[!is.na(ss$consensus_Species)]
  print(sample_names[i])
  x = length(unique(con_spec))
  #
  BINs97 <- ss$BOLD_BIN_uri[ss$`BOLD_HIT%ID` >= 97]
  unique(BINs97[!is.na(BINs97)])
  y = length(unique(BINs97[!is.na(BINs97)]))
  #
  BINs95 <- ss$BOLD_BIN_uri[ss$`BOLD_HIT%ID` >= 95]
  z = length(unique(BINs95[!is.na(BINs95)]))
  #
  df = rbind(df, data.frame(x,y,z))
}

df
dfnew <- t(df)
colnames(dfnew) <- sample_names
 
write.table(dfnew, file="Rolhfs_EC_2021_117_counts.tsv", sep="\t", row.names = FALSE)
