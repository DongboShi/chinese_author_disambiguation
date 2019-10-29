library(rhdf5)
library(dplyr)
library(rjson)
library(tidyr)
library(rlist)
library(parallel)
setwd("/Users/Lenovo/Desktop/feature")
ref_single<-c()
ref_zong<-c()
for(t in c(1,5)){
  data <- fromJSON(file=paste0('CJ_t',".json"),simplify=T)
  papers<-data$papers
  for (n in 1:length(papers)){
    ref_single<-papers[[n]][["Reference"]][[1]]
    ref_zong<-c(ref_single,ref_zong)
  }
}

for(t in c(1,5)){
  pairorder_orig <- h5read(file=paste0(t,"_pair.h5"),name="pair")
  data <- fromJSON(file=paste0('CJ_t',".json"),simplify=T)
  papers<-data$papers
  pairorder <- pairorder_orig
  pairorder$ref1<-0
  pairorder$ref2<-0
  pairorder$ref3<-0
  paperA<-pairorder$paperA
  paperB<-pairorder$paperB
#ref1:pA ∩ RB + pB ∩ RA
  for(k in 1:dim(pairorder)[1]){
    idf_sum<-0
    paperB_k<-paperB[k]
    paperA_k<-paperA[k]
    paperB_ref<-data[["papers"]][[paperB_k]][["Reference"]][[1]]
    paperA_ref<-data[["papers"]][[paperA_k]][["Reference"]][[1]]
    if(paperA_k %in% paperB_ref){
      a=1     #如果A在B的Reference里，就记录1
    }else {
      a=0
    }
    if(paperB_k %in% paperA_ref){
      b=1    #如果B在A的Reference里，就记录1
    }else {
      b=0  
    }
    pairorder$ref1[k]<-a+b    #如果AB互在对方的reference里，就为2，只有一篇在，为1，都不在，为0
#ref2：RB ∩ RA    
    ref_jiao<-intersect(paperA_ref,paperB_ref)
    pairorder$ref2[k]<-length(ref_jiao)  
#ref3：∑logidf(R)局部idf    
    if(length(ref_jiao)==0){
      idf_sum<-0  #没有share的ref，直接记0
    }
    else{
      for(i in 1:length(ref_jiao)){
        count_i<-which(ref_zong==ref_jiao[i])
        idf_i<-log(length(ref_zong)/length(count_i))
        idf_sum<-idf_sum+idf_i
       }
    }
    pairorder$ref3[k]<-idf_sum
  }
  write.csv(pairorder,'sample.csv')
}

