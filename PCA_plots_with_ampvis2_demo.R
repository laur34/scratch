# Create a PCA plot of metabarcoding OTU data, either or without knowing any groupings of where samples were collected.
#install.packages("remotes")
library(remotes)
#remotes::install_github("MadsAlbertsen/ampvis2")
library(ampvis2)

setwd("/home/aim/Desktop/Laura_PCA_implementation/")

# Read in OTU table which is already formatted for ampvis2
## The OTU ID's are expected to be in either the rownames of the data frame or in a column called "OTU".
## The last 7 columns are the corresponding taxonomy assigned to the OTUs, named "Kingdom", "Phylum", "Class", "Order", "Family", "Genus", "Species".
otutbl <- read.table("otutbl2016_demo.tsv", header=T, sep="\t", stringsAsFactors = F, check.names = F)

###############################
# Analyse WITHOUT metadata.
# Use amp_load to load the data into ampvis2 format.
ampwo <- amp_load(otutable = otutbl, metadata=NULL, fasta=NULL, tree=NULL, pruneSingletons = NULL)

# Principal Component Analysis can be performed by simply setting type="pca" as shown at
amp_ordinate(data=ampwo, type="ca")

# Scree plot
result <- amp_ordinate(ampwo, type="pca", transform="hellinger", detailed_output=T)
result$screeplot


###############################
# WITH metadata
metadata2016 <- read.table("/home/aim/Desktop/Laura_PCA_implementation/md2016_demo", header=T, sep=",", stringsAsFactors = F, check.names = F)

ampwith <- amp_load(otutable = otutbl, metadata = metadata2016, fasta=NULL, tree=NULL, pruneSingletons = NULL)
# PCA
amp_ordinate(data=ampwith, type="pca", transform="hellinger", sample_color_by = "Trap", sample_colorframe = T, detailed_output=F)
# Scree plot
result <- amp_ordinate(ampwith, type="pca", transform="hellinger", detailed_output=T)
result$screeplot
