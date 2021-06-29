#Creating a tibble associating species' scientific names with nubKeys from GBIF
#These are the identifiers used in the URLs to species' pages on GBIF, so we can create links.
#29.6.2021 LH

library(rgbif)
out <- name_lookup(query="Apis mellifera", rank="species")
names(out)
out$meta
head(out$data)
out$facets
out$names[3]

#read in species list
setwd("/home/laur/Desktop/learn_rgbif")
#species <- read.table("expl_species_list.txt", header=F)
species <- readLines("expl_species_list.txt")
#sp <- as.vector(species$V1)
sp <- as.vector(species)
sp10 <- sp[1:10]

#create a tibble (row-by-row)
library(tibble)
#t <- tribble(~SpeciesName, ~Key, ~NCBI_ID)

#loop through, running query for each species, adding it to the tibble.

#But this ran into an error when a species didn't have a taxonID. Try tryCatch.
t <- tribble(~SpeciesName, ~Key)

for(s in sp){
  tryCatch({
    print(s)
    z <- name_lookup(query=s, rank='species')
#    t <- add_row(t, SpeciesName=z$data[1,"scientificName"], Key=z$data[1,"nubKey"])
    t <- add_row(t, SpeciesName=z$data[1,"scientificName"], Key=na.omit(unique(z$data$nubKey))[1])
    }, error=function(e){cat("ERROR: missing data",conditionMessage(e),"\n")})
}

#################################
#for(s in sp){
#  print(s)
#  z <- name_lookup(query=s, rank="species")
#  t %>% add_row(tibble_row(SpeciesName=z$data[1,"scientificName"], Key=z$data[1,"nubKey"]))
#  t <- add_row(t, SpeciesName=z$data[1,"scientificName"], Key=z$data[1,"nubKey"])
#}


class(t)
cbind.data.frame(t$SpeciesName$scientificName,t$Key)
write.table(cbind.data.frame(t$SpeciesName$scientificName,t$Key), file="species_nubkeys.csv", sep="\t", row.names = FALSE)
