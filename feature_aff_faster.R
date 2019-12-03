library(dplyr)
library(rjson)
library(rhdf5)
library(tidyr)
library(rlist)
library(stringr)
library(parallel)
library(readr)
library(data.table)

# /(ㄒoㄒ)/~~写文件名不要换行，路径会报错 

files <- list.files(path='/Users/zijiangred/changjiang/dataset/inputdata',pattern='CJ_')
id <- sort(as.numeric(str_extract(files,'[0-9]+')))

# part_Aff <- c()
# for (i in id){
#     data <- fromJSON(file=paste0("/Users/zijiangred/changjiang/dataset/inputdata/CJ_",i,".json"),simplify=T)
#     papers <- data$papers
#     Affiliations <- list.map(papers,Affiliations)
#     aff <- unlist(Affiliations)
#     part_Aff <- c(part_Aff,aff)
#     # save.image('/Users/zijiangred/changjiang/dataset/feature/part_Aff.RData')
#     print(i)
# }

# /Users/zijiangred/changjiang/dataset/feature
# make idf
# calculate the partial idf
# part_aff <- tolower(part_Aff)
# address1 <- str_trim(str_extract(part_aff,'[^,]+'))
# address2 <- str_trim(str_extract(part_aff,'((?<=,)[^,]+)'))
# address1[is.na(address1)] <- ''
# address1[address1=='na'] <- ''
# address2[is.na(address2)] <- ''
# address2[address2=='na'] <- ''
# part_aff1 <- as.data.frame(table(address1))
# colnames(part_aff1) <- c('org1','freq')
# part_aff1 <- mutate(part_aff1,part_idf_aff1 = log(sum(freq)/freq))
# write.csv(part_aff1,file='org1_idf.csv',row.names = F,na ='')

# org2 <- paste(address1,address2,sep=', ')
# part_aff2 <- as.data.frame(table(org2))
# colnames(part_aff2) <- c('org2','freq')
# part_aff2 <- mutate(part_aff2,part_idf_aff2 = log(sum(freq)/freq))
# write.csv(part_aff2,file='org2_idf.csv',row.names = F,na ='')

part_aff1 <- read_csv('/Users/zijiangred/changjiang/dataset/feature/org1_idf.csv')
part_aff2 <- read_csv('/Users/zijiangred/changjiang/dataset/feature/org2_idf.csv')

# calculate the global idf
# /Users/zijiangred/changjiang/dataset/global
# org1_tf <- read_csv('org1_tf.csv')
# org1_tf[is.na(org1_tf)==T]=''
# org1_tf[org1_tf=='na']=''
# GlobalAFF1 <- group_by(org1_tf,term) %>%
#     summarise(freq = sum(frequency))
# GlobalAFF1_sum <- sum(GlobalAFF1$freq)
# GlobalAFF1 <- mutate(GlobalAFF1,idf_aff1 = log(GlobalAFF1_sum/freq))
# colnames(GlobalAFF1) <- c('org1','freq','idf_aff1')

# org2_tf <- read_csv('org2_tf.csv')
# org2_tf <- mutate(org2_tf,address1 = str_trim(str_extract(term,'[^,]+'))) %>%
#     mutate(address2 = str_trim(str_extract(term,'((?<=,)[^,]+)')))
# org2_tf[is.na(org2_tf)==T]=''
# org2_tf[org2_tf=='na']=''
# org2_tf <- mutate(org2_tf,org2 = paste(address1,address2,sep=', '))
# GlobalAFF2 <- group_by(org2_tf,org2) %>%
#     summarise(freq = sum(frequency))
# GlobalAFF2_sum <- sum(GlobalAFF2$freq)
# GlobalAFF2 <- mutate(GlobalAFF2,idf_aff2 = log(GlobalAFF2_sum/freq))
# write.csv(GlobalAFF1,file='/Users/zijiangred/changjiang/dataset/feature/feature_Aff/GlobalAFF1.csv',row.names = F,na ='')
# write.csv(GlobalAFF2,file='/Users/zijiangred/changjiang/dataset/feature/GlobalAFF2.csv',row.names = F,na ='')
GlobalAFF1 <- read_csv('/Users/zijiangred/changjiang/dataset/feature/GlobalAFF1.csv')
GlobalAFF2 <- read_csv('/Users/zijiangred/changjiang/dataset/feature/GlobalAFF2.csv')

