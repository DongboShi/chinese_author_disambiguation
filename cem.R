library(dplyr)
library(rjson)
library(rhdf5)
library(tidyr)
library(rlist)
library(parallel)
install.packages('cem')
install.packages('Amelia')
library(cem)
data<-read.csv('/Users/Lenovo/Desktop/xinxiaoqu/fmzl/cem.csv')
data1 <- data.frame(na.omit(data))
a<-c('qianwu','qiansi','qiansan','qianer','qianyi')
imbalance(group = data1$treat, data = data1[a])
mat <- cem(treatment="treat",data=data1, drop='mean', keep.all=TRUE)
mat
mat$k2k
homo1 <- att(mat, mean~treat,  data=data1)
rand1 <- att(mat, mean~treat,  data=data1, model="linear-RE")
rf1 <- att(mat, mean~treat,  data=data1, model="rf")
homo2 <- att(mat, mean~treat,  data=data1, extra=TRUE)
rand2 <- att(mat, mean~treat,  data=data1, model="linear-RE", extra=TRUE)
rf2 <- att(mat, mean~treat,  data=data1, model="rf", extra=TRUE)
homo1
summary(homo1)
rand1
rf1
homo2
rand2
rf2

plot( homo1, mat, data1, vars=c("qianwu","qiansi","qiansan","qianer",'qianyi'))
plot( rand1, mat, data1, vars=c("qianwu","qiansi","qiansan","qianer",'qianyi'))
plot( rf1, mat, data1, vars=c("qianwu","qiansi","qiansan","qianer",'qianyi'))

plot( homo2, mat, data1, vars=c("qianwu","qiansi","qiansan","qianer",'qianyi'))
plot( rand2, mat, data1, vars=c("qianwu","qiansi","qiansan","qianer",'qianyi'))
plot( rf2, mat, data1, vars=c("qianwu","qiansi","qiansan","qianer",'qianyi'))

mat2 <- k2k(mat, data1, "euclidean", 1)
mat2
mat2$k2k

library(Amelia)
summary(data)
imputed <- amelia(data, noms = c("treat"))
imputed <- imputed$imputations[1:5]

mat3 <- cem("treat", datalist = imputed, drop = "mean", data = data)
mat3

out <- att(mat3, mean ~ treat, data = imputed)
out

mat <- cem(data = data1, drop = "mean")
psample <- pair(mat, data = data1)

table(psample$paired)[1:50]
psample$paired[1:50]
table(psample$full.paired)[1:50]
psample$full.paired[1:10]

