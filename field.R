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
fie_corpus <- c()
field_corpus <- function(){
    for (j in 1:length(fl)){
        data <- fromJSON(file=paste0("/Users/zijiangred/changjiang/dataset/inputdata/",fl[j]),simplify=T)
        papers<-data$papers
        field <- list.map(papers,Field)
        tmp <- unlist(field)
        field <- str_to_lower(tmp)
        field <- str_trim(field)
        fie_corpus <- c(fie_corpus,field)
        print(j)
    }
    fie_corpus <- fie_corpus[fie_corpus!='na']
    fie_tb <- table(fie_corpus)
    fie_tf_part<-data.frame(unlist(fie_tb))
    names(fie_tf_part) <- c("term","frequency")
    fie_tf_part$term <- as.character(fie_tf_part$term)
    write.csv(fie_tf_part,file="/Users/zijiangred/changjiang/dataset/part/fie_tf_part.csv", row.names = F)
    return(fie_tf_part)
}

fie_tf_part <- field_corpus()
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
fie_tf_part <- read_csv(file="/Users/zijiangred/changjiang/dataset/part/fie_tf_part.csv")
fie_tf_global <- read_csv(file="/Users/zijiangred/changjiang/dataset/global/field_tf.csv")

field <- function(j){
    i = str_split(fl[j],'\\.')
    i <- unlist(i)[1]
    i = str_split(i,'\\_')
    i <- unlist(i)[2]
    data <- fromJSON(file=paste0("/Users/zijiangred/changjiang/dataset/inputdata/",fl[j]),simplify=T)
    pairorder_orig <- h5read(file=(paste0("/Users/zijiangred/changjiang/dataset/pairorder/",i,"_pair.h5")),name="pair")
    papers <- data$papers
    field <- list.map(papers,Field)
    field <- unlist(field)
    fields <- setDT(as.data.frame(field), keep.rownames = 'ut')[]
    fields$field <- tolower(str_trim(fields$field))
    fields$ut<-str_sub(fields$ut,1,19)
    fields<-fields %>% filter(field!='na')
    pairorder <- pairorder_orig
    A <- inner_join(pairorder,fields,by=c('paperA'='ut'))
    colnames(A) <- c("paperA","paperB","fieldsA")
    B <- inner_join(pairorder,fields,by=c('paperB'='ut'))
    colnames(B) <- c("paperA","paperB","fieldsB")
    fields_inner <- inner_join(A,B,by=c('paperA'='paperA','paperB'='paperB','fieldsA'='fieldsB'))
    if(nrow(fields_inner)==0){
        pairorder$field1 <- 0
        pairorder$field2 <- 0
        pairorder$field3 <- 0
    }else{
        fields_inner <- left_join(fields_inner,fie_tf_global,by=c('fieldsA'='term'))
        colnames(fields_inner) <- c("paperA","paperB","fieldsA",'fre_global')
        fields_inner <- left_join(fields_inner,fie_tf_part,by=c('fieldsA'='term'))
        colnames(fields_inner) <- c("paperA","paperB","fieldsA",'fre_global','fre_part')
        total_global = sum(fie_tf_global$frequency)
        total_part = sum(fie_tf_part$frequency)
        fields_inner <- mutate(fields_inner,idf_part=log(total_part/fre_part))
        fields_inner <- mutate(fields_inner,idf_global=log(total_global/fre_global))
        fields_inner <- fields_inner%>%group_by(paperA,paperB)%>%summarise(field1=n(),field2=sum(idf_part),field3=sum(idf_global))
        pairorder <- left_join(pairorder,fields_inner,by=c('paperA'='paperA','paperB'='paperB'))
    }
    pairorder <- pairorder %>%
        arrange(match(paperA,pairorder_orig$paperA),
                match(paperB,pairorder_orig$paperB))
    pairorder[is.na(pairorder)] <- 0
    write.csv(pairorder,file=paste0("/Users/zijiangred/changjiang/dataset/feature/field/field_",i,".csv"),row.names = F)
    print(j)
}
lapply(1:length(fl),field)
