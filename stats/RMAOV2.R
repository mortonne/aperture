#! /usr/global/R/bin/Rscript

args <- commandArgs(TRUE)

# format should be:
# data   subject   V1   V2
data <- read.table(args[1], colClasses=c('numeric', rep('factor', 3)),
                   col.names=c('dep', 'subject', 'V1', 'V2'))

res <- aov(dep ~ (V1 * V2) + Error(subject / (V1 * V2)), data)
summary(res)

