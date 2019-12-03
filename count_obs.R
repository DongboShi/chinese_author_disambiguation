library(dplyr)
library(rjson)
library(rhdf5)
library(tidyr)
library(rlist)
library(parallel)
library(stringr)
rm(list=ls())
setwd("/Users/zijiangred/changjiang/dataset/pairorder")
fl <- list.files(path = "/Users/zijiangred/changjiang/dataset/grandtruth")
fl <- fl[str_detect(fl,"json")]
observations <- data.frame(paste0("CJ",str_extract(fl,"[0-9]+")))
names(observations) <- "cj"
observations <- observations %>% 
        mutate(ntruth = 0,
               ntotal = 0)
for(j in 1:length(fl)){
        i <- fl[j]
        id <- str_extract(i,pattern = "[0-9]+")
        data <- fromJSON(file=paste0("/Users/zijiangred/changjiang/dataset/inputdata/CJ_",id,".json"),simplify=T)
        grandtruth <- fromJSON(file=paste0("/Users/zijiangred/changjiang/dataset/grandtruth/",i),simplify=T)
        papers <- data$papers
        gtpaper <- grandtruth[[1]][[2]]
        observations$cj[j] <- i
        observations$ntruth[j] <- length(gtpaper)
        observations$ntotal[j] <- length(papers)
}
write.csv(observations,file = paste0("/Users/zijiangred/changjiang/dataset/feature/observations.csv"),row.names = F)





