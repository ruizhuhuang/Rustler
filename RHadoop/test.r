library(rmr2)
a=to.dfs(1:10^5)
str(a)

from.dfs(to.dfs(1:10^5))
from.dfs(to.dfs(keyval(1, 1:10^5)))
