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

makeem <- function(i){
        id <- str_extract(i,pattern = "[0-9]+")
        data <- fromJSON(file=paste0("/Users/zijiangred/changjiang/dataset/inputdata/CJ_",id,".json"),simplify=T)
        papers <- data$papers
        Email <- data.frame()
        for(k in 1:length(papers)){
                ut <- papers[[k]]$UT
                em <- papers[[k]]$Email[[1]]
                result<-data.frame()
                if(length(em)>0){
                        result <- data.frame(em,stringsAsFactors = F)
                        names(result)<-"email"
                        result$ut <- ut
                }
                result <- result %>% filter(email!="NA")
                Email <- rbind(Email,result)}
        pair <- inner_join(Email,Email,by="email") %>% 
                rename(paperA = ut.x,paperB=ut.y) %>%
                filter(paperA < paperB) %>%
                select(paperA,paperB)
        write.csv(pair,file = paste0("/Users/zijiangred/changjiang/dataset/feature/email/email_",id,".csv"),row.names = F)
}
for(i in 1:length(fl)){
        makeem(fl[i])
        print(i)
}
