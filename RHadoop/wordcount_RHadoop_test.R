#!/usr/bin/Rscript

library(rmr2)

args=commandArgs(trailingOnly = TRUE) 


bp =
  list(
    hadoop =
      list(
        D = paste("mapred.job.name=", args[[1]], sep=''),
        D = "mapreduce.map.memory.mb=11500",
        D = "mapreduce.reduce.memory.mb=11500",
        D = "mapreduce.map.java.opts=-Xmx9000M",
        D = "mapreduce.reduce.java.opts=-Xmx9000M",
	#D = "mapreduce.map.memory.mb=-1",
	#D = "mapreduce.reduce.memory.mb=-1",
        D = "mapreduce.tasktracker.map.tasks.maximum=2",
        D = "mapreduce.tasktracker.reduce.tasks.maximum=2",
	D = "mapreduce.input.fileinputformat.split.minsize=0",
	D = "mapreduce.jobtracker.maxtasks.perjob=-1",
	D = "mapreduce.reduce.input.limit=-1",
        D = paste("mapreduce.job.maps=", args[[2]], sep=''),
        D = paste("mapreduce.job.reduces=", args[[3]], sep='')
                                        ))


rmr.options(backend.parameters = bp);

rmr.options("backend.parameters")

wordcount = 
    function(input, output = args[[5]], pattern = " "){
        wc.map = function(., lines) {
#	    lines=gsub("[^[:alnum:]///' ]", "", lines)
            keyval(unlist(lapply(lines,function(line)strsplit(line,fixed=T,split=pattern)[[1]])),1)}
            #keyval(unlist(strsplit( x = lines,fixed=T, split = pattern)),1)}

 	wc.reduce = function(word, counts ) {
	    keyval(word, sum(counts))}
	      
	mapreduce(input = input,
            output = output,
            input.format = "text",
	    #output.format = "text",
            map = wc.map,
            reduce = wc.reduce,
	    combine=TRUE)}

head(as.data.frame(from.dfs(wordcount(args[[4]]))))

#as.data.frame(from.dfs(wordcount(args[[3])))
