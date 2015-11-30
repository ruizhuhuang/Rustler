#Note: Y is -1 and 1 from the input
library(SparkR)

args <- commandArgs(trailing = TRUE)

if (length(args) != 4) {
  print("Usage: logistic_regression <master> <file> <iters> <dimension>")
  q("no")
}

master="yarn-client"
file=args[[1]]
iters = as.integer(args[[2]])
dim = as.integer(args[[3]])
minSplits = as.integer(args[[4]])
alpha = 0.05


ptm=proc.time()

# Initialize Spark context
sc <- sparkR.init(master, "LogisticRegressionR")
iterations <- as.integer(iters)

readPartition <- function(part){
  #part = as.vector(part, mode = "character") # list to character vector
  #part = strsplit(part, " ", fixed = T)
  part = lapply(part, function(line)strsplit(line," ", fixed=T)[[1]])
  list(matrix(as.numeric(unlist(part)), ncol = length(part[[1]]),byrow=T)) # return a list with one matrix 
}

# Read data points and convert each partition to a matrix
points <- cache(lapplyPartition(textFile(sc, file,minSplits=minSplits), readPartition)) #minSplits=minSplits


plane = t(c(1,rep(0, dim)))
g = function(z) 1/(1 + exp(-z))

# Compute logistic regression gradient for a matrix of data points
gradient <- function(partition) {
  partition = partition[[1]]
  Y <- partition[, 1]  # point labels (first column of input file)
  X <- partition[, -1] # point coordinates

  # For each point (x, y), compute gradient function
  Z=Y * X * g(-Y * as.numeric(X %*% t(plane)))
  grad = apply(Z,2,sum)
  #grad = as.vector(t(X) %*% (g(-Y * as.numeric(X %*% t(plane)))*Y)) # equivalent to two lines above
  list(grad)
}

for (i in 1:iterations) {
  cat("On iteration ", i, "\n")
  plane <- plane + alpha*reduce(lapplyPartition(points, gradient), "+")
}

cat("Final plane: ", plane, "\n")
time=(proc.time()-ptm)[[3]]

res = data.frame(minSplits, time)
print(res)
write.table(res, "result_lr_600g_800g",append = TRUE, row.names = F, col.names = F)

