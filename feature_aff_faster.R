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

# files <- list.files(path='/home/stonebird/cad/inputdata',pattern='CJ_')
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

# part_aff1 <- read_csv('/home/stonebird/cad/org1_idf.csv')
# part_aff2 <- read_csv('/home/stonebird/cad/org2_idf.csv')
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
# write.csv(GlobalAFF2,file='/Users/zijiangred/changjianghtop/dataset/feature/GlobalAFF2.csv',row.names = F,na ='')
# GlobalAFF1 <- read_csv('/home/stonebird/cad/GlobalAFF1.csv')
# GlobalAFF2 <- read_csv('/home/stonebird/cad/GlobalAFF2.csv')

GlobalAFF1 <- read_csv('/Users/zijiangred/changjiang/dataset/feature/GlobalAFF1.csv')
GlobalAFF2 <- read_csv('/Users/zijiangred/changjiang/dataset/feature/GlobalAFF2.csv')

for (i in id){
    # pairorder <- h5read(file=paste0("/Users/zijiangred/changjiang/dataset/pairorder/",i,"_pair.h5"),name="pair")
    # data <- fromJSON(file=paste0("/home/stonebird/cad/inputdata/CJ_",i,".json"),simplify=T)
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
        select(-address1,-address2,-aff)
    
    AFF <- add_count(AFF,ut,org1,name='org1_count')   
    AFF <- add_count(AFF,ut,org2,name='org2_count')   
    
    # AFF <- add_count(AFF,ut,name='org_count')   
    
    #  list交并算法过慢，舍弃
    # AFF1 <- AFF %>%
    #     group_by(ut) %>%
    #     summarise(Org1=paste(org1,collapse='---'),Org2=paste(org2,collapse='---')) %>%
    #     mutate(Org1 = str_split(Org1,'---'),Org2 = str_split(Org2,'---')) 
    # 
    
    rm(data)
    rm(papers)
    gc()
    ############################################################
    # calculate jaccard
    # pairA <- left_join(pairorder,AFF1,by=c('paperA'='ut'))
    # colnames(pairA) <- c('paperA','paperB','Org1_A','Org2_A')
    # pairA_B <- left_join(pairA,AFF1,by=c('paperB'='ut'))
    # colnames(pairA_B) <- c('paperA','paperB','Org1_A','Org2_A','Org1_B','Org2_B')
    # org1_jiao <- Map(intersect, pairA_B$Org1_A, pairA_B$Org1_B)
    # org1_bing <- Map(union, pairA_B$Org1_A, pairA_B$Org1_B)
    # aff11 <- sapply(1:length(org1_jiao), function(x) length(org1_jiao[[x]])/length(org1_bing[[x]])) %>%
    #     as.data.frame()
    # org2_jiao <- Map(intersect, pairA_B$Org2_A, pairA_B$Org2_B)
    # org2_bing <- Map(union, pairA_B$Org2_A, pairA_B$Org2_B)
    # aff12 <- sapply(1:length(org2_jiao), function(x) length(org2_jiao[[x]])/length(org2_bing[[x]])) %>%
    #     as.data.frame()
    # pairA_B <- cbind(pairA_B,aff11,aff12)
    # colnames(pairA_B) <- c("paperA","paperB","Org1_A","Org2_A","Org1_B","Org2_B","aff11","aff12")
    
    # Org1  
    AFF_org1 <- select(AFF,ut,org1,org1_count) %>%
        left_join(part_aff1) %>%
        select(-freq) %>%
        left_join(GlobalAFF1) %>%
        select(-freq) %>%
        distinct()
    AFF_org1 <- add_count(AFF_org1,ut,name='uni_org1_sum')
    
    pairorder_org1A <- AFF_org1
    colnames(pairorder_org1A) <- c('paperA','org1','org1_countA','part_idf_aff1','idf_aff1','uni_org1_sumA')
    pairorder_org1B <- select(AFF_org1,-part_idf_aff1,-idf_aff1)
    colnames(pairorder_org1B) <- c('paperB','org1','org1_countB','uni_org1_sumB')    
    pairorderA_pairorderB_intersectorg1 <- inner_join(pairorder_org1A,pairorder_org1B) %>%
        filter(paperA<paperB)
    pairorderA_pairorderB_intersectorg1 <-add_count(pairorderA_pairorderB_intersectorg1,paperA,paperB,name='intersect_count')
    # min is wrong, use pmin :https://dennisphdblog.wordpress.com/2009/07/24/r-command-of-the-week-pmax-and-pmin/
    pairorderA_pairorderB_intersectorg1 <- mutate(pairorderA_pairorderB_intersectorg1,
                                                  org1_part_idf_aff1=part_idf_aff1*pmin(org1_countA,org1_countB),
                                                  org1_idf_aff1=idf_aff1*pmin(org1_countA,org1_countB),
                                                  aff11 = intersect_count/(uni_org1_sumA+uni_org1_sumB-intersect_count))
    rm(pairorderA_pairorderB_intersectorg1)
    gc()
    # 实际上分组后aff11是一样的，min(aff11)只是为了能取出来
    pairorder_org1 <- group_by(pairorderA_pairorderB_intersectorg1,paperA,paperB) %>%
        summarise(aff11 = min(aff11),aff21 = sum(org1_part_idf_aff1),aff31 = sum(org1_idf_aff1))
    
    # Org2  
    AFF_org2 <- select(AFF,ut,org2,org2_count) %>%
        left_join(part_aff2) %>%
        select(-freq) %>%
        left_join(GlobalAFF2) %>%
        select(-freq) %>%
        distinct()
    AFF_org2 <- add_count(AFF_org2,ut,name='uni_org2_sum')
    
    pairorder_org2A <- AFF_org2
    colnames(pairorder_org2A) <- c('paperA','org2','org2_countA','part_idf_aff2','idf_aff2','uni_org2_sumA')
    pairorder_org2B <- select(AFF_org2,-part_idf_aff2,-idf_aff2)
    colnames(pairorder_org2B) <- c('paperB','org2','org2_countB','uni_org2_sumB')    
    pairorderA_pairorderB_intersectorg2 <- inner_join(pairorder_org2A,pairorder_org2B) %>%
        filter(paperA<paperB)
    pairorderA_pairorderB_intersectorg2 <-add_count(pairorderA_pairorderB_intersectorg2,paperA,paperB,name='intersect_count')
    # min is wrong, use pmin :https://dennisphdblog.wordpress.com/2009/07/24/r-command-of-the-week-pmax-and-pmin/
    pairorderA_pairorderB_intersectorg2 <- mutate(pairorderA_pairorderB_intersectorg2,
                                                  org2_part_idf_aff2=part_idf_aff2*pmin(org2_countA,org2_countB),
                                                  org2_idf_aff2=idf_aff2*pmin(org2_countA,org2_countB),
                                                  aff12 = intersect_count/(uni_org2_sumA+uni_org2_sumB-intersect_count))
    rm(pairorderA_pairorderB_intersectorg2)
    gc()
    # 实际上分组后aff11是一样的，min(aff11)只是为了能取出来
    pairorder_org2 <- group_by(pairorderA_pairorderB_intersectorg2,paperA,paperB) %>%
        summarise(aff12= min(aff12),aff22 = sum(org2_part_idf_aff2),aff32 = sum(org2_idf_aff2))
    WOS:000071005400018
    # 设定顺序
    pairorder_Aff1 <- left_join(pairorder,pairorder_org1)
    pairorder_Aff2 <- left_join(pairorder,pairorder_org2)
    
    # Feature_aff <-cbind(pairorder_Aff1,select(pairorder_Aff2,-paperA,-paperB),select(pairA_B,-paperA,-paperB))
    Feature_aff <-cbind(pairorder_Aff1,select(pairorder_Aff2,-paperA,-paperB))
    Feature_aff[is.na(Feature_aff)] <- 0
    # write.csv(Feature_aff,paste0('/home/stonebird/cad/feature/aff_full/Feature_aff_',i,'.csv'),row.names=F,na ='')
    write.csv(Feature_aff,file=paste0('/Users/zijiangred/changjiang/dataset/Meng_feature/all_feature_aff/Feature_aff_',i,'.csv'),row.names = F,na ='')
    print(i)
}
# 
# x = 'AGH Univ Sci & Technol, Fac Phys & Appl Comp Sci, Krakow, Poland'
# str_sub(x,1,str_locate_all(x,",")[[1]][1,1]-1)