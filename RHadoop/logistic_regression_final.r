library(rmr2)

args=commandArgs(trailingOnly=TRUE)

input = args[[1]]
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
        D = "mapreduce.tasktracker.map.tasks.maximum=1",
        D = "mapreduce.tasktracker.reduce.tasks.maximum=1",
        #D = "mapreduce.input.fileinputformat.split.minsize=0",
        #D = "mapreduce.jobtracker.maxtasks.perjob=-1",
        #D = "mapreduce.reduce.input.limit=-1",
        D = paste("mapreduce.job.maps=", numMapper, sep=''),
        D = paste("mapreduce.job.reduces=", numReducer, sep='')
        #D = paste("mapred.map.tasks=",numMapper, sep=''),
        #D = paste("mapred.reduce.tasks=",numReducer, sep='')
      ))


rmr.options(backend.parameters = bp);

rmr.options("backend.parameters")


## @knitr logistic.regression-signature
logistic.regression = 
  function(input, iterations, dims, alpha){
    
    ## @knitr logistic.regression-map
    lr.map =          
      function(., lines) {
        nrow=length(lines)
        part=lapply(lines, function(x)strsplit(x,split = " "))
        part = as.numeric(unlist(part))
        M=matrix(part, nrow = nrow,byrow=T)
        Y =as.integer( M[,1]) 
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
              input=input,
	      input.format = "text",
              map = lr.map,     
              reduce = lr.reduce,
              combine = TRUE)))
      plane = plane + alpha * gradient }
    plane }
## @knitr end

out = matrix()

  ## @knitr end  
  ptm = proc.time()
  out = 
    ## @knitr logistic.regression-run 
    logistic.regression(
      input, iter, 2, 0.05)
  time=(proc.time()-ptm)[[3]]
  res = data.frame( numMapper, numReducer, time)
  print(res)
  write.table(res, "result_lr_big",append = TRUE, row.names = F, col.names = F)
  ## @knitr end  
  ## max likelihood solution diverges for separable dataset, (-inf, inf) such as the above
  print(out)

