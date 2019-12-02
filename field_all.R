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


fie_tf_part <- read_csv(file="/Users/zijiangred/changjiang/dataset/part/fie_tf_part.csv")
fie_tf_global <- read_csv(file="/Users/zijiangred/changjiang/dataset/global/field_tf.csv")

field <- function(j){
    i = str_split(fl[j],'\\.')
    i <- unlist(i)[1]
    i = str_split(i,'\\_')
    i <- unlist(i)[2]
    data <- fromJSON(file=paste0("/Users/zijiangred/changjiang/dataset/inputdata/",fl[j]),simplify=T)
    papers <- data$papers
    paperut <- names(papers)
    paperut1 <- paperut
    pairorder <- crossing(paperut,paperut1) %>%
        rename(paperA = paperut, paperB=paperut1) %>%
        filter(paperA < paperB)
    field <- list.map(papers,Field)
    field <- unlist(field)
    fields <- setDT(as.data.frame(field), keep.rownames = 'ut')[]
    fields$field <- tolower(str_trim(fields$field))
    fields$ut<-str_sub(fields$ut,1,19)
    fields<-fields %>% filter(field!='na')
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
    pairorder[is.na(pairorder)] <- 0
    write.csv(pairorder,file=paste0("/Users/zijiangred/changjiang/dataset/feature/field_all/field_",i,".csv"),row.names = F)
    print(paste0(j,'-',i))
}
lapply(1:length(fl),field)
