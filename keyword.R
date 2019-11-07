library(rhdf5)
library(dplyr)
library(rjson)
library(tidyr)
library(readr)
library(rlist)
library(stringr)
library(parallel)

fl <- list.files(path = "/Users/zijiangred/changjiang/dataset/inputdata")
fl <- fl[str_detect(fl,"json")]

#做词袋,局部
key_corpus <- c()
keyword_corpus <- function(){
    for (j in 1:length(fl)){
        data <- fromJSON(file=paste0("/Users/zijiangred/changjiang/dataset/inputdata/",fl[j]),simplify=T)
        papers<-data$papers
        keyword <- list.map(papers,Keywords)
        tmp <- unlist(keyword)
        tmp1 <- tmp[str_detect(tmp,";")]
        tmp2 <- tmp[!str_detect(tmp,";")]
        tmp3 <- str_trim(unlist(lapply(tmp1,function(x) str_split(x,";"))),side="both")
        keyword_final <- tolower(c(tmp2,tmp3))
        key_corpus <- c(key_corpus,keyword_final)
        print(j)
    }
    key_corpus <- key_corpus[key_corpus!='na']
    key_tb <- table(key_corpus)
    key_tf_part<-data.frame(unlist(key_tb))
    names(key_tf_part) <- c("term","frequency")
    key_tf_part$term <- as.character(key_tf_part$term)
    write.csv(key_tf_part,file="/Users/zijiangred/changjiang/dataset/part/jour_tf_part.csv", row.names = F)
    return(key_tf_part)
}

key_tf_part <- keyword_corpus()
#########################################################################
library(rhdf5)
library(dplyr)
library(rjson)
library(tidyr)
library(rlist)
library(readr)
library(stringr)
library(parallel)
library(data.table)

fl <- list.files(path = "/Users/zijiangred/changjiang/dataset/inputdata")
fl <- fl[str_detect(fl,"json")]
key_tf_part <- read_csv(file="/Users/zijiangred/changjiang/dataset/part/kw_tf_part.csv")
key_tf_global <- read_csv(file="/Users/zijiangred/changjiang/dataset/global/kw_tf.csv")

keyword <- function(j){
    i = str_split(fl[j],'\\.')
    i <- unlist(i)[1]
    i = str_split(i,'\\_')
    i <- unlist(i)[2]
    data <- fromJSON(file=paste0("/Users/zijiangred/changjiang/dataset/inputdata/",fl[j]),simplify=T)
    pairorder_orig <- h5read(file=(paste0("/Users/zijiangred/changjiang/dataset/pairorder/",i,"_pair.h5")),name="pair")
    papers <- data$papers
    keyword <- list.map(papers,Keywords)
    tmp <- unlist(keyword)
    tmp1 <- tmp[str_detect(tmp,";")]
    tmp2 <- tmp[!str_detect(tmp,";")]
    tmp3 <- unlist(lapply(tmp1,function(x) str_split(x,";")))
    keyword <- tolower(c(tmp2,tmp3))
    keywords <- setDT(as.data.frame(keyword), keep.rownames = 'ut')[]
    keywords$keyword <- tolower(str_trim(keywords$keyword))
    keywords$ut<-str_sub(keywords$ut,1,19)
    keywords<-keywords %>% filter(keyword!='na')
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
    write.csv(pairorder,file=paste0("/Users/zijiangred/changjiang/dataset/feature/keyword/kw_",i,".csv"), row.names = F)
    print(j)
}
lapply(1:length(fl),keyword)
    
