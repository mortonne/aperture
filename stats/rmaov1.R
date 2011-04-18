#!/usr/global/R/bin/Rscript

args <- commandArgs(TRUE)

# format should be:
# data   subject   V1
data <- read.table(args[1], colClasses=c('numeric', rep('factor', 2)),
                   col.names=c('dep', 'subject', 'V1'))

wide <- reshape(data, v.names='dep', idvar='subject', timevar='V1',
                direction='wide')

# reorder columns to have dep in ascending order
ind <- c(1, order(names(wide)[-1]) + 1)
wide <- wide[,ind]

# use the car library
# to install:
# install.packages('car')
#  or
# install.packages('car', 'path_to_local_library')
library(car)

# make sure unordered and ordered contrasts are set to correct values
options(contrasts=c('contr.sum', 'contr.poly'))

# create a multivariate analysis generating coefficients
# corresponding to the mean of each repeated measure and
# information about variances
mult.dv <- lm(as.matrix(wide[,-1]) ~ 1)

# create a repeated measures factor with levels = names of the
# time points
rm.factor <- names(wide)[-1]

# invoke repeated measures anova
# idesign creates a transformation matrix allowing for tests
# of main effect of time
mc.aov <- Anova(mult.dv, idata=data.frame(rm.factor),
                idesign=~rm.factor, type='III')
summary(mc.aov)

if (length(rm.factor) == 3) {
  # calculate linear combinations
  pw.comp <- cbind(c(1,-1,0), c(1,0,-1), c(0,1,-1))
  pw.scores <- data.frame(as.matrix(wide[,-1]) %*% pw.comp)
  names(pw.scores) <- c('1vs2', '1vs3', '2vs3')
  n <- length(pw.scores[,1])

  # corresponding t and significance (two-sided)
  obst.pw <- (sqrt(n) * mean(pw.scores)) / sd(pw.scores)
  pval.pw <- 2 * (1 - pt(abs(obst.pw), n - 1))

  # print
  m = mean(pw.scores)
  se = sd(pw.scores) / sqrt(n)
  round(data.frame(mean=m, SE=se, t=obst.pw, df=rep(n - 1, 3), p=pval.pw), 4)
}

