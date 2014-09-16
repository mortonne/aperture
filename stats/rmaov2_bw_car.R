#!/usr/global/R/bin/Rscript

args <- commandArgs(TRUE)

# format should be:
# data   subject   V1 (between)   V2 (within)
data <- read.table(args[1], colClasses=c('numeric', rep('factor', 3)),
                   col.names=c('dep', 'subject', 'V1', 'V2'))

# reshape to wide format
wide <- reshape(data, v.names='dep', timevar='V2', idvar='subject', direction='wide')

library(car)

# make sure unordered and ordered contrasts are set to correct values
options(contrasts=c('contr.sum', 'contr.poly'))

# w.factor <- levels(data$V2)
V2 <- levels(data$V2)
dep.mat <- as.matrix(wide[,-1:-2])

# create a multivariate analysis generating coefficients corresponding
# to the mean of each repeated measure and information about variances
V1 <- wide$V1
mult.dv <- lm(dep.mat ~ V1)

# run a type-III within-subjects ANOVA
rep.aov <- Anova(mult.dv, idata=data.frame(V2), idesign=~V2, type="III")
summary(rep.aov)
