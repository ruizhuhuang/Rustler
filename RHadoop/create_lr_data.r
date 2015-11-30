library(rmr2)

args=commandArgs(trailingOnly=TRUE)

size=as.numeric(args[[1]])

test.size = 10^size

## create test set 
set.seed(0)
## @knitr logistic.regression-data
eps = rnorm(test.size)
testdata = 
  to.dfs(
    as.matrix(
      data.frame(
        y = 2 * (eps > 0) - 1,
        x0=1,
        x1 = 1:test.size, 
        x2 = 1:test.size + eps,
        x3 = 1:test.size + 2*eps,
        x4 = 1:test.size + 3*eps)), output=paste("/user/rhuang/input/lr/data_size_4", size,sep=""))
