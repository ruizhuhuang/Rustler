library(rmr2)

args = commandArgs(trailingOnly = TRUE)

# pi_rhadoop numMaps numPoints
numPoints=as.numeric(args[[1]])
numMaps=as.numeric(args[[2]])

n <- numPoints * numMaps


piFuncVec <- function(elems) {
  message(length(elems))
  rands1 <- runif(n = length(elems), min = -1, max = 1)
  rands2 <- runif(n = length(elems), min = -1, max = 1)
  val <- ifelse((rands1^2 + rands2^2) < 1, 1.0, 0.0)
  sum(val)
}

map = function(.,numPoints){
    inside=piFuncVec(numPoints)
    keyval(1, inside)
}

reduce = function(key, val){
  keyval(key,sum(val))
}

count = mapreduce(
  input=NULL,
  output=NULL,
  map=map,
  reduce=reduce
  )

cat("Pi is roughly", 4.0 * count / n, "\n")
