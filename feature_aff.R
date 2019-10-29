library(dplyr)
library(rjson)
library(rhdf5)
library(tidyr)
library(rlist)
library(stringr)
library(parallel)
library(readr)
# ptm <- proc.time()
rm(list=ls())
setwd("D:/")
# setwd("/Users/birdstone/Documents/Data")
# h5read(pair[c("paperA","paperB")],file=paste0("/Users/zijiangred/changjiang/dataset/pairorder/",
#                                               i,"_pair.h5"),name="pair")
i = 1
pairorder <- h5read(file=paste0(i,"_pair.h5"),name="pair")
# data <- fromJSON(file=paste0("/Users/zijiangred/changjiang/dataset/inputdata/",i,".json"),simplify=T)
i=1
data <- fromJSON(file=paste0("CJ_",i,".json"),simplify=T)
papers <- data$papers
# All ut affliation
aff <- data.frame()
for(k in 1:length(papers)){
    ut <- papers[[k]]$UT
    afflication <- data[["papers"]][[k]]$Affiliations[[1]]
    result<-data.frame()
    if(length(afflication)>0){
        result <- data.frame(ut,stringsAsFactors = F)
        result$aff <- list(data[["papers"]][[k]]$Affiliations[[1]])
    }
    aff <- rbind(aff,result)
}

AFF <- unnest(aff,aff) %>%
        mutate(org1 = str_extract(aff,'[^,]+(?=,)')) %>%
        mutate(org2 = str_extract(aff,'([^,]+,[^,]+)(?=,)'))
pairorderAB_length <- count(AFF,ut)
colnames(pairorderAB_length) <- c('ut',"num")

AFF <- left_join(AFF,pairorderAB_length)

# feature_aff11 <- select(pairorder,paperA,paperB,Aorg1,Borg1)
# for(i in 1:dim(pairorder)[1]){
#     feature_aff11$aff11[i] <- length(intersect(feature_aff11$Aorg1[[i]],feature_aff11$Borg1[[i]]))/length(union(feature_aff11$Aorg1[[i]],feature_aff11$Borg1[[i]]))
# }
# 
# feature_aff12 <- select(pairorder,paperA,paperB,Aorg2,Borg2)
# for(i in 1:dim(pairorder)[1]){
#     feature_aff12$aff12[i] <- length(intersect(feature_aff12$Aorg2[[i]],feature_aff12$Borg2[[i]]))/length(union(feature_aff12$Aorg2[[i]],feature_aff12$Borg2[[i]]))
# }

############################################################
# make idf
# calculate the partial idf
part_aff1 <- count(AFF,org1) %>%
    mutate(part_idf_aff1 = log(nrow(AFF)/(n+1)))

part_aff2 <- count(AFF,org2) %>%
    mutate(part_idf_aff2 = log(nrow(AFF)/(n+1)))

# calculate the global idf
GlobalAFF1 <- read_csv('org1_tf.csv')
GlobalAFF1_sum <- sum(GlobalAFF1$frequency)
GlobalAFF1 <- mutate(GlobalAFF1,idf_aff1 = log(GlobalAFF1_sum/frequency))
GlobalAFF2 <- read_csv('org2_tf.csv') #read.csv 太慢了
GlobalAFF2_sum <- sum(GlobalAFF2$frequency)
GlobalAFF2 <- mutate(GlobalAFF2,idf_aff2 = log(GlobalAFF2_sum/frequency))

pairorderA <- left_join(pairorder,AFF,by=c('paperA'='ut'))
colnames(pairorderA) <- c("paperA","paperB","aff","org1","org2","numA")
pairorderB <- left_join(pairorder,AFF,by=c('paperB'='ut'))
colnames(pairorderB) <- c("paperA","paperB","aff","org1","org2","numB")

pairorderA_pairorderB_intersectorg1 <- inner_join(select(pairorderA,-aff,-org2),
                                                  select(pairorderB,-aff,-org2)) %>% distinct() 
