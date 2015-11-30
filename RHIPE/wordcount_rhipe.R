#!/usr/bin/env Rscript
library(Rhipe)
rhinit()
rhoptions(runner = 'R CMD /home/apps/big-data-r/Rhipe/bin/RhipeMapReduce --slave --silent --vanilla')

#input.file.local <- 'sample.txt'
input.user.dir <- paste('/user/',Sys.getenv('USER'),sep='')

args=commandArgs(trailingOnly = TRUE)

rhclean()

time0=proc.time()

if(length(args) < 2){
  input.file.name<- 'book100.txt'
 # input.file.name <- 'enwiki-latest-pages-meta-current1.xml'
  input.testnum<-1
  num_reducers<-0
  num_mappers<-10
  combiner<-T
}else{
  input.testnum <- args[[1]] 
  input.file.name <- args[[2]]
  num_reducers<- args[[4]]
  num_mappers<- as.integer(args[[3]])
  if(args[[5]]=="true"){
	combiner<-T
  }else{
	combiner<-F
  }
}

input.file.hdfs <- paste(input.user.dir,'/data/',input.file.name,sep='')
output.dir.hdfs <- paste(input.user.dir,'/out/rhipe_',format(Sys.time(), "%H%M%OS"),input.file.name,"M",num_mappers,"R",num_reducers,sep='')
output.file.local <- paste('rhipe_',format(Sys.time(),"%H%M%OS"),input.file.name,num_mappers,'M',num_reducers,'R',sep='')

mapper <- expression( {
    # 'map.values' is a list containing each line of the input file
    lines <- gsub('(^\\s+|\\s+$)', '', map.values)
    keys <- unlist(strsplit(lines, split='\\s+'))
    value <- 1
    lapply(keys, FUN=rhcollect, value=value)
} )

reducer <- expression(
    # 'reduce.key' is equivalent to this_key and set by Rhipe
    # 'reduce.values' is a list of values corresponding to this_key
    # 'pre' is executed before we process a new reduce.key
    # 'reduce' is executed for 'reduce.values'
    # 'post' is executed once all reduce.values are processed
    pre = {
        running_total <- 0
    },
    reduce = {
        running_total <- sum(running_total, unlist(reduce.values))
    },
    post = {
        rhcollect(reduce.key, running_total)
    }
)


# equivalent to hadoop dfs -copyFromLocal
#rhput(input.file.local, input.file.hdfs)

 mapred = list(
#            mapred.task.timeout=1
	     mapred.max.split.size=as.integer(1024*1024*num_mappers)
            , mapreduce.job.reduces=num_reducers #CDH3,4
	     ,LD_LIBRARY_PATH=paste("/home/apps/protobuf-2.5.0/lib")
        )
rhipe.results <- rhwatch(
                        map=mapper, reduce=reducer,
                        input=rhfmt(input.file.hdfs, type="text"),
                        output=output.dir.hdfs,
                        jobname=paste("rhipe-",num_mappers,num_reducers,combiner,input.file.name,sep="-"),
                        mapred=mapred,
			combiner=combiner,readback=T)

                        # mapred=list(paste("mapreduce.job.maps",num_mappers,sep='='),
            #, mapred.job.reuse.jvm.num.tasks=-1
            #, mapreduce.job.jvm.numtasks=-1
                        #   paste("mapreduce.job.reduces",num_reducers,sep='=')))
# the mapred=... parameter is optional in rhwatch() above

# results on HDFS are in Rhipe object binary format, NOT ASCII, and must be
# read using rhread().  results becomes a list of two-item lists (key,val)

##outputfiles<-rhls(paste(output.dir.hdfs,"/part-*",sep=""))

##for( a in outputfiles$file){
##results <- rhread(a)
##cat(a,"\n")

# the data.frame() below converts list of (key,val) to a list of keys and
# a list of vals, then dumps these into a file with tab delimitation
## write.table( data.frame(words=unlist(lapply(X=results,FUN="[[",1)), 
##                         count=unlist(lapply(X=results,FUN="[[",2))), 
##              file=output.file.local,
##              quote=FALSE,
##		append=TRUE, 
##              row.names=FALSE, 
##              col.names=FALSE,
##              sep="\t"
##              )
##}

proc.time()-time0
