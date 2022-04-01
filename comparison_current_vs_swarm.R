# Comparison of BIN qualities and quantities in results from our current method and SWARM

#Read in old and new results
########## Old results:
#install.packages("readxl")
library(readxl)
setwd("/home/laur/Desktop/NGS_RUN_15_03_2022_run06/multiplex/")
data1 <- read_excel("multiplex_results.xlsx", n_max=1)

#install.packages("dplyr")
library(plyr)
library(dplyr)

cnames <- data1 %>%
  slice(1) %>%
  unlist(., use.names=FALSE)

data1 <- read_excel("multiplex_results.xlsx", skip = 1, col_names = cnames)
warnings()
data1
data1 <- data1[-1, ]
BINs1 <- data1[ ,2]

########## New results (SWARM) :
setwd("/home/laur/Desktop/NGS_RUN_15_03_2022_run06/multiplex/test_swarm/")
data2 <- read_excel("test_swarm_results.xlsx", skip = 2, col_names = cnames)
warnings()
data2
BINs2 <- data2[ ,2]

BINs1vec <- pull(BINs1, BOLD_BIN_uri)
BINs2vec <- pull(BINs2, BOLD_BIN_uri)

#install.packages("stringi")
library(stringi)
B1 <- stri_omit_na(BINs1vec)
class(B1)
B2 <- stri_omit_na(BINs2vec)
length(B1)
length(B2)
length(unique(B1)) #old way - unique BIN count
length(unique(B2)) #new way - unique BIN count

############## Plot - bar plot of BINs and unique BINs ####################
ttl_BINs <- c(length(B1), length(B2))

current_way <- c(length(B1), length(unique(B1)))
swarm_way <- c(length(B2), length(unique(B2)) )
df <- cbind(current_way, swarm_way)
barplot(as.matrix(df), beside = TRUE)
legend("topright", legend = c("total", "unique"), col=c("black", "grey"), pch = 16)
title(main = "BINs")

#Ratio of total BINs to unique BINs
length(unique(B1))/length(B1) #72.7% unique
length(unique(B2))/length(B2) #73.6% unique


#### OTU counts ####
otus_old <- data1$`OTU_ID;cluster_size`
otus_new <- data2$`OTU_ID;cluster_size`
ttl_otus <- c(length(otus_old), length(otus_new))

current_way <- c(length(otus_old), length(B1), length(unique(B1)))
swarm_way <- c(length(otus_new), length(B2), length(unique(B2)))

df <- cbind(current_way, swarm_way)
barplot(as.matrix(df), beside=T)
title(main = "OTU, BIN, and unique BIN counts")
#


#### Numbers for after pre-clustering, after chimera removal, after clustering, after wrapper, after nc filtering
current_pipeline <- c(2233,1973,1901,1654,1591)
swarm_pipeline <- c(2233,1973,1831,1591,1529)

dfv <- cbind(current_pipeline, swarm_pipeline)
barplot(as.matrix(dfv), beside = T)
legend("topright", legend = c("pre-clustered", "non-chimeric", "clusters/swarms", "after wrapper", "after NC filter"), col = gray.colors(5), pch = 16)
title(main = "Sequences")

#### Number of OTUs with less than 10 BINs
#old
length(data1$`OTU_ID;cluster_size`) #Number of OTUs: 1591

data1$Nr_seqs <- sub("OTU_[[:digit:]]+;size=", "" ,data1$`OTU_ID;cluster_size`) #isolate the sizes (nr. seqs)
data1$Nr_seqs <- as.numeric(data1$Nr_seqs)

length(data1$Nr_seqs[which(data1$Nr_seqs < 10)]) #1052 OTUs with less than 10 sequences
length(data1$Nr_seqs[which(data1$Nr_seqs < 10)]) / length(data1$`OTU_ID;cluster_size`) #66% of OTUs have less than 10 seqs

#new
length(data2$`OTU_ID;cluster_size`) #Number of OTUs: 1528
#this one came from swarm and has trailing semicolons--strip them
data2$`OTU_ID;cluster_size` <- sub(";$", "", data2$`OTU_ID;cluster_size`)

data2$Nr_seqs <- sub("OTU_[[:digit:]]+;size=", "" ,data2$`OTU_ID;cluster_size`) #isolate the sizes (nr. seqs)
data2$Nr_seqs <- as.numeric(data2$Nr_seqs)

length(data2$Nr_seqs[which(data2$Nr_seqs < 10)]) #1007 OTUs with less than 10 sequences
length(data2$Nr_seqs[which(data2$Nr_seqs < 10)]) / length(data2$`OTU_ID;cluster_size`) #65.9% of OTUs have less than 10 seqs

#Plot
## ggplot2 histograms
library(ggplot2)
df <- data.frame(method = factor( c(rep("current", nrow(data1)), rep("swarm", nrow(data2)))),
                 num_seqs_in_clstr = c(data1$Nr_seqs, data2$Nr_seqs)  )

## Interleaved histogram
### Calculate the mean of each group:

mu <- ddply(df, "method", summarise, grp.mean=mean(num_seqs_in_clstr))
head(mu)

ggplot(df, aes(x=num_seqs_in_clstr, color=method)) +
  geom_histogram(fill="white", alpha=0.3, position = "dodge", binwidth = 20) +
  geom_vline(data = mu, aes(xintercept=grp.mean, color=method),linetype="dashed") +
  ggtitle("Cluster size frequencies")
## Log-transformed
ggplot(df, aes(x=num_seqs_in_clstr, color=method)) +
  geom_histogram(alpha=0.1, position = "dodge") +
  geom_vline(data = mu, aes(xintercept=grp.mean, color=method),linetype="dashed") +
  scale_x_log10() +
  ggtitle("Cluster size frequencies")


## Violin plot
v <- ggplot(df, aes(x=method, y=num_seqs_in_clstr)) +
  geom_violin(trim = FALSE)

v
############## Venn diagram of BINs in each method ########################
BINs <- unique(union(B1, B2))
length(BINs)
length(intersect(B1,B2))
#For some reason my Venneuler one does not look proportional
#install.packages("rJava")
#library(rJava)

#install.packages("eulerr")
#library(eulerr)

#ve <- euler(c("current"=length(unique(B1)), "swarm"=length(unique(B2)),  "current&swarm"=length(intersect(unique(B1),unique(B2)))) )
#ve$labels <- c(
#  paste("current\n", length(unique(B1))+length(intersect(unique(B1),unique(B2)))),
#  paste("swarm\n", length(unique(B2))+length(intersect(unique(B1),unique(B2)))) 
#)
#plot(ve)

#install.packages("VennDiagram")
library(VennDiagram)
grid.newpage()
draw.pairwise.venn(area1 = length(unique(B1)),
                   area2 = length(unique(B2)),
                   cross.area = length(intersect(unique(B1),unique(B2))),
                   category = c("current BINs", "swarm BINs"),fill = c("red","blue"))

