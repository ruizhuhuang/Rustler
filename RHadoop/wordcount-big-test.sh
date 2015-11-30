#!/bin/sh
hadoop jar $HADOOP_STREAMING \
-D mapred.map.tasks=20 -D mapred.reduce.tasks=10 \
-file mapper-2.R -mapper mapper-2.R \
-file reducer-4.R -reducer reducer-4.R \
-input /tmp/data/enwiki-20120104-pages-articles.xml  -output /user/rhuang/wc-xml/output-33g-test-20-111
