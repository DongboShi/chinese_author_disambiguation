#install.packages("data.tree")
#install.packages("rlist")
#install.packages("rjson")
#install.packages("BiocManager")
#BiocManager::install("rhdf5")
library(dplyr)
library(rjson)
library(rhdf5)
library(tidyr)
library(rlist)
library(parallel)
library(stringr)
rm(list=ls())
setwd("/Users/zijiangred/changjiang/dataset/pairorder")

#library(XML)
#library(data.tree)
##读入数据

fl <- list.files(path = "/Users/zijiangred/changjiang/dataset/grandtruth")
fl <- fl[str_detect(fl,"json")]

#grandtruth <- fromJSON(file="/Users/zijiangred/changjiang/dataset/inputdata/exact_list.json",simplify=T)
#print("successfully load grandtruth data")
##定义样本对顺序
#grandtruth <- fromJSON(file="/Users/zijiangred/test/Exact_1.json",simplify = T)
#gtpaper <- grandtruth[[1]][2]
#data <- fromJSON(file="/Users/zijiangred/test/CJ_1.json",simplify=T)
#h5write(pair[c("paperA","paperB")],file=paste0("1","_pair.h5"),name="pair")
#file.remove(paste0("1","_pair.h5"))
makepair <- function(i){
        id <- str_extract(i,pattern = "[0-9]+")
        grandtruth <- fromJSON(file=paste0("/Users/zijiangred/changjiang/dataset/grandtruth/",i),simplify=T)
        gtpaper <- grandtruth[[1]][[2]]
        gtpaper1 <- gtpaper
        pair <- crossing(gtpaper,gtpaper1) %>% 
                rename(paperA=gtpaper,paperB = gtpaper1) %>%
                filter(paperA < paperB)
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
        # 制造正样本
        pair2 <- inner_join(Email,Email,by="email") %>% 
                rename(paperA = ut.x,paperB=ut.y) %>%
                filter(paperA < paperB) %>%
                select(paperA,paperB)
        pair3 <- anti_join(pair2,pair,by=c("paperA","paperB"))
        # negative pairs
        fullut <- unlist(list.select(papers,UT))
        negpaper <- fullut[!fullut%in%gtpaper]
        pair4 <- crossing(gtpaper,negpaper) %>%
                rename(paperA = gtpaper, paperB=negpaper)
        pair4$label <- 0
        if(dim(pair)[1]>0){
                pair$label <- 1
                if(dim(pair3)[1]>0){
                        pair3$label <- 1
                        pair_final <- rbind(pair,pair3)
                        pair_final <- rbind(pair_final,pair4)
                }else{
                        pair_final <- rbind(pair,pair4)
                }
        }else{
                if(dim(pair3)[1]>0){
                        pair3$label <- 1
                        pair_final <- rbind(pair3,pair4)
                }else{
                        pair_final <- pair4
                }
        }
        
        # export results
        if(paste0(id,"_pair.h5") %in% list.files()){
                file.remove(paste0(id,"_pair.h5"))
        }
        if(paste0(id,"_label.h5") %in% list.files()){
                file.remove(paste0(id,"_label.h5"))
        }
        h5write(pair_final[c("paperA","paperB")],file=paste0(id,"_pair.h5"),name="pair")
        h5write(pair_final[c("label")],file=paste0(id,"_label.h5"),name="label")
}
for(i in fl){
        makepair(i)
        print(i)
}
mclapply(1:length(fl),makepair,mc.cores=3)


