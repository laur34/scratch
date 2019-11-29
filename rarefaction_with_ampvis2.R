# Create a rarefaction curve (number of reads vs number of OTUs) for each sample.
# Tutorial at https://madsalbertsen.github.io/ampvis2/reference/amp_rarecurve.html
# 27.11.2019 LH

library(ampvis2)
# load example data
data("AalborgWWTPs")

# Rarecurve
amp_rarecurve(AalborgWWTPs, facet_by = "Plant")

################################################
# load our data
setwd("/home/aim/rarefaction_curves_r/")
d <- read.csv("pretend_otutbl_w_classifications.tsv", header=T, sep="\t")

# load metadata and object
mymetadata <- read.csv("pretend_metadata.tsv", header=T, sep="\t", colClasses=c("character", "character"))

al <- amp_load(otutable = d, metadata = mymetadata)

# Rarecurve
amp_rarecurve(al, facet_by = NULL, color_by = "temperature")

# without metadata
al <- amp_load(d, metadata=NULL, fasta=NULL)
# Rarecurve
amp_rarecurve(al)


################ With a realistic resluts table ####################
## Read in list of results. First, open the xlsx file and remove the top row. Then, save as csv/tsv.
results <- read.csv("Schwarzstorch_20190927NGSeco_results_plus_more_samples.csv", header=T, sep=",", stringsAsFactors=F)

## Locate the sample columns (btwn sum reads per otu, and BIN.sharing), as a subset of df
colvars <- names(results)
start_loc <- match("sum_reads_per_OTU", colvars)
end_loc <- match("BIN.sharing.", colvars)
samples <- results[, (start_loc+1):(end_loc-1)]
#samples <- samples[,1:ncol(samples)-1]

## Split it up into groups of 10 samples each, with any remainder in last table.
s <- split.default(samples, ceiling(seq_along(samples)/10))
#c(rep(ncol(samples) %/% 10,10) , ncol(samples) %% 10)
#s <- split.default(samples, rep(1:(ncol(samples)/10), 10))

## And for each of these subtables, concatenate columns OTU, and NCBI taxa 4- 10.
head(results$OTU.cluster_size) #fix this--it's smashed into "size=..." from Geneious.
library(stringr)
ssf <- str_split_fixed(results$OTU.cluster_size, ";", 2)
head(ssf[,1])

colvars <- names(results)
start_loc <- match("NCBI_taxon_04", colvars)
end_loc <- match("NCBI_taxon_10", colvars)
taxa <- results[, start_loc:end_loc]

########### NOTE: This part is not automated. Hard-coding the numbers for right now, for number of subtables (length of s).
otu_table1 <- cbind.data.frame(as.data.frame(ssf[,1]), as.data.frame(s[1]), taxa)
