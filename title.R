ptm<-proc.time()
library(tm)
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
#做停用词库与去停用词的title词库
titles<-c()
stopword<-function(){
    for (j in 1:length(file)){
        i = str_split(file[j],'\\.')
        i <- unlist(i)[1]
        i = str_split(i,'\\_')
        i <- unlist(i)[2]
        data <- fromJSON(file=paste0('./data/',file[j]),simplify=T)
        for (h in 1:length(data$papers)){
            title <- data$papers[[h]]$Title
            if(title != 'NA'){
                titles <- c(titles,title)
            }
        }
    }
    titles<-str_trim(titles)
    titles<-str_to_lower(titles)
    titles<-str_replace_all(titles,'[:punct:]','')
    reuters <- VCorpus(VectorSource(titles))
    titles<-unlist(str_split(titles,' '))
    titles<-titles[titles!='']
    reuters <- tm_map(reuters, removeWords, stopwords("english"))
    title_stop <- c()
    for (k in 1:length(reuters)) {
        title_stop<-c(title_stop,reuters[[k]][["content"]])
    }
    title_stop<-unlist(str_split(title_stop,' '))
    title_stop<-title_stop[title_stop!='']
    stopword<-titles[!(titles%in%title_stop)]
    stopword<-unique(stopword)
    stopword<-data.frame(stopword)
    write.csv(stopword,file="./part/stopword.csv", row.names = F)
    tit_tb <- table(title_stop)
    tit_tf_part<-data.frame(unlist(tit_tb))
    names(tit_tf_part) <- c("term","frequency")
    tit_tf_part$term <- as.character(tit_tf_part$term)
    write.csv(tit_tf_part,file="./part/title_tf_part.csv", row.names = F)
    return(tit_tf_part)
}

tit_tf_part<-stopword()
tit_tf_global <- read_csv(file="./global/title_tf.csv")
tit_stopword<-read_csv(file="./part/stopword.csv")

title <- function(j){
    i = str_split(file[j],'\\.')
    i <- unlist(i)[1]
    i = str_split(i,'\\_')
    i <- unlist(i)[2]
    data <- fromJSON(file=paste0('./data/',file[j]),simplify=T)
    pairorder_orig <- h5read(file=(paste0('./pair/',i,"_pair.h5")),name="pair")
    papers <- data$papers
    titles <- data.frame()
    for(k in 1:length(papers)){
        ut <- papers[[k]]$UT
        title <- str_to_lower(papers[[k]]$Title)
        title<-str_replace_all(title,'[:punct:]','')
        title <- str_split(title,' ')
        title <- unlist(title)
        title <- str_trim(title)
        result<-data.frame()
        if(length(title)>0){
            result <- data.frame(title,stringsAsFactors = F)
            names(result)<-c("titles")
            result$ut <- ut
        }
        titles <- rbind(titles,result)
        
    }
    titles <- filter(titles,titles!='na')
    titles <- filter(titles,!(titles%in%tit_stopword$stopword))
    pairorder <- pairorder_orig
    A <- inner_join(pairorder,titles,by=c('paperA'='ut'))
    colnames(A) <- c("paperA","paperB","titlesA")
    B <- inner_join(pairorder,titles,by=c('paperB'='ut'))
    colnames(B) <- c("paperA","paperB","titlesB")
    titles_inner <- inner_join(A,B,by=c('paperA'='paperA','paperB'='paperB','titlesA'='titlesB'))
    titles_inner <- left_join(titles_inner,tit_tf_global,by=c('titlesA'='term'))
    colnames(titles_inner) <- c("paperA","paperB","titlesA",'fre_global')
    titles_inner <- left_join(titles_inner,tit_tf_part,by=c('titlesA'='term'))
    colnames(titles_inner) <- c("paperA","paperB","titlesA",'fre_global','fre_part')
    total_global = sum(tit_tf_global$frequency)
    total_part = sum(tit_tf_part$frequency)
    titles_inner <- mutate(titles_inner,idf_part=log(total_part/fre_part))
    titles_inner <- mutate(titles_inner,idf_global=log(total_global/fre_global))
    titles_inner <- titles_inner%>%group_by(paperA,paperB)%>%summarise(A_B=n(),title2=sum(idf_part),title3=sum(idf_global))
    titles_inner$A__B <- 0
    for(h in 1:dim(titles_inner)[1]){
        titlesA <- titles %>% filter(ut==titles_inner$paperA[h])%>%select(titles)
        titlesB <- titles %>% filter(ut==titles_inner$paperB[h])%>%select(titles)
        A__B <- length(union(titlesA,titlesB))
        titles_inner$A__B[h]<-A__B
    }
    titles_inner <- mutate(titles_inner,title1=A_B/A__B)
    pairorder <- left_join(pairorder,titles_inner,by=c('paperA'='paperA','paperB'='paperB'))
    pairorder <- pairorder %>%
        arrange(match(paperA,pairorder_orig$paperA),
                match(paperB,pairorder_orig$paperB))
    pairorder[is.na(pairorder)] <- 0
    pairorder <- pairorder%>%select(paperA,paperB,title1,title2,title3)
    write.csv(pairorder,file=paste0("./feature/title_",i,".csv"), row.names = F)
}
lapply(1:length(file),title)
proc.time() - ptm
