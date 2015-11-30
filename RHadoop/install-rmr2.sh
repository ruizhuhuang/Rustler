#!/bin/sh

echo 'options("repos" = c(CRAN="http://cran.fhcrc.org"))
install.packages(c("Rcpp", "RJSONIO", "digest", "functional", "reshape2", 
"stringr", "plyr", "caTools"))' > pre-rmr2.R
Rscript pre-rmr2.R

export HADOOP_CMD=/usr/bin/hadoop
export HADOOP_STREAMING=/usr/lib/hadoop-mapreduce/hadoop-streaming-2.3.0-cdh5.1.0.jar
R CMD INSTALL rmr2_3.3.1.tar.gz
