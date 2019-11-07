library(rhdf5)
library(dplyr)
library(rjson)
library(tidyr)
library(rlist)
library(readr)
library(stringr)
library(parallel)

fl <- list.files(path = "/Users/zijiangred/changjiang/dataset/inputdata")
fl <- fl[str_detect(fl,"json")]

#做词袋,局部
jour_corpus <- c()
journal_corpus <- function(){
    for (j in 1:length(fl)){
        data <- fromJSON(file=paste0("/Users/zijiangred/changjiang/dataset/inputdata/",fl[j]),simplify=T)
        papers<-data$papers
        journal <- list.map(papers,Journal)
        tmp <- str_trim(unlist(journal))
        journal <- tolower(tmp)
        jour_corpus <- c(jour_corpus,journal)
        print(j)
    }
    jour_corpus <- jour_corpus[jour_corpus != 'na']
    jour_tb <- table(jour_corpus)
    jour_tf_part<-data.frame(unlist(jour_tb))
    names(jour_tf_part) <- c("term","frequency")
    jour_tf_part$term <- as.character(jour_tf_part$term)
    write.csv(jour_tf_part,file="/Users/zijiangred/changjiang/dataset/part/jour_tf_part.csv", row.names = F)
    return(jour_tf_part)
}
jour_tf_part <- journal_corpus()


######################################################################
library(rhdf5)
library(dplyr)
library(rjson)
library(tidyr)
library(rlist)
library(readr)
library(stringr)
library(parallel)
library(data.table)
#c:/Users/liuningjie/Desktop/chinese
fl <- list.files(path = "/Users/zijiangred/changjiang/dataset/inputdata")
fl <- fl[str_detect(fl,"json")]
jour_tf_part <- read_csv(file="/Users/zijiangred/changjiang/dataset/part/jour_tf_part.csv")

journal <- function(j){
    i = str_split(fl[j],'\\.')
    i <- unlist(i)[1]
    i = str_split(i,'\\_')
    i <- unlist(i)[2]
    data <- fromJSON(file=paste0("/Users/zijiangred/changjiang/dataset/inputdata/",fl[j]),simplify=T)
    pairorder_orig <- h5read(file=(paste0("/Users/zijiangred/changjiang/dataset/pairorder/",i,"_pair.h5")),name="pair")
    papers <- data$papers
    journal <- unlist(list.map(papers,Journal))
    journals <- setDT(as.data.frame(journal), keep.rownames = 'ut')[]
    journals$journal <- tolower(str_trim(journals$journal))
    journals$ut<-str_sub(journals$ut,1,19)
    journals<- journals %>% filter(journal!='na')
    pairorder <- pairorder_orig
    A <- inner_join(pairorder,journals,by=c('paperA'='ut'))
    colnames(A) <- c("paperA","paperB","journalA")
    B <- inner_join(pairorder,journals,by=c('paperB'='ut'))
    colnames(B) <- c("paperA","paperB",'journalB')
    journal_inner <- inner_join(A,B,by=c('paperA'='paperA','paperB'='paperB','journalA'='journalB'))
    if(nrow(journal_inner)==0){
        pairorder$so1 <- 0
        pairorder$so2 <- 0
    }else{
        journal_inner <- left_join(journal_inner,jour_tf_part,by=c('journalA'='term'))
        total_part = sum(jour_tf_part$frequency)
        journal_inner <- mutate(journal_inner,idf_part=log(total_part/frequency))
        journal_inner$so1<-1
        journal_inner$so2<-journal_inner$idf_part
        pairorder <- left_join(pairorder,journal_inner,by=c('paperA'='paperA','paperB'='paperB'))
    }
    pairorder <- pairorder %>%
        arrange(match(paperA,pairorder_orig$paperA),
                match(paperB,pairorder_orig$paperB))
    pairorder <- pairorder %>%select(paperA,paperB,so1,so2)
    pairorder[is.na(pairorder)] <- 0
    write.csv(pairorder,file=paste0("/Users/zijiangred/changjiang/dataset/feature/journal/jour_",i,".csv"), row.names = F)
    print(j)
}
lapply(1:length(fl),journal)




