#!/bin/bash
Rscript logistic_regression_final.r /user/rhuang/data_lr/data_lr_200 3 5000 1 >& lr.out.5000 &
Rscript logistic_regression_final.r /user/rhuang/data_lr/data_lr_400 3 10000 1 >& lr.out.10000 &
Rscript logistic_regression_final.r /user/rhuang/data_lr/data_lr_600 3 15000 1 >& lr.out.15000 &
Rscript logistic_regression_final.r /user/rhuang/data_lr/data_lr_800 3 20000 1 >& lr.out.20000 &
