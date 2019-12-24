library(dplyr)
library(rjson)
library(rhdf5)
library(tidyr)
library(rlist)
library(stringr)
library(parallel)
library(readr)
library(data.table)


data_mk <- function(inputdata){
        inputdata <- unlist(inputdata)
        inputdata <- setDT(as.data.frame(inputdata), keep.rownames = 'ut')[]
        inputdata <- mutate(inputdata,ut_plus=str_sub(ut,20),
                            ut_plus=ifelse(ut_plus=='',1,ut_plus)) # 出现多个作者取第一个   
        inputdata <- inputdata %>% 
                filter(ut_plus==1) %>%
                select(-ut_plus)
        return(inputdata)
}

# ptm <- proc.time()
# rm(list=ls())
# setwd('D:/0LLLab/chinese_author_disambiguation')
files <- list.files(path='/home/stonebird/cad/inputdata',pattern='CJ_')
# files <- list.files(path='/Users/zijiangred/changjiang/dataset/inputdata',pattern='CJ_')
id <- sort(as.numeric(str_extract(files,'[0-9]+')))
files1 <- list.files(path='/home/stonebird/cad/feature/author_full') 
id1 <- sort(as.numeric(str_extract(files1,'[0-9]+')))
id <- id[!(id %in% id1)]

IDFlName <- read.csv('/home/stonebird/cad/tf_file/IDFlName_idf.csv')

for (j in 1:length(id)){
    i <- id[j]
    data <- fromJSON(file=paste0("/home/stonebird/cad/inputdata/CJ_",i,".json"),simplify=T)
    # data <- fromJSON(file=paste0("/Users/zijiangred/changjiang/dataset/inputdata/CJ_",i,".json"),simplify=T)
    papers <- data$papers
    # if (length(papers)<20000){
    inputdata1 <- list.map(papers,FocusName)
    inputdata2 <- list.map(papers,NumAuthors)
    inputdata3 <- list.map(papers,Focus_seq)
    
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
    Author_info <- left_join(Author_info,IDFlName,by = "lName") %>%
        select(-c(NumAuthors,Focus_seq,freq))
    rm(data)
    rm(papers)
    rm(FocusName)
    rm(NumAuthors)
    rm(Focus_seq)
    rm(inputdata1)
    rm(inputdata2)
    rm(inputdata3)
    gc()
    Author_infoA <- Author_info
    colnames(Author_infoA) <- c("paperA","FocusNameA","lNameA","fNameA","fullnameA","lastauthorA",
                                "firstauthorA","lName_idfA")
    Author_infoB <- Author_info
    colnames(Author_infoB) <- c("paperB","FocusNameB","lNameB","fNameB","fullnameB","lastauthorB",
                                "firstauthorB","lName_idfB")
    #Author_info_pair <- data.frame()
    featur_author_list <- list()
    
    for(k in seq(1,length(Author_infoA$paperA),5000)){
            m <- round(k/5000)+1
            tmp <- Author_infoA[k:(k+4999),]
            result <- crossing(tmp,Author_infoB) %>%
                    filter(paperA < paperB) %>%
                    mutate(fullname = fullnameA + fullnameB)
            result <- result %>%
                    mutate(givenname = ifelse(fNameA!=fNameB & fullname==1,1,0)) %>%
                    mutate(givenname = ifelse(fNameA==fNameB & fullname==0,2,givenname)) %>%
                    mutate(givenname = ifelse(fNameA==fNameB & fullname==2,3,givenname),
                           IDF_lname=lName_idfA+lName_idfB) %>%
                    mutate(authororder = ifelse(firstauthorA==1 & firstauthorB==1,2,0)) %>%
                    mutate(authororder = ifelse(lastauthorA ==1 & lastauthorB==1,1,authororder)) %>%
                    mutate(authororder = ifelse(firstauthorA ==1 & lastauthorB==1,1,authororder)) %>%
                    mutate(authororder = ifelse(lastauthorA ==1 & firstauthorB==1,1,authororder)) %>%
                    select(paperA,paperB,givenname,IDF_lname,authororder)
            featur_author_list[[m]] <- result
            rm(result)
            gc()
            print(k)
    } 
    featur_author <- data.frame()
    
    for(k in 1:length(featur_author_list)){
            featur_author <- rbind(featur_author,featur_author_list[[k]])
            gc()
            print(k)
    }
   
    rm(featur_author_list)
    rm(Author_infoA)
    rm(Author_infoB)
    rm(Author_info)
    gc()
    write.csv(featur_author,file=paste0('/home/stonebird/cad/feature/author_full/Feature_author_',i,'.csv'),row.names = F,na ='')
    # write.csv(featur_author,file=paste0('/Users/zijiangred/changjiang/dataset/Meng_feature/all_feature_author/Feature_authororder_',i,'.csv'),row.names = F,na ='')
    # }
    print(j)
}

# proc.time()-ptm