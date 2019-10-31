library(dplyr)
library(rjson)
library(rhdf5)
library(tidyr)
library(rlist)
library(parallel)
library(stringr)
rm(list=ls())
setwd("/Users/zijiangred/changjiang/dataset/feature")

#setwd("/Users/birdstone/Documents/Data")
fl <- list.files(path = "/Users/zijiangred/changjiang/dataset/inputdata")
fl <- fl[str_detect(fl,"json")]
# input data
coauthor_global <- data.frame()
for(i in fl){
        data <- fromJSON(file=paste0("/Users/zijiangred/changjiang/dataset/inputdata/",i),simplify=T)
        papers <- data$papers
        coauthors <- data.frame()
        tmp <- list.map(papers,Coauthors)
        tmp1 <- unlist(lapply(tmp,head,n=1))
        coauthors <- data.frame(tmp1)
        names(coauthors)<-"coauthor"
        rownames(coauthors)<- NULL
        replicate <- lapply(tmp1,function(x){result <-length(unlist(x))})
        coauthors$ut <- rep(names(replicate),replicate)
        coauthor_global <- rbind(coauthor_global,coauthors)
        print(i)
}



shiouc
makecoauthor <- function(i){}
i <- fl[1]
data <- fromJSON(file="CJ_1.json",simplify=T)
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

paperut <- names(papers)
paperut1 <- paperut

coauthor11 <- inner_join(coauthors[c("ut","fullname")],
                         coauthors[c("ut","fullname")],
                         by="fullname") %>%
        rename(paperA = ut.x, paperB = ut.y) %>%
        filter(paperA < paperB) %>%
        group_by(paperA,paperB) %>%
        summarise(coauthor11 = n())
        
coauthor12 <- inner_join(coauthors[c("ut","fullnameshort")],
                         coauthors[c("ut","fullnameshort")],
                         by="fullnameshort") %>%
        rename(paperA = ut.x, paperB = ut.y) %>%
        filter(paperA < paperB) %>%
        group_by(paperA,paperB) %>%
        summarise(coauthor12 = n())

coauthorn1 <- coauthors %>% 
        select(ut,fullname) %>%
        distinct() %>%
        group_by(ut) %>%
        summarise(n1=n())

pair <- crossing(paperut,paperut1) %>%
        rename(paperA = paperut, paperB=paperut1) %>%
        filter(paperA < paperB)
pair <- left_join(pair,coauthorn1,by=c("paperA"="ut")) %>%
        rename(auA=n1)
pair <- left_join(pair,coauthorn1,by=c("paperB"="ut")) %>%
        rename(auB=n1)      
pair <- pair %>%
        mutate(auA=if_else(is.na(auA),0,as.numeric(auA)),
               auB=if_else(is.na(auB),0,as.numeric(auB)))

pair <- left_join(pair,coauthor11,by=c("paperA","paperB"))
pair <- left_join(pair,coauthor12,by=c("paperA","paperB"))

pair <- pair %>%
        mutate(coauthor11=if_else(is.na(coauthor11),0,as.numeric(coauthor11)),
               coauthor12=if_else(is.na(coauthor12),0,as.numeric(coauthor12)))

pair <- pair %>% 
        mutate(auA = auA + 1,
               auB = auB + 1,
               coauthor31 = coauthor11/(auA+auB),
               coauthor32 = coauthor12/(auA+auB),
               coauthor21_1 = coauthor11/auA,
               coauthor21_2 = coauthor11/auB,
               coauthor22_1 = coauthor12/auA,
               coauthor22_2 = coauthor12/auB,
               coauthor21 = if_else(coauthor21_1>=coauthor21_2,
                                    coauthor21_1,
                                    coauthor21_2),
               coauthor22 = if_else(coauthor22_1>=coauthor22_2,
                                    coauthor22_1,
                                    coauthor22_2))

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

#---------------------------------------
## 制造feture
#--------------------------------------

