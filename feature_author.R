library(dplyr)
library(rjson)
library(rhdf5)
library(tidyr)
library(rlist)
library(stringr)
library(parallel)
library(readr)
# ptm <- proc.time()
# rm(list=ls())
# setwd('D:/0LLLab/chinese_author_disambiguation')
files <- list.files(path='/Users/zijiangred/changjiang/dataset/inputdata',pattern='CJ_')
id <- sort(as.numeric(str_extract(files,'[0-9]+')))

part_focus_name <- c()
for (i in id){
    data <- fromJSON(file=paste0("/Users/zijiangred/changjiang/dataset/inputdata/CJ_",i,".json"),simplify=T)
    papers <- data$papers
    FocusName <- c()
    for(k in 1:length(papers)){
        name <- data[["papers"]][[k]][["FocusName"]][1]
        FocusName <- c(FocusName,name)
    }
    part_focus_name <- c(part_focus_name,FocusName)
    print(i)
}
# make idf
IDFlName <- as.data.frame(table(str_extract(part_focus_name,'\\S+')))
colnames(IDFlName) <- c('lName','freq')
IDFlName <- mutate(IDFlName,lName_idf = log(sum(freq)/freq))
write.csv(IDFlName,file='/Users/zijiangred/changjiang/dataset/feature/IDFlName_idf.csv',row.names = F,na ='')

# IDFlName <- read.csv('/Users/zijiangred/changjiang/dataset/feature/IDFlName_idf.csv')

for (i in id){
    pairorder <- h5read(file=paste0("/Users/zijiangred/changjiang/dataset/pairorder/",i,"_pair.h5"),name="pair")
    data <- fromJSON(file=paste0("/Users/zijiangred/changjiang/dataset/inputdata/CJ_",i,".json"),simplify=T)
    papers <- data$papers
    FocusName <- data.frame()
    for(k in 1:length(papers)){
        ut <- papers[[k]]$UT
        name <- data[["papers"]][[k]][["FocusName"]][1]
        result<-data.frame()
        if(length(name)>0){
            result <- data.frame(ut,stringsAsFactors = F)
            result$FocusName <- name
        }
        FocusName <- rbind(FocusName,result)
    }
    
    FocusName <- separate(FocusName,FocusName,c('lName','fName'),remove=F)
    fullname_length <- max(str_length(data[["Names"]][[1]]))
    FocusName <- mutate(FocusName,fullname=ifelse(str_length(FocusName)==fullname_length,1,0))
    
    # match info on paper
    pairorderA <- left_join(pairorder,FocusName,by=c('paperA'='ut'))
    colnames(pairorderA) <- c("paperA","paperB","FocusNameA","lNameA","fNameA","fullnameA")
    pairorderAB <- left_join(pairorderA,FocusName,by=c('paperB'='ut'))
    colnames(pairorderAB) <- c("paperA","paperB","FocusNameA","lNameA","fNameA",
                               "fullnameA","FocusNameB","lNameB","fNameB","fullnameB")
    pairorderAB$fullname <- pairorderAB$fullnameA + pairorderAB$fullnameB
    Feature_givenname <- mutate(pairorderAB,givenname = ifelse(fNameA!=fNameB & fullname==1,1,0)) %>%
        mutate(givenname = ifelse(fNameA==fNameB & fullname==0,2,givenname)) %>%
        mutate(givenname = ifelse(fNameA==fNameB & fullname==2,3,givenname))
    
    write.csv(Feature_givenname,file=paste0('/Users/zijiangred/changjiang/dataset/feature/feature_author/Feature_givenname/Feature_givenname_',i,'.csv'),row.names = F,na='')
    
    ############################################################
    pairorderAB_A <- select(left_join(select(pairorderAB,paperA,paperB,lNameA,lNameB),IDFlName,
                                      by=c('lNameA'='lName')),-freq)
    colnames(pairorderAB_A) <- c('paperA','paperB','lNameA','lNameB','lName_idfA')
    pairorderAB_AB <- select(left_join(pairorderAB_A,IDFlName,by=c('lNameB'='lName')),-freq)
    colnames(pairorderAB_AB) <- c('paperA','paperB','lNameA','lNameB','lName_idfA','lName_idfB')
    Feature_lName <- mutate(pairorderAB_AB,IDF_lname=lName_idfA+lName_idfB)
    write.csv(Feature_lName,file=paste0('/Users/zijiangred/changjiang/dataset/feature/feature_author/Feature_lName/Feature_lName_',i,'.csv'),row.names = F,na='')
   
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

    write.csv(Feature_authororder,file=paste0('/Users/zijiangred/changjiang/dataset/feature/feature_author/Feature_authororder/Feature_authororder_',i,'.csv'),row.names = F,na ='')
    print(i)
    }

# proc.time()-ptm