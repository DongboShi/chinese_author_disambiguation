library(dplyr)
library(rjson)
library(rhdf5)
library(tidyr)
library(rlist)
library(stringr)
library(parallel)
library(readr)
# rm(list=ls())
setwd('D:/0LLLab/chinese_author_disambiguation')
# setwd("/Users/birdstone/Documents/Data")
# h5read(pair[c("paperA","paperB")],file=paste0("/Users/zijiangred/changjiang/dataset/pairorder/",
#                                               i,"_pair.h5"),name="pair")

files <- list.files(pattern = "json")
part_Aff <- c()
for (i in 1:length(files)){
    data <- fromJSON(file=paste0("CJ_",i,".json"),simplify=T)
    papers <- data$papers
    aff <- c()
    for(k in 1:length(papers)){
        afflication <- data[["papers"]][[k]]$Affiliations[[1]]
        aff <- c(aff,afflication)
    }
    part_Aff <- c(part_Aff,aff)
}

# make idf
# calculate the partial idf
part_aff1 <- as.data.frame(table(str_extract(unlist(part_Aff),'[^,]+(?=,)')))
colnames(part_aff1) <- c('org1','freq')
part_aff1 <- mutate(part_aff1,part_idf_aff1 = log(sum(freq)/freq),org1=tolower(org1)) 
part_aff2 <- as.data.frame(table(str_extract(unlist(part_Aff),'([^,]+,[^,]+)(?=,)')))
colnames(part_aff2) <- c('org2','freq')
part_aff2 <- mutate(part_aff2,part_idf_aff2 = log(sum(freq)/freq),org2=tolower(org2)) 
# calculate the global idf
GlobalAFF1 <- read_csv('org1_tf.csv')
GlobalAFF1_sum <- sum(GlobalAFF1$frequency)
GlobalAFF1 <- mutate(GlobalAFF1,idf_aff1 = log(GlobalAFF1_sum/frequency))
GlobalAFF2 <- read_csv('org2_tf.csv') #read.csv 太慢了
GlobalAFF2_sum <- sum(GlobalAFF2$frequency)
GlobalAFF2 <- mutate(GlobalAFF2,idf_aff2 = log(GlobalAFF2_sum/frequency))


for (i in 1:length(files)){
    pairorder <- h5read(file=paste0(i,"_pair.h5"),name="pair")
    # data <- fromJSON(file=paste0("/Users/zijiangred/changjiang/dataset/inputdata/",i,".json"),simplify=T)
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
            mutate(aff = tolower(aff)) %>% 
            mutate(org1 = str_extract(aff,'[^,]+(?=,)')) %>%
            mutate(org2 = str_extract(aff,'([^,]+,[^,]+)(?=,)'))
    
    org1_count <- group_by(AFF,ut,org1) %>%
        count()
    AFF <- left_join(AFF,org1_count)
    colnames(AFF) <- c("ut","aff","org1","org2","org1_count")
    org2_count <- group_by(AFF,ut,org2) %>%
        count()
    AFF <- left_join(AFF,org2_count)
    colnames(AFF) <- c("ut","aff","org1","org2","org1_count","org2_count")
    
    ogr_length <- count(AFF,ut)
    colnames(ogr_length) <- c('ut',"org_count")
    
    AFF <- left_join(AFF,ogr_length)
    
    ############################################################

    # match info on paper
    pairorderA <- left_join(pairorder,AFF,by=c('paperA'='ut'))
    colnames(pairorderA) <- c("paperA","paperB","aff","org1","org2","org1_countA",
                              "org2_countA","org_countA")
    pairorderB <- left_join(pairorder,AFF,by=c('paperB'='ut'))
    colnames(pairorderB) <- c("paperA","paperB","aff","org1","org2","org1_countB",
                              "org2_countB","org_countB")
    
    pairorderA_pairorderB_intersectorg1 <- inner_join(select(pairorderA,-aff,-org2),
                                                      select(pairorderB,-aff,-org2)) %>% distinct() 
    pairorderA_pairorderB_intersectorg1 <- select(left_join(pairorderA_pairorderB_intersectorg1,
                                                            part_aff1),-freq,-org2_countA,-org2_countB)
    pairorderA_pairorderB_intersectorg1 <- select(left_join(pairorderA_pairorderB_intersectorg1,
                                                            GlobalAFF1,by=c('org1'='term')),-frequency)
    pairorderA_pairorderB_intersectorg1 <- mutate(pairorderA_pairorderB_intersectorg1,
                                                  org1_part_idf_aff1=part_idf_aff1*pmin(org1_countA,org1_countB),
                                                  org1_idf_aff1=idf_aff1*pmin(org1_countA,org1_countB),
                                                  org1_aff11 = pmin(org1_countA,org1_countB)/(org_countA+org_countB))
    
    pairorderA_pairorderB_intersectorg2 <- inner_join(select(pairorderA,-aff,-org1),
                                                      select(pairorderB,-aff,-org1)) %>% distinct() 
    pairorderA_pairorderB_intersectorg2 <- select(left_join(pairorderA_pairorderB_intersectorg2,
                                                            part_aff2),-freq,-org1_countA,-org1_countB)
    pairorderA_pairorderB_intersectorg2 <- select(left_join(pairorderA_pairorderB_intersectorg2,
                                                            GlobalAFF2,by=c('org2'='term')),-frequency)
    pairorderA_pairorderB_intersectorg2 <- mutate(pairorderA_pairorderB_intersectorg2,
                                                  org2_part_idf_aff2=part_idf_aff2*pmin(org2_countA,org2_countB),
                                                  org2_idf_aff2=idf_aff2*pmin(org2_countA,org2_countB),
                                                  org2_aff12 = pmin(org2_countA,org2_countB)/(org_countA+org_countB))
    
    # min is wrong, use pmin :https://dennisphdblog.wordpress.com/2009/07/24/r-command-of-the-week-pmax-and-pmin/
    pairorder_org1 <- group_by(pairorderA_pairorderB_intersectorg1,paperA,paperB) %>%
        summarise(aff11 = sum(org1_aff11),aff21 = sum(org1_part_idf_aff1),aff31 = sum(org1_idf_aff1))
    
    pairorder_org2 <- group_by(pairorderA_pairorderB_intersectorg2,paperA,paperB) %>%
        summarise(aff12 = sum(org2_aff12),aff22 = sum(org2_part_idf_aff2),aff32 = sum(org2_idf_aff2))
    
    
    pairorder_Aff <- left_join(pairorder_org1,pairorder_org2)
    Feature_aff <- left_join(pairorder,pairorder_Aff)
    Feature_aff[is.na(Feature_aff)] <- 0
    Feature_aff <- select(Feature_aff,paperA,paperB,aff11,aff12,aff21,aff22,aff31,aff32)
    write.csv(Feature_aff,paste0('Feature_aff_',i,'.csv'),row.names=F)
}

