#!/bin/sh
sparkR-submit  --master yarn --executor-memory 1g --num-executors 4 \
housing.R yarn-client /user/$USER/data/housing.txt /user/$USER/output/spark/housing-seq
