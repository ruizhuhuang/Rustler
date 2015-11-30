library(SparkR)

args=commandArgs(trailingOnly = TRUE)

if(length(args) != 3){
  cat("USE:sparkR-submit  --master yarn --executor-memory 1g --num-executors 10  housing.R yarn-client <input> <output> ")
  q("no")
}

sc=sparkR.init(args[[1]],"housing")
minSplits=4L
lines=textFile(sc,args[[2]],minSplits=minSplits)
elements <- lapply(lines,
                 function(line) {
                   strsplit(line, ",")[[1]]
                 })
kv=lapply(elements,function(x){list(x[1],as.numeric(x[6]))})
partitionNAOmit <- lapplyPartition(kv, function(part) {   #part is a list of list(k,v)
	dat=data.frame(t(na.omit(matrix(unlist(part), ncol=2, byrow=T))),
	    stringsAsFactors = FALSE);
	return(dat)
	}
)
t=lapply(partitionNAOmit,function(x){list(x[1],as.numeric(as.character(x[2])))})
g=groupByKey(t,minSplits)
stats=mapValues(g,function(x){c(min(unlist(x)),median(unlist(x)),max(unlist(x)))}) #x is a list of list(v)
head(collect(stats))
#ouput.path=paste('/user/',Sys.getenv('USER'),'/output/spark/housing/housing-stat-seq',sep='')
#saveAsObjectFile(stats, ouput.path)
#rdd <- objectFile(sc, ouput.path)
#head(collect(rdd))


county.string=lapply(elements,function(x){paste(x[1],x[2],x[3],sep=",")})
distint.string=distinct(county.string)
e.list <- lapply(distint.string,
                 function(line) {
                   strsplit(line, ",")[[1]]
                 })
kv.list=lapply(e.list,function(x){list(x[1],c(x[2],x[3]))})
all=join(kv.list,stats,minSplits)
head(collect(all))
#ouput.path=paste('/user/',Sys.getenv('USER'),'/output/spark/housing/housing-stat-seq',sep='')
saveAsObjectFile(all, args[[3]])

