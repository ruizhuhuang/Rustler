## http://grokbase.com/t/gg/rhadoop/131eb8rqab/490-logistic-regression-using-rmr2-package
## see spark implementation http://www.spark-project.org/examples.html
## see nice derivation here http://people.csail.mit.edu/jrennie/writing/lr.pdf

library(rmr2)

args=commandArgs(trailingOnly=TRUE)

size=as.numeric(args[[1]])
iter=as.numeric(args[[2]])
numMapper=as.numeric(args[[3]])
numReducer=as.numeric(args[[4]])



bp =
  list(
    hadoop =
      list(
        #D = paste("mapred.job.name=", args[[1]], sep=''),
        D = "mapreduce.map.memory.mb=11500",
        D = "mapreduce.reduce.memory.mb=11500",
        D = "mapreduce.map.java.opts=-Xmx9000M",
        D = "mapreduce.reduce.java.opts=-Xmx9000M",
	#D = "mapreduce.map.memory.mb=-1",
	#D = "mapreduce.reduce.memory.mb=-1",
        #D = "mapreduce.tasktracker.map.tasks.maximum=2",
        #D = "mapreduce.tasktracker.reduce.tasks.maximum=2",
	#D = "mapreduce.input.fileinputformat.split.minsize=0",
	#D = "mapreduce.jobtracker.maxtasks.perjob=-1",
	#D = "mapreduce.reduce.input.limit=-1",
        D = paste("mapred.map.tasks=",numMapper, sep=''),
        D = paste("mapred.reduce.tasks=",numReducer, sep='')
                                        ))


rmr.options(backend.parameters = bp);

rmr.options("backend.parameters")


## @knitr logistic.regression-signature
logistic.regression = 
  function(input, iterations, dims, alpha){
    
    ## @knitr logistic.regression-map
    lr.map =          
      function(., M) {
        Y = M[,1] 
        X = M[,-1]
        keyval(
          1,
          Y * X * 
            g(-Y * as.numeric(X %*% t(plane))))}
    ## @knitr logistic.regression-reduce
    lr.reduce =
      function(k, Z) 
        keyval(k, t(as.matrix(apply(Z,2,sum))))
    ## @knitr logistic.regression-main
    plane = t(c(1,rep(0, dims)))
    g = function(z) 1/(1 + exp(-z))
    for (i in 1:iterations) {
      gradient = 
        values(
          from.dfs(
            mapreduce(
              input,
              map = lr.map,     
              reduce = lr.reduce,
              combine = TRUE)))
      plane = plane + alpha * gradient }
    plane }
## @knitr end

out = list()
test.size = 10^size
for (be in c("local", "hadoop")) {
  rmr.options(backend = be)
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
          x2 = 1:test.size + eps)))
  ## @knitr end  
    ptm = proc.time()
    out[[be]] = 
    ## @knitr logistic.regression-run 
    logistic.regression(
      testdata, iter, 2, 0.05)
    time=(proc.time()-ptm)[[3]]
    res = data.frame(size, iter, numMapper, numReducer, time)
    print(res)
    write.table(res, "result_lr_rhadoop",append = TRUE, row.names = F, col.names = F)
  ## @knitr end  
  ## max likelihood solution diverges for separable dataset, (-inf, inf) such as the above
}
stopifnot(
  isTRUE(all.equal(out[['local']], out[['hadoop']], tolerance = 1E-7)))
print(out[['hadoop']])
