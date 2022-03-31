## Creating a tibble associating species' scientific names with countries from GBIF.
## 31.3.2022 LH

library(rgbif)
library(tibble)

# Need occurrence data
myspecies <- c("Melopsittacus undulatus")

# download GBIF occurrence data for this species; this takes time if there are many data points!
# if your species is widespread but you want to work on a particular region, you can download records within a specified window of coordinates:
gbif_data <- occ_data(scientificName = myspecies, hasCoordinate = TRUE, limit = 20000, decimalLongitude = "1, 21", decimalLatitude = "44, 56")  # note that coordinate ranges must be specified this way: "smaller, larger" (e.g. "-5, -2")

gbif_data$data #a tibble
gbif_data$data$country

# get the columns that matter for the occurrence data:
myspecies_coords <- gbif_data$data[ , c("scientificName", "decimalLongitude", "decimalLatitude", "country")]
head(myspecies_coords, n=8)

# But this returns very many records (occurrences). And we need only one per species.

gd <- occ_data(scientificName = myspecies, hasCoordinate = TRUE, limit = 2, decimalLongitude = "1, 21", decimalLatitude = "44, 56")  # note that coordinate ranges must be specified this way: "smaller, larger" (e.g. "-5, -2")

#read in species list
species <- readLines("expl_species_list.txt")
sp <- as.vector(species)

#Create a tibble (row-by-row)
#Runs into an error when a species didn't have a taxonID. Try tryCatch.
#loop through, running query for each species, adding it to the tibble.

t <- tribble(~SpeciesName, ~altSpecName, ~country)

for(s in sp){
  tryCatch({
    print(s)
    z <- occ_data(scientificName = s, hasCoordinate = TRUE, limit = 20, decimalLongitude = "1, 21", decimalLatitude = "44, 56")
    t <- add_row(t, SpeciesName=z$data$scientificName, altSpecName=z$data$species,  country=z$data$country)
  }, error=function(e){cat("ERROR: missing data",conditionMessage(e),"\n")})
}


t
df  <- cbind.data.frame(t$SpeciesName, t$altSpecName, t$country)
write.table(df, file="species_countries2.tsv", sep="\t", row.names = FALSE)

#This creates a table for which we can ignore the first column.
#Rows are in duplicates by species names. With text processing command lines, we can make the species one line each, and put multiple countries on one line, separated by pipes.
t2 <- t[,2:3]

require(dplyr)
t2summ <- t2 %>% group_by(altSpecName, country) %>% summarise()

result  <- aggregate(country ~ altSpecName, data = t2summ, paste, collapse = "|")