pairorderA_pairorderB_intersectorg1 <- select(left_join(pairorderA_pairorderB_intersectorg1,part_aff1),-n)
pairorderA_pairorderB_intersectorg1 <- select(left_join(pairorderA_pairorderB_intersectorg1,
                                                        GlobalAFF1,by=c('org1'='term')),-frequency)

pairorderA_pairorderB_intersectorg2 <- inner_join(select(pairorderA,-aff,-org1),
                                                  select(pairorderB,-aff,-org1)) %>% distinct() 
pairorderA_pairorderB_intersectorg2 <- select(left_join(pairorderA_pairorderB_intersectorg2,part_aff2),-n)
pairorderA_pairorderB_intersectorg2 <- select(left_join(pairorderA_pairorderB_intersectorg2,
                                                        GlobalAFF2,by=c('org2'='term')),-frequency)

pairorder_idf1 <- group_by(pairorderA_pairorderB_intersectorg1,paperA,paperB) %>%
    summarise(aff21 = sum(part_idf_aff1),aff31 = sum(idf_aff1))

pairorder_idf2 <- group_by(pairorderA_pairorderB_intersectorg2,paperA,paperB) %>%
    summarise(aff22 = sum(part_idf_aff2),aff32 = sum(idf_aff2))

pairorder_Aff2 <- left_join(pairorder,pairorder_idf1)
pairorder_Aff3 <- left_join(pairorder,pairorder_idf2)

#######################
# make feature feature_aff11, feature_aff12

Affiliation <-  AFF %>%
    group_by(ut) %>%
    summarise(org1=paste(org1,collapse='---'),org2=paste(org2,collapse='---'))%>%
    mutate(org1=str_split(org1,"---"),org2=str_split(org2,"---"))
Affiliation <- left_join(Affiliation,pairorderAB_length)

pairorder <- left_join(pairorder,Affiliation,by=c('paperA'='ut'))
colnames(pairorder) <- c("paperA","paperB","Aorg1","Aorg2","numA")
pairorder <- left_join(pairorder,Affiliation,by=c('paperB'='ut'))
colnames(pairorder) <- c("paperA","paperB","Aorg1","Aorg2","numA","Borg1","Borg2","numB")

pairorderAB_intersectorg1_count <- group_by(pairorderA_pairorderB_intersectorg1,
                                            paperA,paperB) %>%count()
pairorder_Aff1 <- left_join(pairorder,pairorderAB_intersectorg1_count)
colnames(pairorder_Aff1) <- c("paperA","paperB","Aorg1","Aorg2","numA","Borg1","Borg2","numB","org1_count")
pairorderAB_intersectorg2_count <- group_by(pairorderA_pairorderB_intersectorg2,
                                            paperA,paperB) %>%count()
pairorder_Aff1 <- left_join(pairorder_Aff1,pairorderAB_intersectorg2_count)
colnames(pairorder_Aff1) <- c("paperA","paperB","Aorg1","Aorg2","numA","Borg1","Borg2","numB","org1_count","org2_count")

pairorder_Aff1[is.na(pairorder_Aff1)] <- 0
pairorder_Aff1 <- mutate(pairorder_Aff1,aff11=org1_count/(numA+numB),
                         aff12=org2_count/(numA+numB))
# all aff feature in dataframe  pairorder_Aff
pairorder_Aff <- cbind(select(pairorder_Aff1,paperA,paperB,Aorg1,Borg1,Aorg2,
                                  Borg2,numA,numB,org1_count,org2_count,
                                  aff11,aff12),
                       select(pairorder_Aff2,paperA,paperB,aff21,aff31),
                       select(pairorder_Aff3,paperA,paperB,aff22,aff32))

feature_aff11 <- select(pairorder_Aff1,paperA,paperB,aff11)
feature_aff12 <- select(pairorder_Aff1,paperA,paperB,aff12)


#调整feature的顺序使得其与原始的pair相一致
# pairorder <- pairorder %>%
#     arrange(match(paperA,pairorder_orig$paperA),
#             match(paperB,pairorder_orig$paperB))

