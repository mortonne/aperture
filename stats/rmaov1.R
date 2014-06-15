#! /usr/global/R/bin/Rscript

args <- commandArgs(TRUE)

# format should be:
# data   subject   V1
data <- read.table(args[1], colClasses=c('numeric', rep('factor', 2)),
                  col.names=c('dep', 'subject', 'V1'))

res <- aov(dep ~ V1 + Error(subject / V1), data)

F <- summary(res)[[2]][[1]][1,4]
p <- summary(res)[[2]][[1]][1,5]

write.table(data.frame(F=F, p=p), args[2], quote=FALSE, na='NaN',
            row.names=FALSE, col.names=FALSE)

summary(res)
