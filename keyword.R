ptm = proc.time()
library(rhdf5)
library(dplyr)
library(rjson)
library(tidyr)
library(readr)
library(stringr)
library(parallel)

setwd("C:/Users/liuningjie/Desktop/chinese/data")
file = list.files()
setwd("C:/Users/liuningjie/Desktop/chinese")
#做词袋,局部
key_corpus <- c()
keyword_corpus <- function(){
    for (j in 1:length(file)){
        i = str_split(file[j],'\\.')
        i <- unlist(i)[1]
        i = str_split(i,'\\_')
        i <- unlist(i)[2]
        data <- fromJSON(file=paste0('./data/',file[j]),simplify=T)
        for (h in 1:length(data$papers)){
            keyword <- str_to_lower(data$papers[[h]]$Keywords)
            if (length(keyword) == 1){
                keyword <- str_split(keyword,';')
                keyword <- unlist(keyword)
            }
            keyword <- str_trim(keyword)
            key_corpus <- c(key_corpus,keyword)
        }
    }
    key_corpus <- unlist(key_corpus)
    key_corpus <- key_corpus[key_corpus!='na']
    key_tb <- table(key_corpus)
    key_tf_part<-data.frame(unlist(key_tb))
    names(key_tf_part) <- c("term","frequency")
    key_tf_part$term <- as.character(key_tf_part$term)
    write.csv(key_tf_part,file="./part/key_tf_part.csv", row.names = F)
    return(key_tf_part)
}
key_tf_part <- keyword_corpus()
key_tf_global <- read_csv(file="./global/kw_tf.csv")

keyword <- function(j){
    i = str_split(file[j],'\\.')
    i <- unlist(i)[1]
    i = str_split(i,'\\_')
    i <- unlist(i)[2]
    data <- fromJSON(file=paste0('./data/',file[j]),simplify=T)
    pairorder_orig <- h5read(file=(paste0('./pair/',i,"_pair.h5")),name="pair")
    #全局
    papers <- data$papers
    keywords <- data.frame()
    for(k in 1:length(papers)){
        ut <- papers[[k]]$UT
        keyword <- str_to_lower(papers[[k]]$Keywords)
        if (length(keyword) == 1){
            keyword <- str_split(keyword,';')
            keyword <- unlist(keyword)
        }
        keyword <- str_trim(keyword)
        result<-data.frame()
        if(length(keyword)>0){
            result <- data.frame(keyword,stringsAsFactors = F)
            names(result)<-c("keywords")
            result$ut <- ut
        }
        keywords <- rbind(keywords,result)
        
    }
    keywords <- filter(keywords,keywords!='na')
    pairorder <- pairorder_orig
    A <- inner_join(pairorder,keywords,by=c('paperA'='ut'))
    colnames(A) <- c("paperA","paperB","keywordsA")
    B <- inner_join(pairorder,keywords,by=c('paperB'='ut'))
    colnames(B) <- c("paperA","paperB","keywordsB")
    keywords_inner <- inner_join(A,B,by=c('paperA'='paperA','paperB'='paperB','keywordsA'='keywordsB'))
    keywords_inner <- left_join(keywords_inner,key_tf_global,by=c('keywordsA'='term'))
    colnames(keywords_inner) <- c("paperA","paperB","keywordsA",'fre_global')
    keywords_inner <- left_join(keywords_inner,key_tf_part,by=c('keywordsA'='term'))
    colnames(keywords_inner) <- c("paperA","paperB","keywordsA",'fre_global','fre_part')
    total_global = sum(key_tf_global$frequency)
    total_part = sum(key_tf_part$frequency)
    keywords_inner <- mutate(keywords_inner,idf_part=log(total_part/fre_part))
    keywords_inner <- mutate(keywords_inner,idf_global=log(total_global/fre_global))
    keywords_inner <- keywords_inner%>%group_by(paperA,paperB)%>%summarise(kw1=n(),kw2=sum(idf_part),kw3=sum(idf_global))
    pairorder <- left_join(pairorder,keywords_inner,by=c('paperA'='paperA','paperB'='paperB'))
    pairorder <- pairorder %>%
        arrange(match(paperA,pairorder_orig$paperA),
                match(paperB,pairorder_orig$paperB))
    pairorder[is.na(pairorder)] <- 0
    write.csv(pairorder,file=paste0("./feature/keyword_",i,".csv"), row.names = F)
}
lapply(1:length(file),keyword)
proc.time() - ptm 
    
