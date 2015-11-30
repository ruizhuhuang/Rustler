
library(Rhipe)
rhinit()

rhoptions(runner = 'R CMD /home/apps/big-data-r/Rhipe/bin/RhipeMapReduce --slave --silent --vanilla')


map1 <- expression({
  lapply(seq_along(map.keys), function(r) {
    line = strsplit(map.values[[r]], ",")[[1]]
    outputkey <- line[1:3]
    outputvalue <- data.frame(
      date = as.numeric(line[4]),
      units =  as.numeric(line[5]),
      listing = as.numeric(line[6]),
      selling = as.numeric(line[7]),
      stringsAsFactors = FALSE
    )
  rhcollect(outputkey, outputvalue)
  })
})


reduce1 <- expression(
  pre = {
    reduceoutputvalue <- data.frame()
  },
  reduce = {
    reduceoutputvalue <- rbind(reduceoutputvalue, do.call(rbind, reduce.values))
  },
  post = {
    reduceoutputkey <- reduce.key[1]
    attr(reduceoutputvalue, "location") <- reduce.key[1:3]
    names(attr(reduceoutputvalue, "location")) <- c("FIPS","county","state")
    rhcollect(reduceoutputkey, reduceoutputvalue)
  }
)

 mapred = list(
#	     mapred.max.split.size=as.integer(1024*1024*num_mappers)
#            , mapreduce.job.reduces=num_reducers #CDH3,4
	     LD_LIBRARY_PATH=paste("/home/apps/protobuf-2.5.0/lib")
        )


mr1 <- rhwatch(
  map      = map1,
  reduce   = reduce1,
  mapred   = mapred,
  input    = rhfmt("/user/rhuang/data/housing.txt", type = "text"),
  output   = rhfmt("/user/rhuang/output/housing/byCounty", type = "sequence"),
  readback = FALSE
)





