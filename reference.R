library(dplyr)
library(rjson)
library(rhdf5)
library(stringr)
library(tidyr)
library(rlist)
library(parallel)
files <- list.files(path='/Users/zijiangred/changjiang/dataset/inputdata',pattern='CJ_')
id <- sort(as.numeric(str_extract(files,'[0-9]+')))
Reference <- c()
for (i in id){
  data <- fromJSON(file=paste0("/Users/zijiangred/changjiang/dataset/inputdata/CJ_",i,".json"),simplify=T)
  papers <- data$papers
  reference <- c()
  for(k in 1:length(papers)){
    ref <- data[["papers"]][[k]]$Reference[[1]]
    reference <- c(reference,ref)
  }
  Reference<-c(Reference,reference) 
}
#计算每个ref的log idf
part_ref3 <- as.data.frame(table(unlist(Reference)))
colnames(part_ref3) <- c('ref','freq')
part_ref3 <- mutate(part_ref3,part_idf_ref = log(sum(freq)/freq))

for (i in id){
  pairorder <- h5read(file=paste0("/Users/zijiangred/changjiang/dataset/pairorder/",i,"_pair.h5"),name="pair")
  data <- fromJSON(file=paste0("/Users/zijiangred/changjiang/dataset/inputdata/CJ_",i,".json"),simplify=T)
  papers <- data$papers
  ref_1 <- data.frame()
  for(k in 1:length(papers)){
    ut <- papers[[k]]$UT
    ref <- data[["papers"]][[k]]$Reference[[1]]
    result<-data.frame()
    if(length(ref)>0){
      result <- data.frame(ut,stringsAsFactors = F)
      result$ref <- list(ref)
    }
    ref_1 <- rbind(ref_1,result)
  }  
  Ref <- unnest(ref_1,ref)
  
  #计算一对pair相交的ref数量
  pairorderA <- left_join(pairorder,Ref,by=c('paperA'='ut'))
  pairorderB <- left_join(pairorder,Ref,by=c('paperB'='ut'))
  pairorderAB <- inner_join(pairorderA,pairorderB)
  pairorderAB <- select(left_join(pairorderAB,part_ref3),-freq)
  pairorderAB <- group_by(pairorderAB,paperA,paperB) %>%
    mutate(ref2=n())
 
  #计算sum log idf
  feature <- group_by(pairorderAB,paperA,paperB) %>%
  mutate(ref3=sum(part_idf_ref)) %>%
  select(-ref,-part_idf_ref) %>%
  distinct()
  
  Feature <- left_join(pairorder,feature)
  Feature[is.na(Feature)] <- 0
  
  #计算第一个feature，A在B的ref里，记1，B在A的ref里，也记1，加和
  paperAinB <- mutate(pairorderB,AinB=ifelse(paperA==ref,1,0))
  paperAinB[is.na(paperAinB)] <-0
  paperAinB <-group_by(paperAinB,paperA,paperB) %>%
    mutate(part_ref1=sum(AinB)) %>%
    select(-ref,-AinB) %>%
    distinct()

  paperBinA <- mutate(pairorderA,BinA=ifelse(paperB==ref,1,0)) 
  paperBinA[is.na(paperBinA)] <-0
  paperBinA <-group_by(paperBinA,paperA,paperB) %>%
    mutate(part_ref2=sum(BinA)) %>%
    select(-ref,-BinA) %>%
    distinct()

  feature2 <- inner_join(paperAinB,paperBinA) %>%
    mutate(ref1=part_ref1+part_ref2) %>%
    select(-part_ref1,-part_ref2) %>%
    distinct()

  Ref_feature <- full_join(feature2,Feature)

  write.csv(Ref_feature,file=paste0('/Users/zijiangred/changjiang/dataset/feature/Feature_ref/feature_ref_',i,'.csv'),row.names=F,na='')  
  print(i) 
}
