library(dplyr)
library(rjson)
library(rhdf5)
library(tidyr)
library(rlist)
library(stringr)
library(parallel)
library(readr)
library(data.table)

# ptm <- proc.time()
# rm(list=ls())
# setwd('D:/0LLLab/chinese_author_disambiguation')
# files <- list.files(path='/home/stonebird/cad/inputdata',pattern='CJ_')
files <- list.files(path='/Users/zijiangred/changjiang/dataset/inputdata',pattern='CJ_')
id <- sort(as.numeric(str_extract(files,'[0-9]+')))

# part_focus_name <- c()
# for (i in id){
#     data <- fromJSON(file=paste0("/Users/zijiangred/changjiang/dataset/inputdata/CJ_",i,".json"),simplify=T)
#     papers <- data$papers
#     FocusName <- c()
#     for(k in 1:length(papers)){
#         name <- data[["papers"]][[k]][["FocusName"]][1]
#         FocusName <- c(FocusName,name)
#     }
#     part_focus_name <- c(part_focus_name,FocusName)
#     print(i)
# }
# # make idf
# IDFlName <- as.data.frame(table(str_extract(part_focus_name,'\\S+')))
# colnames(IDFlName) <- c('lName','freq')
# IDFlName <- mutate(IDFlName,lName_idf = log(sum(freq)/freq))
# write.csv(IDFlName,file='/Users/zijiangred/changjiang/dataset/feature/IDFlName_idf.csv',row.names = F,na ='')

IDFlName <- read.csv('/home/stonebird/cad/IDFlName_idf.csv')
# IDFlName <- read.csv('/Users/zijiangred/changjiang/dataset/feature/IDFlName_idf.csv')

for (i in id[id>102]){
    data <- fromJSON(file=paste0("/home/stonebird/cad/inputdata/CJ_",i,".json"),simplify=T)
    # data <- fromJSON(file=paste0("/Users/zijiangred/changjiang/dataset/inputdata/CJ_",i,".json"),simplify=T)
    papers <- data$papers
    # if (length(papers)<20000){
    inputdata1 <- list.map(papers,FocusName)
    inputdata2 <- list.map(papers,NumAuthors)
    inputdata3 <- list.map(papers,Focus_seq)
    data_mk <- function(inputdata){
        inputdata <- unlist(inputdata)
        inputdata <- setDT(as.data.frame(inputdata), keep.rownames = 'ut')[]
        inputdata <- mutate(inputdata,ut_plus=str_sub(ut,20),
                            ut_plus=ifelse(ut_plus=='',1,ut_plus)) # 出现多个作者取第一个   
        inputdata <- inputdata %>% 
            filter(ut_plus==1) %>%
            select(-ut_plus) %>%
            mutate(ut = str_sub(ut,1,19))
        return(inputdata)
         }
    FocusName <- data_mk(inputdata1)
    NumAuthors <- data_mk(inputdata2)
    Focus_seq <- data_mk(inputdata3)
    fullname_length <- max(str_length(data[["Names"]][[1]]))
    Author_info <- cbind(FocusName,NumAuthors[-1],Focus_seq[-1])
    colnames(Author_info) <- c('ut','FocusName','NumAuthors','Focus_seq')
    Author_info <- separate(Author_info,FocusName,c('lName','fName'),remove=F)
    Author_info <- mutate(Author_info,fullname=ifelse(str_length(FocusName)==fullname_length,1,0),
                          lastauthor = ifelse(Focus_seq==NumAuthors,1,0),
                          firstauthor = ifelse(Focus_seq==1,1,0))
    Author_info <- left_join(Author_info,IDFlName) %>%
        select(-c(NumAuthors,Focus_seq,freq))
    
    Author_infoA <- Author_info
    colnames(Author_infoA) <- c("paperA","FocusNameA","lNameA","fNameA","fullnameA","lastauthorA",
                                "firstauthorA","lName_idfA")
    Author_infoB <- Author_info
    colnames(Author_infoB) <- c("paperB","FocusNameB","lNameB","fNameB","fullnameB","lastauthorB",
                                "firstauthorB","lName_idfB")
    Author_info_pair <- crossing(Author_infoA,Author_infoB) %>%
        filter(paperA < paperB) %>%
        mutate(fullname = fullnameA + fullnameB)
    featur_author <- mutate(Author_info_pair,givenname = ifelse(fNameA!=fNameB & fullname==1,1,0)) %>%
        mutate(givenname = ifelse(fNameA==fNameB & fullname==0,2,givenname)) %>%
        mutate(givenname = ifelse(fNameA==fNameB & fullname==2,3,givenname),
               IDF_lname=lName_idfA+lName_idfB) %>%
        mutate(authororder = ifelse(firstauthorA==1 & firstauthorB==1,2,0)) %>%
        mutate(authororder = ifelse(lastauthorA ==1 & lastauthorB==1,1,authororder)) %>%
        mutate(authororder = ifelse(firstauthorA ==1 & lastauthorB==1,1,authororder)) %>%
        mutate(authororder = ifelse(lastauthorA ==1 & firstauthorB==1,1,authororder)) %>%
        select(paperA,paperB,givenname,IDF_lname,authororder)
    write.csv(featur_author,file=paste0('/home/stonebird/cad/feature/author_full/Feature_author_',i,'.csv'),row.names = F,na ='')
    # write.csv(featur_author,file=paste0('/Users/zijiangred/changjiang/dataset/Meng_feature/all_feature_author/Feature_authororder_',i,'.csv'),row.names = F,na ='')
    # }
     print(i)
    }

# proc.time()-ptm
