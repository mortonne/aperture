#! /usr/global/R/bin/Rscript

args <- commandArgs(TRUE)

# format should be:
# data   subject   V1   V2
data <- read.table(args[1], colClasses=c('numeric', rep('factor', 3)),
                  col.names=c('dep', 'subject', 'V1', 'V2'))

res <- aov(dep ~ (V1 * V2) + Error(subject / (V1 * V2)), data)

F <- rep(NA, 3)
p <- rep(NA, 3)
for (i in 1:3) {
  F[i] <- summary(res)[[i+1]][[1]][1,4]
  p[i] <- summary(res)[[i+1]][[1]][1,5]
}

write.table(data.frame(F=F, p=p), args[2], quote=FALSE, na='NaN',
            row.names=FALSE, col.names=FALSE)

summary(res)

## data <- read.table(args[1], colClasses=c('numeric', rep('factor', 2)),
##                    col.names=c('dep', 'V1', 'V2'))
## res <- aov(dep ~ V1 * V2, data)

## F <- summary(res)[[1]][-4,4]
## p <- summary(res)[[1]][-4,5]



