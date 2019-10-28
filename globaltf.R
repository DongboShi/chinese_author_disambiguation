library(RMySQL)
library(dplyr)
library(stringr)
con <- DBI::dbConnect(RMySQL::MySQL(),
                      dbname = "wos",
                      user = "root",
                      password = "zhulab2016",# hide the password
                      client.flag = CLIENT_MULTI_STATEMENTS)

itemtitle1 <- dbGetQuery(con,"select * from itemtitle;")
itemtitle2 <- dbGetQuery(con,"select ut,ti from thomson.sourceitems;")
#item2 <- dbGetQuery(con,"select ut_char,pub_year from thomson.item where pub_year >=2000")

# itemtitle2 <- itemtitle2 %>% 
#         filter(ut %in% item2$ut_char[item2$pub_year>=2000&item2$pub_year<=2008])
ti1 <- tolower(unlist(str_split(itemtitle1$ti,' ')))
ti2 <- tolower(unlist(str_split(itemtitle2$ti,' ')))
ti <- c(ti1,ti2)
ti_tb <- table(ti)
ti_tf<-data.frame(unlist(ti_tb))
names(ti_tf) <- c("term","frequency")
# title_tf <- read.csv("/Users/zijiangred/changjiang/dataset/global/title_tf.csv", stringsAsFactors = F)
# title_tf <- title_tf %>% 
#         mutate(term=tolower(term)) %>%
#         group_by(term) %>%
#         summarise(frequency = sum(frequency))
# ti_tf <- title_tf 
write.csv(ti_tf,file="/Users/zijiangred/changjiang/dataset/global/title_tf.csv", row.names = F)


rm(itemtitle1,itemtitle2,itemtitle2_1,ti1,ti2,ti,ti_tb,ti_tf)
#-----------------------------------------------------------
##affiliation
#------------------------------------------------------------
itemaff <- dbGetQuery(con,"select * from itemaffiliation;")
aff <- dbGetQuery(con,"select * from affiliation;")
itemaff2 <- dbGetQuery(con,"select * from thomson.itemaffiliation;")
aff2 <- dbGetQuery(con,"select * from affiliation;")
#itemaff2 <- itemaff2 %>% filter(ut %in% item2$ut_char[item2$pub_year>=2000&item2$pub_year<=2008])
itemaff <- inner_join(itemaff,aff[c("org1","org2","address_md5")],by="address_md5")
# itemaff2 <- itemaff2 %>% 
#         mutate(org1=unlist(lapply(address,function(x){str_sub(x,1,str_locate_all(x,",")[[1]][1,1]-1)})),
#                org2=unlist(lapply(address,function(x){str_sub(x,1,str_locate_all(x,",")[[1]][2,1]-1)})))
# 
itemaff <- itemaff %>% mutate(org2 = paste(org1,org2,sep = ", "))
itemaff <- itemaff %>% select(ut_char,org1,org2) %>% distinct()

itemaff2_0 <- itemaff2 %>% filter(str_count(address,",")==0)
itemaff2_1 <- itemaff2 %>% filter(str_count(address,",")==1)
itemaff2_2 <- itemaff2 %>% filter(str_count(address,",")>1)
tmp1 <- itemaff2_1 %>% 
        select(ut,address) %>%
        mutate(org1=tolower(unlist(lapply(address,function(x){str_sub(x,1,str_locate_all(x,",")[[1]][1,1]-1)}))),
               org2=tolower(org1))
tmp2 <- itemaff2_2 %>% 
        select(ut,address) %>%
        mutate(org1=tolower(unlist(lapply(address,function(x){str_sub(x,1,str_locate_all(x,",")[[1]][1,1]-1)}))),
               org2=tolower(unlist(lapply(address,function(x){str_sub(x,1,str_locate_all(x,",")[[1]][2,1]-1)}))))

org1 <- c(itemaff$org1,tmp1$org1,tmp2$org1)
org2 <- c(itemaff$org2,tmp1$org2,tmp2$org2)
org1_tf <- data.frame(unlist(table(org1)))
names(org1_tf) <- c("term","frequency")
write.csv(org1_tf,file="/Users/zijiangred/changjiang/dataset/global/org1_tf.csv",row.names = F)
org2_tf <- data.frame(unlist(table(org2)))
names(org2_tf) <- c("term","frequency")
write.csv(org2_tf,file="/Users/zijiangred/changjiang/dataset/global/org2_tf.csv",row.names = F)
rm(itemaff,aff,itemaff2,aff2,itemaff2_1,itemaff2_0,itemaff2_2,tmp1,tmp2,org1,org2,org1_tf,org2_tf)
gc()

