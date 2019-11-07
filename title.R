library(tm)
library(rhdf5)
library(dplyr)
library(rjson)
library(rlist)
library(tidyr)
library(readr)
library(stringr)
library(parallel)

fl <- list.files(path = "/Users/zijiangred/changjiang/dataset/inputdata")
fl <- fl[str_detect(fl,"json")]
#做停用词库与去停用词的title词库
titles<-c()
stopword<-function(){
    for (j in 1:length(fl)){
        data <- fromJSON(file=paste0("/Users/zijiangred/changjiang/dataset/inputdata/",fl[j]),simplify=T)
        papers<-data$papers
        title <- list.map(papers,Title)
        title <- unlist(title)
        titles <- c(titles,title)
        print(j)
    }
    titles<-titles[titles!='NA']
    titles<-str_trim(titles)
    titles<-str_to_lower(titles)
    titles<-str_replace_all(titles,'[:punct:]','')
    reuters <- VCorpus(VectorSource(titles))
    titles<-unlist(str_split(titles,' '))
    titles<-titles[titles!='']
    reuters <- tm_map(reuters, removeWords, stopwords("english"))
    title_stop <- unlist(reuters)
    title_stop<-unlist(str_split(title_stop,' '))
    title_stop<-title_stop[title_stop!='']
    stopword<-titles[!(titles%in%title_stop)]
    stopword<-unique(stopword)
    stopword<-data.frame(stopword)
    write.csv(stopword,file="/Users/zijiangred/changjiang/dataset/part/stopword.csv", row.names = F)
    tit_tb <- table(title_stop)
    tit_tf_part<-data.frame(unlist(tit_tb))
    names(tit_tf_part) <- c("term","frequency")
    tit_tf_part$term <- as.character(tit_tf_part$term)
    write.csv(tit_tf_part,file="/Users/zijiangred/changjiang/dataset/part/title_tf_part.csv", row.names = F)
    return(tit_tf_part)
}

tit_tf_part<-stopword()

####################################################################
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
fl <- list.files(path =  "/Users/zijiangred/changjiang/dataset/inputdata")
fl <- fl[str_detect(fl,"json")]
tit_tf_part <- read_csv(file= "/Users/zijiangred/changjiang/dataset/part/title_tf_part.csv")
tit_tf_global <- read_csv(file="/Users/zijiangred/changjiang/dataset/feature/tit_tf_global.csv")
tit_stopword<-read_csv(file="/Users/zijiangred/changjiang/dataset/part/stopword.csv")

title <- function(j){
    i = str_split(fl[j],'\\.')
    i <- unlist(i)[1]
    i = str_split(i,'\\_')
    i <- unlist(i)[2]
    data <- fromJSON(file=paste0("/Users/zijiangred/changjiang/dataset/inputdata/",fl[j]),simplify=T)
    pairorder_orig <- h5read(file=(paste0("/Users/zijiangred/changjiang/dataset/pairorder/",i,"_pair.h5")),name="pair")
    papers <- data$papers
    title <- list.map(papers,Title)
    title <- unlist(title)
    title <- unlist(lapply(title,function(x) str_split(x," ")))
    titles <- setDT(as.data.frame(title), keep.rownames = 'ut')[]
    titles$title<-tolower(str_trim(titles$title))
    titles$title<-str_replace_all(titles$title,'[:punct:]','')
    titles <- filter(titles,title!='na')
    titles <- filter(titles,!(title%in%tit_stopword$stopword))
    titles<-filter(titles,title!='') 
    titles$ut<-str_sub(titles$ut,1,19)
    pairorder <- pairorder_orig
    A <- inner_join(pairorder,titles,by=c('paperA'='ut'))
    colnames(A) <- c("paperA","paperB","titlesA")
    B <- inner_join(pairorder,titles,by=c('paperB'='ut'))
    colnames(B) <- c("paperA","paperB","titlesB")
    titles_inner<-inner_join(A,B,by=c('paperA'='paperA','paperB'='paperB','titlesA'='titlesB'))
    titles_inner<-distinct(titles_inner)
    if(nrow(titles_inner)==0){
        pairorder$title1 <- 0
        pairorder$title2 <- 0
        pairorder$title3 <- 0
    }else{
        titles_inner <- left_join(titles_inner,tit_tf_global,by=c('titlesA'='term'))
        colnames(titles_inner) <- c("paperA","paperB","titlesA",'fre_global')
        titles_inner <- left_join(titles_inner,tit_tf_part,by=c('titlesA'='term'))
        colnames(titles_inner) <- c("paperA","paperB","titlesA",'fre_global','fre_part')
        total_global = sum(tit_tf_global$frequency)
        total_part = sum(tit_tf_part$frequency)
        titles_inner <- mutate(titles_inner,idf_part=log(total_part/fre_part))
        titles_inner <- mutate(titles_inner,idf_global=log(total_global/fre_global))
        titles_inner <- titles_inner%>%group_by(paperA,paperB)%>%summarise(title2=sum(idf_part),title3=sum(idf_global))
        titles_inner$title1<-0
        for(h in 1:dim(titles_inner)[1]){
            titlesA <- titles %>% filter(ut==titles_inner$paperA[h])%>%select(title)
            titlesB <- titles %>% filter(ut==titles_inner$paperB[h])%>%select(title)
            A_B <- length(intersect(titlesA,titlesB))
            A__B <- length(union(titlesA,titlesB))
            titles_inner$title1[h]<-A_B/A__B
        }
        pairorder <- left_join(pairorder,titles_inner,by=c('paperA'='paperA','paperB'='paperB'))
    }
    pairorder <- pairorder %>%
        arrange(match(paperA,pairorder_orig$paperA),
                match(paperB,pairorder_orig$paperB))
    pairorder <- pairorder%>%select(paperA,paperB,title1,title2,title3)
    pairorder[is.na(pairorder)] <- 0
    write.csv(pairorder,file=paste0("/Users/zijiangred/changjiang/dataset/feature/title/title_",i,".csv"), row.names = F)
    print(j)
}
lapply(1:length(fl),title)