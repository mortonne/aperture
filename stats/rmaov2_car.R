#!/usr/global/R/bin/Rscript

args <- commandArgs(TRUE)

# format should be:
# data   subject   V1   V2
data <- read.table(args[1], colClasses=c('numeric', rep('factor', 3)),
                   col.names=c('dep', 'subject', 'V1', 'V2'))

n <- length(levels(data$subject))
conds <- length(data$dep) / n

l1 <- levels(data$V1)
l2 <- levels(data$V2)
k <- 1
data$time = vector('numeric', length(data$dep))
for (i in 1:length(l1)) {
  for (j in 1:length(l2)) {
    data$time[data$V1 == l1[i] & data$V2 == l2[j]] = k
    k = k + 1
  }
}

# reshape to wide format
wide <- reshape(data, v.names='dep', timevar='time', idvar='subject', direction='wide', drop=c('V1','V2'))

library(car)

# make sure unordered and ordered contrasts are set to correct values
options(contrasts=c('contr.sum', 'contr.poly'))

# create a data frame with the different levels (rows should correspond
# to columns in the wide data frame)
v1 <- rep(0, conds)
v2 <- rep(0, conds)
for (i in 1:conds) {
  v1[i] <- unique(data$V1[data$time == i])
  v2[i] <- unique(data$V2[data$time == i])
}
v1 = factor(v1)
v2 = factor(v2)

w.factor <- data.frame(v1, v2)
dep.mat <- as.matrix(wide[,-1])

# create a multivariate analysis generating coefficients corresponding
# to the mean of each repeated measure and information about variances
mult.dv <- lm(dep.mat ~ 1)

# run a type-III within-subjects ANOVA
rep.aov <- Anova(mult.dv, idata=w.factor, idesign=~v1*v2, type="III")
summary(rep.aov)

if (nrow(w.factor) == 6 & length(levels(data$V1)) == 2 &
    length(levels(data$V2)) == 3) {
  # run the specific pairwise contrasts for V1=1,2
  print('Showing possibly irrelevant contrasts.')

  for (i in 1:2) {
    paste('pairwise contrasts (v1=', i, '):', sep='')
    # set up linear combinations
    # 1 vs. 2
    comp.12 <- rep(0, conds)
    comp.12[w.factor$v1 == i & w.factor$v2 == 1] <- 1
    comp.12[w.factor$v1 == i & w.factor$v2 == 2] <- -1
    
    print('1 vs. 2 coefficients:')
    print(w.factor)
    print(comp.12)
    
    # 1 vs. 3
    comp.13 <- rep(0, conds)
    comp.13[w.factor$v1 == i & w.factor$v2 == 1] <- 1
    comp.13[w.factor$v1 == i & w.factor$v2 == 3] <- -1

    # 2 vs. 3
    comp.23 <- rep(0, conds)
    comp.23[w.factor$v1 == i & w.factor$v2 == 2] <- 1
    comp.23[w.factor$v1 == i & w.factor$v2 == 3] <- -1
    
    # calculate linear combinations
    pw.comp <- cbind(comp.12, comp.13, comp.23)
    pw.scores <- data.frame(dep.mat %*% pw.comp)
    names(pw.scores) <- c('1 - 2', '1 - 3', '2 - 3')

    # corresponding t and significance (two-sided)
    obst.pw <- (sqrt(n) * mean(pw.scores)) / sd(pw.scores)
    pval.pw <- 2 * (1 - pt(abs(obst.pw), n - 1))

    # print
    m = mean(pw.scores)
    se = sd(pw.scores) / sqrt(n)
    print(round(data.frame(mean=m, SE=se, t=obst.pw,
                           df=rep(n - 1, 3), p=pval.pw), 4))
  }
}