# org1_tf <- read.csv("/Users/zijiangred/changjiang/dataset/global/org1_tf.csv",stringsAsFactors = F)
# org1_tf <- org1_tf %>% mutate(term=tolower(term)) %>%
#                  group_by(term) %>%
#                  summarise(frequency = sum(frequency))
# org2_tf <- read.csv("/Users/zijiangred/changjiang/dataset/global/org2_tf.csv",stringsAsFactors = F)
# org2_tf <- org2_tf %>% mutate(term=tolower(term)) %>%
#         group_by(term) %>%
#         summarise(frequency = sum(frequency))
#--------------------------------------------------------
###keywords
#---------------------------------------------------------
kw_origin <- dbGetQuery(con,"select ut_char, DE from wos_all limit 1;")
kw_origin <- data.frame()
getkw <- function(i){
        query<-paste("select ut_char, DE from wos_all where rid >=",i,"and rid <", i+10000,";")
        result <- dbGetQuery(con,query);#制造一个关键词的分布
        return(result)
} 
for(i in seq(10000001,18003656,10000)){
        tmp <- getkw(i)
        kw_origin <- rbind(kw_origin,tmp)
        print(i)
}
kw_origin <- kw_origin %>% filter(!is.na(DE))
insertkw <- function(i){
        result <- data.frame(str_trim(unlist(str_split(kw_origin$DE[i],";")),side ="both"))
        names(result) <- "de"
        result$de <- str_remove_all(result$de,'\\"|\\\\')
        result$ut_char <- kw_origin$ut_char[i]
        for(j in 1:dim(result)[1]){
                query<- paste0('insert into itemkeyword values("', result$ut_char[j], '","', result$de[j], '");')
                dbSendQuery(con,query)
        }
}
for(i in 1:dim(kw_origin)[1]){
        insertkw(i)
        print(i)}

kw <- dbGetQuery(con,"select * from itemkeyword;")
kw <- kw %>% distinct()
kw2 <- dbGetQuery(con,"select ut, de from thomson.sourceitem_des;")
kw2 <- kw2 %>% distinct()
names(kw2) <- c("ut_char","keyword")
#kw2 <- kw2 %>% filter(ut_char  %in% item2$ut_char[item2$pub_year>=2000&item2$pub_year<=2008])
kw<- rbind(kw,kw2) %>% mutate(keyword=tolower(keyword))
kw_tf <- data.frame(unlist(table(kw$keyword)))
names(kw_tf) <- c("term","frequency")
write.csv(kw_tf,file="/Users/zijiangred/changjiang/dataset/global/kw_tf.csv",row.names = F)

rm(kw,kw2,kw_tf )
#--------------------------------------------------------------
###field
#--------------------------------------------------------------
itemfield1 <- dbGetQuery(con,"select * from itemfield")
field1 <- dbGetQuery(con,"select * from field")
itemfield1 <- left_join(itemfield1,field1,by="field_id")
itemfield1 <- itemfield1 %>% distinct()

itemfield2 <- dbGetQuery(con,"select * from thomson.itemfield")
field2 <- dbGetQuery(con,"select * from thomson.field")
itemfield2 <- left_join(itemfield2,field2,by="field_id")
itemfield2 <- itemfield2 %>% distinct()

# itemfield2 <- itemfield2 %>% 
#         filter(ut_char %in% item2$ut_char[item2$pub_year>=2000&item2$pub_year<=2008])

field <- tolower(c(itemfield1$field,itemfield2$field))
field_tf <- data.frame(unlist(table(field)))
names(field_tf) <- c("term","frequency")
write.csv(field_tf,file="/Users/zijiangred/changjiang/dataset/global/field_tf.csv",row.names = F)
rm(itemfield1,field1,itemfield2,field2,field,field_tf)

#------------------------------------------------------------
### keword wide
#------------------------------------------------------------
#kw_wide_origin <- dbGetQuery(con,"select ut_char, ID from wos_all limit 1;")
kw_wide_origin <- data.frame()
getkw <- function(i){
        query<-paste("select ut_char, ID from wos_all where rid >=",i,"and rid <", i+10000,";")
        result <- dbGetQuery(con,query);#制造一个关键词的分布
        return(result)
}
#18003656
for(i in seq(10000001,18003656,10000)){
        tmp <- getkw(i)
        kw_wide_origin <- rbind(kw_wide_origin,tmp)
        print(i)
}
kw_wide_origin <- kw_wide_origin %>% filter(!is.na(ID))
save(kw_wide_origin,file="kw_wide_origin.RData")

insertkw <- function(i){
        result <- data.frame(str_trim(unlist(str_split(kw_wide_origin$ID[i],";")),side ="both"))
        names(result) <- "de"
        result$de <- str_remove_all(result$de,'\\"|\\\\')
        result$ut_char <- kw_wide_origin$ut_char[i]
        for(j in 1:dim(result)[1]){
                query<- paste0('insert into itemkeyword_wide values("', result$ut_char[j], '","', result$de[j], '");')
                dbSendQuery(con,query)
        }
}
for(i in 1:dim(kw_wide_origin)[1]){
        insertkw(i)
        print(i)}










