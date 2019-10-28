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
rm(list=ls())
setwd("/Users/zijiangred/changjiang/dataset/pairorder")

#library(XML)
#library(data.tree)
##读入数据
grandtruth <- fromJSON(file="/Users/zijiangred/changjiang/dataset/inputdata/exact_list.json",simplify=T)
print("successfully load grandtruth data")

##定义样本对顺序
makepair <- function(i,gt){
        gtpaper <- grandtruth[[i]][[2]]
        gtpaper1 <- gtpaper
        pair <- crossing(gtpaper,gtpaper1) %>% 
                rename(paperA=gtpaper,paperB = gtpaper1) %>%
                filter(paperA < paperB)
        #读入备选集
        data <- fromJSON(file=paste0("/Users/zijiangred/changjiang/dataset/inputdata/",i,".json"),simplify=T)
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
        if(dim(pair)[1]>0){
                pair$label <- 1
                if(dim(pair3)[1]>0){
                        pair3$label <- 1
                        fullut <- unlist(list.select(papers,UT))
                        negpaper <- fullut[!fullut%in%gtpaper]
                        pair4 <- crossing(gtpaper,negpaper) %>%
                                rename(paperA = gtpaper, paperB=negpaper)
                        pair4$label <- 0
                        pair_final <- rbind(pair,pair3)
                        pair_final <- rbind(pair_final,pair4)
                }else{
                        fullut <- unlist(list.select(papers,UT))
                        negpaper <- fullut[!fullut%in%gtpaper]
                        pair4 <- crossing(gtpaper,negpaper) %>%
                                rename(paperA = gtpaper, paperB=negpaper)
                        pair4$label <- 0
                        pair_final <- rbind(pair,pair4)
                }
        }else{
                if(dim(pair3)[1]>0){
                        pair3$label <- 1
                        fullut <- unlist(list.select(papers,UT))
                        negpaper <- fullut[!fullut%in%gtpaper]
                        pair4 <- crossing(gtpaper,negpaper) %>%
                                rename(paperA = gtpaper, paperB=negpaper)
                        pair4$label <- 0
                        pair_final <- rbind(pair,pair3)
                        pair_final <- rbind(pair_final,pair4)
                }else{
                        fullut <- unlist(list.select(papers,UT))
                        negpaper <- fullut[!fullut%in%gtpaper]
                        pair4 <- crossing(gtpaper,negpaper) %>%
                                rename(paperA = gtpaper, paperB=negpaper)
                        pair4$label <- 0
                        pair_final <- rbind(pair,pair4)
                }
        }
        if(paste0(i,"_pair.h5") %in% list.files()){
                file.remove(paste0(i,"_pair.h5"))
        }
        if(paste0(i,"_label.h5") %in% list.files()){
                file.remove(paste0(i,"_label.h5"))
        }
        h5write(pair_final[c("paperA","paperB")],file=paste0(i,"_pair.h5"),name="pair")
        h5write(pair_final[c("label")],file=paste0(i,"_label.h5"),name="label")
}


for(i in 162:length(grandtruth)){
        makepair(i,grandtruth)
        print(i)
}
mclapply(1:length(grandtruth),function(x) makepair(x,grandtruth),mc.cores=6)

