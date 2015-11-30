#!/bin/bash
for num in 6000 3000 2000 1500 1200 900 600 300
do
  Rscript logistic_regression_final.r /user/rhuang/data_lr/data_lr_400 3 $num 1
done
