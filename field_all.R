library(dplyr)
library(rjson)
library(tidyr)
library(rlist)
library(readr)
library(stringr)
library(parallel)
library(data.table)

fl <- list.files(path = "/home/stonebird/cad/inputdata")
fl <- fl[str_detect(fl,"json")]


fie_tf_part <- read_csv(file="/home/stonebird/cad/fie_tf_part.csv")
fie_tf_global <- read_csv(file="/home/stonebird/cad/field_tf.csv")

field <- function(j){
    i <- str_split(fl[j],'\\.')
    i <- unlist(i)[1]
    i <- str_split(i,'\\_')
    i <- unlist(i)[2]
    data <- fromJSON(file=paste0("/home/stonebird/cad/inputdata/",fl[j]),simplify=T)
    papers <- data$papers
    paperut <- names(papers)
    paperut1 <- paperut
    pairorder <- crossing(paperut,paperut1) %>%
        rename(paperA = paperut, paperB=paperut1) %>%
        filter(paperA < paperB)
    # 放在这个地方不动
    # 制造features
    field <- list.map(papers,Field)
    field <- unlist(field)
    fields <- setDT(as.data.frame(field), keep.rownames = 'ut')[]
    fields$field <- tolower(str_trim(fields$field))
    fields$ut <-str_sub(fields$ut,1,19)
    fields <- fields %>% filter(field!='na') %>% rename(utA = ut)
    fields2 <- fields %>% rename(utB = utA)
    fieldspair <- inner_join(fields, fields2, by = "field") %>% filter(utA < utB)
    fieldspair <- left_join(fieldspair,fie_tf_global,by=c('field'='term'))
    names(fieldspair) <- c("paperA","paperB","field",'fre_global')
    fieldspair <- left_join(fieldspair,fie_tf_part,by=c('field'='term'))
    colnames(fieldspair) <- c("paperA","paperB","fields",'fre_global','fre_part')
    total_global <- sum(fie_tf_global$frequency)
    total_part <- sum(fie_tf_part$frequency)
    fieldspair_final <- fieldspair %>%
                  mutate(idf_part=log(total_part/fre_part),
                         idf_global=log(total_global/fre_global)) %>%
                  group_by(paperA, paperB) %>%
                  summarise(field1=n(),field2=sum(idf_part),field3=sum(idf_global))
    #合并pairorder
    pairorder <- left_join(pairorder, fieldspair_final, by = c("paperA","paperB")) %>%
                 mutate(field1 = if_else(is.na(field1), 0, field1),
                        field2 = if_else(is.na(field2), 0, field2),
                        field3 = if_else(is.na(field3), 0, field3))

    write.csv(pairorder,file=paste0("/home/stonebird/cad/feature/field_full/field_",i,".csv"),row.names = F)
    print(paste0(j,'-',i))
}
lapply(40:length(fl),field)
