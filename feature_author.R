library(dplyr)
library(rjson)
library(rhdf5)
library(tidyr)
library(rlist)
library(stringr)
library(parallel)
library(readr)
# ptm <- proc.time()
rm(list=ls())
setwd('D:/0LLLab/chinese_author_disambiguation')
# setwd("/Users/birdstone/Documents/Data")
# h5read(pair[c("paperA","paperB")],file=paste0("/Users/zijiangred/changjiang/dataset/pairorder/",
#                                               i,"_pair.h5"),name="pair")
i = 1
pairorder <- h5read(file=paste0(i,"_pair.h5"),name="pair")
# data <- fromJSON(file=paste0("/Users/zijiangred/changjiang/dataset/inputdata/",i,".json"),simplify=T)
data <- fromJSON(file=paste0("CJ_",i,".json"),simplify=T)
papers <- data$papers
# All ut affliation
FoucusName <- data.frame()
for(k in 1:length(papers)){
    ut <- papers[[k]]$UT
    name <- data[["papers"]][[k]][["FocusName"]]
    result<-data.frame()
    if(length(name)>0){
        result <- data.frame(ut,stringsAsFactors = F)
        result$FoucusName <- name
    }
    FoucusName <- rbind(FoucusName,result)
}
FoucusName <- separate(FoucusName,FoucusName,c('lName','fName'),remove=F)
fullname_length <- max(str_length(data[["Names"]][[1]]))
FoucusName <- mutate(FoucusName,fullname=ifelse(str_length(FoucusName)==fullname_length,1,0))

# match info on paper
pairorderA <- left_join(pairorder,FoucusName,by=c('paperA'='ut'))
colnames(pairorderA) <- c("paperA","paperB","FoucusNameA","lNameA","fNameA","fullnameA")
pairorderAB <- left_join(pairorderA,FoucusName,by=c('paperB'='ut'))
colnames(pairorderAB) <- c("paperA","paperB","FoucusNameA","lNameA","fNameA",
                           "fullnameA","FoucusNameB","lNameB","fNameB","fullnameB")
pairorderAB$fullname <- pairorderAB$fullnameA + pairorderAB$fullnameB
Feature_givenname <- mutate(pairorderAB,givenname = ifelse(fNameA!=fNameB & fullname==1,1,0)) %>%
    mutate(givenname = ifelse(fNameA==fNameB & fullname==0,2,givenname)) %>%
    mutate(givenname = ifelse(fNameA==fNameB & fullname==2,3,givenname))

write.csv(Feature_givenname,file='Feature_givenname_1.csv',row.names = F,na='')

############################################################

AuthorOrder <- data.frame()
for(k in 1:length(papers)){
    ut <- papers[[k]]$UT
    Focus_seq <- data[["papers"]][[k]][["Focus_seq"]]
    NumAuthors <- data[["papers"]][[k]][["NumAuthors"]]
    result<-data.frame()
    # if(length(name)>0){
    result <- data.frame(ut,stringsAsFactors = F)
    result$Focus_seq <- Focus_seq
    result$NumAuthors <- NumAuthors
    # }
    AuthorOrder <- rbind(AuthorOrder,result)
}

AuthorOrder <- mutate(AuthorOrder,lastauthor = ifelse(Focus_seq==NumAuthors,1,0))

pairorderA <- left_join(pairorder,AuthorOrder,by=c('paperA'='ut'))
colnames(pairorderA) <- c("paperA","paperB","Focus_seqA","NumAuthorsA","lastauthorA")
pairorderAB <- left_join(pairorderA,AuthorOrder,by=c('paperB'='ut')) 
colnames(pairorderAB) <- c("paperA","paperB","Focus_seqA","NumAuthorsA","lastauthorA",
                           "Focus_seqB","NumAuthorsB","lastauthorB")

Feature_authororder <- mutate(pairorderAB,authororder = ifelse(Focus_seqA==1 & Focus_seqB==1,2,0)) %>%
    mutate(authororder = ifelse(lastauthorA ==1 & lastauthorB==1,1,authororder)) %>%
    mutate(authororder = ifelse(Focus_seqA ==1 & lastauthorB==1,1,authororder)) %>%
    mutate(authororder = ifelse(lastauthorA ==1 & Focus_seqB==1,1,authororder))

write.csv(Feature_authororder,file='Feature_authororder_1.csv',row.names = F,na ='')
