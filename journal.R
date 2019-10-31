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
jour_corpus <- c()
journal_corpus <- function(){
    for (j in 1:length(file)){
        i = str_split(file[j],'\\.')
        i <- unlist(i)[1]
        i = str_split(i,'\\_')
        i <- unlist(i)[2]
        data <- fromJSON(file=paste0('./data/',file[j]),simplify=T)
        for (h in 1:length(data$papers)){
            journal <- str_to_lower(data$papers[[h]]$Journal)
            journal <- str_trim(journal)
            jour_corpus <- c(jour_corpus,journal)
        }
    }
    jour_corpus <- unlist(jour_corpus)
    jour_corpus <- jour_corpus[jour_corpus != 'na']
    jour_tb <- table(jour_corpus)
    jour_tf_part<-data.frame(unlist(jour_tb))
    names(jour_tf_part) <- c("term","frequency")
    jour_tf_part$term <- as.character(jour_tf_part$term)
    write.csv(jour_tf_part,file="./part/jour_tf_part.csv", row.names = F)
    return(jour_tf_part)
}
jour_tf_part <- journal_corpus()

journal <- function(j){
    i = str_split(file[j],'\\.')
    i <- unlist(i)[1]
    i = str_split(i,'\\_')
    i <- unlist(i)[2]
    data <- fromJSON(file=paste0('./data/',file[j]),simplify=T)
    pairorder_orig <- h5read(file=(paste0('./pair/',i,"_pair.h5")),name="pair")
    papers <- data$papers
    journals <- data.frame()
    for(k in 1:length(papers)){
        ut <- papers[[k]]$UT
        journal <- str_to_lower(papers[[k]]$Journal)
        journal <- str_trim(journal)
        result<-data.frame()
        result <- data.frame(journal,stringsAsFactors = F)
        names(result)<-"journals"
        result$ut <- ut
        journals <- rbind(journals,result)
    }
    pairorder <- pairorder_orig
    pairorder <- left_join(pairorder,journals,by=c('paperA'='ut'))
    colnames(pairorder) <- c("paperA","paperB","journalA")
    pairorder <- left_join(pairorder,journals,by=c('paperB'='ut'))
    colnames(pairorder) <- c("paperA","paperB","journalA",'journalB')
    pairorder <- left_join(pairorder,jour_tf_part,by=c('journalA'='term'))
    colnames(pairorder) <- c("paperA","paperB","journalA",'journalB','fre_part')
    total_part = sum(jour_tf_part$frequency)
    pairorder <- mutate(pairorder,idf_part=log(total_part/fre_part))
    pairorder <- mutate(pairorder,so1=ifelse(journalA == journalB,1,0))
    pairorder <- mutate(pairorder,so1=ifelse(journalA=='na'|journalB=='na',0,so1))
    pairorder <- mutate(pairorder,so2=ifelse(so1==1,idf_part,0))
    pairorder <- pairorder %>%
        arrange(match(paperA,pairorder_orig$paperA),
                match(paperB,pairorder_orig$paperB))
    pairorder <- select(pairorder,paperA,paperB,so1,so2)
    write.csv(pairorder,file=paste0("./feature/journal_",i,".csv"), row.names = F)
}
lapply(1:length(file),journal)
proc.time() - ptm 

mclapply(1:length(file),function(x) journal,mc.cores=6)



