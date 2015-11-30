options(java.parameters = "-Xmx11000m")
library(Rhipe)
rhinit()

rhoptions(runner = 'R CMD /home/apps/big-data-r/Rhipe/bin/RhipeMapReduce --slave --silent --vanilla')

rhclean()

args=commandArgs(trailingOnly=TRUE)


input = args[[1]]
output = args[[2]]
numMapper=as.integer(args[[3]])
numReducer=as.integer(args[[4]])

dims=2
iterations=as.numeric(args[[5]])
alpha=0.05


g = function(z) 1/(1 + exp(-z))
plane = t(c(1,rep(0, dims)))

map1 = expression({
    seq=seq_along(map.keys)
    nrow=max(seq)
    part=lapply(map.values, function(x)strsplit(x,split = " "))
    part = as.numeric(unlist(part))
    M=matrix(part, nrow = nrow,byrow=T)
    Y = as.vector(M[,1]) 
    X = as.matrix(M[,-1])
    rhcollect(1, Y*X*g(-Y * as.numeric(X %*% t(plane))))
})

reduce1 = reducer <- expression(
  # 'reduce.key' is equivalent to this_key and set by Rhipe
  # 'reduce.values' is a list of values corresponding to this_key
  # 'pre' is executed before we process a new reduce.key
  # 'reduce' is executed for 'reduce.values'
  # 'post' is executed once all reduce.values are processed
  pre = {
    reduceoutputvalue <- matrix()
  },
  reduce = {
    reduceoutputvalue <- t(as.matrix(apply(reduce.values[[1]],2,sum)))
  },
  post = {
    rhcollect(reduce.key, reduceoutputvalue)
  }
)
mapred = list(
  mapred.max.split.size=as.integer(numMapper)
  , mapreduce.job.reduces=numReducer, #CDH3,4,
   mapreduce.map.memory.mb=11500,
#   mapreduce.reduce.memory.mb=11500,
#   mapreduce.map.java.opts="-Xmx11000m",
#   mapreduce.reduce.java.opts="-Xmx11000m",
   LD_LIBRARY_PATH=paste("/home/apps/protobuf-2.5.0/lib")
)

ptm = proc.time()
for (i in 1:iterations) {
  mr1 <- rhwatch(
    map      = map1,
    reduce   = reduce1,
    input    = rhfmt(input, type = "text"),
    output   = rhfmt(output, type = "sequence"),
    mapred=mapred,
    combiner=T,
    readback =T
  )
  gradient = mr1[[1]][[2]]
  plane = plane + alpha * gradient
  Sys.sleep(5)
}
time=(proc.time()-ptm)[[3]]
res = data.frame(numMapper,numReducer, time)
print(res)
write.table(res, "result_lr_big",append = TRUE, row.names = F, col.names = F)
print(plane)
