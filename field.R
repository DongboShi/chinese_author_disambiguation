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
fie_corpus <- c()
field_corpus <- function(){
    for (j in 1:length(file)){
        i = str_split(file[j],'\\.')
        i <- unlist(i)[1]
        i = str_split(i,'\\_')
        i <- unlist(i)[2]
        data <- fromJSON(file=paste0('./data/',file[j]),simplify=T)
        for (h in 1:length(data$papers)){
            field <- str_to_lower(data$papers[[h]]$Field)
            field <- str_trim(field)
            fie_corpus <- c(fie_corpus,field)
        }
    }
    fie_corpus <- unlist(fie_corpus)
    fie_corpus <- fie_corpus[fie_corpus!='na']
    fie_tb <- table(fie_corpus)
    fie_tf_part<-data.frame(unlist(fie_tb))
    names(fie_tf_part) <- c("term","frequency")
    fie_tf_part$term <- as.character(fie_tf_part$term)
    write.csv(fie_tf_part,file="./part/fie_tf_part.csv", row.names = F)
    return(fie_tf_part)
}
fie_tf_part <- field_corpus()
fie_tf_global <- read_csv(file="./global/field_tf.csv")

field <- function(j){
    i = str_split(file[j],'\\.')
    i <- unlist(i)[1]
    i = str_split(i,'\\_')
    i <- unlist(i)[2]
    data <- fromJSON(file=paste0('./data/',file[j]),simplify=T)
    pairorder_orig <- h5read(file=(paste0('./pair/',i,"_pair.h5")),name="pair")
    #全局
    papers <- data$papers
    fields <- data.frame()
    for(k in 1:length(papers)){
        ut <- papers[[k]]$UT
        field <- str_to_lower(papers[[k]]$Field)
        field <- str_trim(field)
        result<-data.frame()
        if(length(field)>0){
            result <- data.frame(field,stringsAsFactors = F)
            names(result)<-c("fields")
            result$ut <- ut
        }
        fields <- rbind(fields,result)
        
    }
    fields <- filter(fields,fields!='na')
    pairorder <- pairorder_orig
    A <- inner_join(pairorder,fields,by=c('paperA'='ut'))
    colnames(A) <- c("paperA","paperB","fieldsA")
    B <- inner_join(pairorder,fields,by=c('paperB'='ut'))
    colnames(B) <- c("paperA","paperB","fieldsB")
    fields_inner <- inner_join(A,B,by=c('paperA'='paperA','paperB'='paperB','fieldsA'='fieldsB'))
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
    pairorder <- pairorder %>%
        arrange(match(paperA,pairorder_orig$paperA),
                match(paperB,pairorder_orig$paperB))
    pairorder[is.na(pairorder)] <- 0
    write.csv(pairorder,file=paste0("./feature/field_",i,".csv"), row.names = F)
    
}
lapply(1:length(file),field)
proc.time() - ptm