for (i in id[id>5]){
    # pairorder <- h5read(file=paste0("/Users/zijiangred/changjiang/dataset/pairorder/",i,"_pair.h5"),name="pair")
    data <- fromJSON(file=paste0("/Users/zijiangred/changjiang/dataset/inputdata/CJ_",i,".json"),simplify=T)
    papers <- data$papers
    paperut <- names(papers) 
    paperut1 <- paperut 
    pairorder <- crossing(paperut,paperut1) %>% 
        rename(paperA = paperut, paperB=paperut1) %>% 
        filter(paperA < paperB) 
    # All ut affliation
    Affiliations <- list.map(papers,Affiliations)
    aff <- unlist(Affiliations)
    AFF <- setDT(as.data.frame(aff), keep.rownames = 'ut') %>%
        mutate(ut = str_extract(ut,'WOS:\\S{15}'))  %>%
        mutate(aff = tolower(aff)) %>% 
        mutate(address1 = str_trim(str_extract(aff,'[^,]+(?=,)'))) %>%
        mutate(address2 = str_trim(str_extract(aff,'(?<=,)[^,]+')))
    AFF[AFF=='na'] <- '' 
    AFF[is.na(AFF)==T] <- ''
    AFF <- mutate(AFF,org1 = address1,org2 = paste(address1,address2,sep=', ')) %>% 
        select(-address1,-address2)
    AFF1 <- AFF %>%
        group_by(ut) %>%
        summarise(Org1=paste(org1,collapse='---'),Org2=paste(org2,collapse='---')) %>%
        mutate(Org1 = str_split(Org1,'---'),Org2 = str_split(Org2,'---')) 
    
    org1_count <- group_by(AFF,ut,org1) %>%
        count()
    AFF <- left_join(AFF,org1_count)
    colnames(AFF) <- c("ut","aff","org1","org2","org1_count")
    org2_count <- group_by(AFF,ut,org2) %>%
        count()
    AFF <- left_join(AFF,org2_count)
    colnames(AFF) <- c("ut","aff","org1","org2","org1_count","org2_count")
    
    ############################################################
    # calculate jaccard
    pairA <- left_join(pairorder,AFF1,by=c('paperA'='ut'))
    colnames(pairA) <- c('paperA','paperB','Org1_A','Org2_A')
    pairA_B <- left_join(pairA,AFF1,by=c('paperB'='ut'))
    colnames(pairA_B) <- c('paperA','paperB','Org1_A','Org2_A','Org1_B','Org2_B')
    org1_jiao <- Map(intersect, pairA_B$Org1_A, pairA_B$Org1_B)
    org1_bing <- Map(union, pairA_B$Org1_A, pairA_B$Org1_B)
    aff11 <- sapply(1:length(org1_jiao), function(x) length(org1_jiao[[x]])/length(org1_bing[[x]])) %>%
        as.data.frame()
    org2_jiao <- Map(intersect, pairA_B$Org2_A, pairA_B$Org2_B)
    org2_bing <- Map(union, pairA_B$Org2_A, pairA_B$Org2_B)
    aff12 <- sapply(1:length(org2_jiao), function(x) length(org2_jiao[[x]])/length(org2_bing[[x]])) %>%
        as.data.frame()
    pairA_B <- cbind(pairA_B,aff11,aff12)
    colnames(pairA_B) <- c("paperA","paperB","Org1_A","Org2_A","Org1_B","Org2_B","aff11","aff12")

    # match info on paper    
    AFF_idf1 <- select(left_join(AFF,part_aff1),-freq)
    AFF_idf2 <- select(left_join(AFF_idf1,part_aff2),-freq) 
    AFF_idf3 <- select(left_join(AFF_idf2,GlobalAFF1),-freq)
    AFF_idf <- select(left_join(AFF_idf3,GlobalAFF2),-freq)
    
    pairorder_org1A <- select(AFF_idf,ut,org1,org1_count,part_idf_aff1,idf_aff1)
    colnames(pairorder_org1A) <- c('paperA','org1','org1_countA','part_idf_aff1','idf_aff1')
    pairorder_org1B <- select(AFF_idf,ut,org1,org1_count)
    colnames(pairorder_org1B) <- c('paperB','org1','org1_countB')    
    pairorderA_pairorderB_intersectorg1 <- inner_join(pairorder_org1A,pairorder_org1B) %>% distinct() %>%
        filter(paperA<paperB)
    pairorderA_pairorderB_intersectorg1 <- mutate(pairorderA_pairorderB_intersectorg1,
                                                  org1_part_idf_aff1=part_idf_aff1*pmin(org1_countA,org1_countB),
                                                  org1_idf_aff1=idf_aff1*pmin(org1_countA,org1_countB))

    pairorder_org2A <- select(AFF_idf,ut,org2,org2_count,part_idf_aff2,idf_aff2)
    colnames(pairorder_org2A) <- c('paperA','org2','org2_countA','part_idf_aff2','idf_aff2')
    pairorder_org2B <- select(AFF_idf,ut,org2,org2_count)
    colnames(pairorder_org2B) <- c('paperB','org2','org2_countB')    
    pairorderA_pairorderB_intersectorg2 <- inner_join(pairorder_org2A,pairorder_org2B) %>% distinct() %>%
        filter(paperA<paperB)
    pairorderA_pairorderB_intersectorg2 <- mutate(pairorderA_pairorderB_intersectorg2,
                                                  org2_part_idf_aff2=part_idf_aff2*pmin(org2_countA,org2_countB),
                                                  org2_idf_aff2=idf_aff2*pmin(org2_countA,org2_countB))
    
    # min is wrong, use pmin :https://dennisphdblog.wordpress.com/2009/07/24/r-command-of-the-week-pmax-and-pmin/
    pairorder_org1 <- group_by(pairorderA_pairorderB_intersectorg1,paperA,paperB) %>%
        summarise(aff21 = sum(org1_part_idf_aff1),aff31 = sum(org1_idf_aff1))
    
    pairorder_org2 <- group_by(pairorderA_pairorderB_intersectorg2,paperA,paperB) %>%
        summarise(aff22 = sum(org2_part_idf_aff2),aff32 = sum(org2_idf_aff2))
    
    # pairorder_Aff1 <- left_join(pairorder,pairorder_org1)
    # pairorder_Aff2 <- left_join(pairorder,pairorder_org2)
    # pairorder_Aff <- left_join(pairorder_Aff1,pairorder_Aff2)
    # Feature_aff <- left_join(pairorder,pairA_B)
    # Feature_aff <- left_join(Feature_aff,pairorder_Aff)
    Feature_aff <-cbind(pairorder_org1,select(pairorder_org2,-paperA,-paperB),select(pairA_B,-paperA,-paperB))
    Feature_aff[is.na(Feature_aff)] <- 0
    Feature_aff <- select(Feature_aff,paperA,paperB,aff11,aff12,aff21,aff22,aff31,aff32)
    write.csv(Feature_aff,paste0('/Users/zijiangred/changjiang/dataset/Meng_feature/all_feature_aff/Feature_aff_',i,'.csv'),row.names=F,na ='')
    print(i)
}
# 
# x = 'AGH Univ Sci & Technol, Fac Phys & Appl Comp Sci, Krakow, Poland'
# str_sub(x,1,str_locate_all(x,",")[[1]][1,1]-1)

