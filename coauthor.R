library(dplyr)
library(rjson)
library(rhdf5)
library(tidyr)
library(rlist)
library(parallel)
rm(list=ls())
#setwd("/Users/zijiangred/changjiang/dataset/feature")
setwd("/Users/birdstone/Documents/Data")
# h5read(pair[c("paperA","paperB")],file=paste0("/Users/zijiangred/changjiang/dataset/pairorder/",
#                                               i,"_pair.h5"),name="pair")
pairorder_orig <- h5read(file=paste0(i,"_pair.h5"),name="pair")
# data <- fromJSON(file=paste0("/Users/zijiangred/changjiang/dataset/inputdata/",i,".json"),simplify=T)
data <- fromJSON(file=paste0(i,".json"),simplify=T)
papers <- data$papers
coauthors <- data.frame()
for(k in 1:length(papers)){
        ut <- papers[[k]]$UT
        ca <- papers[[k]]$Coauthor[[1]]
        result<-data.frame()
        if(length(ca)>0){
                result <- data.frame(ca,stringsAsFactors = F)
                names(result)<-"coauthor"
                result$ut <- ut
        }
        coauthors <- rbind(coauthors,result)
}
# 名字变形

coauthors <- coauthors %>% 
        mutate(familyname = str_sub(coauthor,1,str_locate(coauthor,",")[,1]-1),
               givenname = str_sub(coauthor,str_locate(coauthor,",")[,1]+1))
coauthors$familyname[is.na(coauthors$familyname)] <- 
        str_sub(coauthors$coauthor[is.na(coauthors$familyname)],1,str_locate(coauthors$coauthor[is.na(coauthors$familyname)]," ")[,1]-1)
coauthors$givenname[is.na(coauthors$givenname)] <- 
        str_sub(coauthors$coauthor[is.na(coauthors$givenname)],str_locate(coauthors$coauthor[is.na(coauthors$givenname)]," ")[,1]+1)

coauthors <- coauthors %>% 
        mutate(familyname = tolower(familyname),
               givenname = tolower(givenname),
               givenname = str_remove_all(givenname,"-|\\.|`| "),
               givennameshort = str_sub(givenname,1,1),
               fullname=paste(familyname,givenname,sep=","),
               fullnameshort=paste(familyname,givennameshort,sep=","))
pairorder <- pairorder_orig
pairorder$coauthor11<-0
pairorder$coauthor12<-0
pairorder$coauthor31<-0
pairorder$coauthor32<-0

for(i in 1:dim(pairorder)[1]){
        au1 <- coauthors %>% filter(ut==pairorder$paperA[i]) 
        au2 <- coauthors %>% filter(ut==pairorder$paperB[i])
        pairorder$coauthor11[i]<-sum(au1$fullname %in% au2$fullname)
        pairorder$coauthor12[i]<-sum(au1$fullnameshort %in% au2$fullnameshort)
        pairorder$coauthor11[is.na(pairorder$coauthor11)]<-0
        pairorder$coauthor12[is.na(pairorder$coauthor12)]<-0
        pairorder$coauthor31 <- pairorder$coauthor11/(length(au1)+length(au2))
        pairorder$coauthor32 <- pairorder$coauthor12/(length(au1)+length(au2))
        if(length(au1)==0 |length(au2)==0){
                pairorder$coauthor21 <- 0
                pairorder$coauthor22 <- 0
        }else{
                pairorder$coauthor21 <- pairorder$coauthor11/min(length(au1),length(au2))
                pairorder$coauthor22 <- pairorder$coauthor12/min(length(au1),length(au2))
        }
}
#调整feature的顺序使得其与原始的pair相一致
pairorder <- pairorder %>%
        arrange(match(paperA,pairorder_orig$paperA),
                match(paperB,pairorder_orig$paperB))


