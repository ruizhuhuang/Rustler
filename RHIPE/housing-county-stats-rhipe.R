library(Rhipe)
rhinit()

rhoptions(runner = 'R CMD /home/apps/big-data-r/Rhipe/bin/RhipeMapReduce --slave --silent --vanilla')


map2 <- expression({
  lapply(seq_along(map.keys), function(r) {
    outputvalue <- data.frame(
      FIPS = map.keys[[r]],
      county = attr(map.values[[r]], "location")["county"],
      min = min(map.values[[r]]$listing, na.rm = TRUE),
      median = median(map.values[[r]]$listing, na.rm = TRUE),
      max = max(map.values[[r]]$listing, na.rm = TRUE),
      stringsAsFactors = FALSE
    )
    outputkey <- attr(map.values[[r]], "location")["state"]
    rhcollect(outputkey, outputvalue)
  })
})

reduce2 <- expression(
  pre = {
    reduceoutputvalue <- data.frame()
  },
  reduce = {
    reduceoutputvalue <- rbind(reduceoutputvalue, do.call(rbind, reduce.values))
  },
  post = {
    rhcollect(reduce.key, reduceoutputvalue)
  }
)

 mapred = list(
#	     mapred.max.split.size=as.integer(1024*1024*num_mappers)
#            , mapreduce.job.reduces=num_reducers #CDH3,4
	     LD_LIBRARY_PATH=paste("/home/apps/protobuf-2.5.0/lib")
        )


CountyStats <- rhwatch(
  map      = map2,
  reduce   = reduce2,
  mapred   = mapred,
  input    = rhfmt("/user/rhuang/output/housing/byCounty", type = "sequence"),
  output   = rhfmt("/user/rhuang/output/housing/CountyStats", type = "sequence"),
  readback = TRUE
)

