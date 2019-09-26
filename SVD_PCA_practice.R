# Practice doing a Principal Component Analysis with Singular Value Decomposition.
# For when we don't know any characteristics about categories of the samples
# but want to see if there's any signal in the data regarding potential groupings.
# From tutorial at http://www.sthda.com/english/articles/31-principal-component-methods-in-r-practical-guide/118-principal-component-analysis-in-r-prcomp-vs-princomp/
# 26.9.2019 LH

install.packages("factoextra")
library(factoextra)
# Using dataset decathlon2, which has names of athletes in rows, and sporting events in columns.
# (Active individuals, active variables)
library("factoextra")
data(decathlon2)
decathlon2.active <- decathlon2[1:23, 1:10]
head(decathlon.active[, 1:6])

# Compute PCA in R using prcomp()
res.pca <- prcomp(decathlon2.active, scale=TRUE)
# Visualize eigenvalues (scree plot). Show the percentage of variances explained by each principal component.
