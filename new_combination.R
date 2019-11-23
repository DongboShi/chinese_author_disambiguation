library(rhdf5)
library(dplyr)
library(stringr)
library(readr)
library(parallel)

observations<-read_csv('/Users/zijiangred/changjiang/dataset/feature/observations.csv')
train_sample<-observations%>%filter(ntruth>=10)
train_data<-data.frame()
setwd('/Users/zijiangred/changjiang/dataset')

for (i in 1:nrow(train_sample)) {
    fl <- str_remove(train_sample$cj[i],'CJ')
    
    pairorder<-h5read(file=paste0('pairorder/',fl,"_pair.h5"),name="pair")
    label<-h5read(file=paste0('pairorder/',fl,"_label.h5"),name="label")
    Feature_authororder<-read_csv(file=paste0('feature/Feature_author/Feature_authororder/Feature_authororder_',fl,'.csv'))
    Feature_authororder<-left_join(pairorder,Feature_authororder,by = c("paperA", "paperB"))
    Feature_authororder<-Feature_authororder[,c(1,2,9)] %>% 
        arrange(match(paperA,pairorder$paperA),
                match(paperB,pairorder$paperB))
    Feature_authororder<-Feature_authororder[,3:ncol(Feature_authororder)]
    
    Feature_givenname<-read_csv(file=paste0('feature/Feature_author/Feature_givenname/Feature_givenname_',fl,'.csv'))
    Feature_givenname<-left_join(pairorder,Feature_givenname,by = c("paperA", "paperB"))
    Feature_givenname<-Feature_givenname[,c(1,2,12)] %>% 
        arrange(match(paperA,pairorder$paperA),
                match(paperB,pairorder$paperB))
    Feature_givenname<-Feature_givenname[,3:ncol(Feature_givenname)]
    
    Feature_lName<-read_csv(file=paste0('feature/Feature_author/Feature_lName/Feature_lName_',fl,'.csv'))
    Feature_lName<-left_join(pairorder,Feature_lName,by = c("paperA", "paperB"))
    Feature_lName<-Feature_lName[,c(1,2,7)] %>% 
        arrange(match(paperA,pairorder$paperA),
                match(paperB,pairorder$paperB))
    Feature_lName<-Feature_lName[,3:ncol(Feature_lName)]

    year<-read_csv(file=paste0('feature/year/year_',fl,'.csv'))
    year<-left_join(pairorder,year,by = c("paperA", "paperB"))
    year<-year[,c(1,2,5,6)] %>% 
        arrange(match(paperA,pairorder$paperA),
                match(paperB,pairorder$paperB))
    year<-year[,3:ncol(year)]

    feature_before<-read_csv(file=paste0('/Users/zijiangred/changjiang/dataset/feature/feature/feature_',fl,'.csv'))
    feature_before<-feature_before[,c(1,2,7:21,24:39)]
    feature_new<-cbind(pairorder,label,Feature_authororder,Feature_givenname,Feature_lName,year)
    feature<-left_join(feature_new,feature_before,by=c('paperA','paperB'))
    feature_1<-feature%>%filter(label==1)
    feature_0<-feature%>%filter(label==0)
    if(nrow(feature_0)>nrow(feature_1)){
        pb=nrow(feature_1)/nrow(feature_0)
        feature_0$ind<-sample(2,nrow(feature_0),replace=TRUE,prob=c(1-pb,pb))
        feature_2<-feature_0%>%filter(ind==2)
        feature_0<-feature_2[,1:39]
        balance_data<-rbind(feature_0,feature_1)
    }else{
        pb=nrow(feature_0)/nrow(feature_1)
        feature_1$ind<-sample(2,nrow(feature_1),replace=TRUE,prob=c(1-pb,pb))
        feature_2<-feature_1%>%filter(ind==2)
        feature_1<-feature_2[,1:39]
        balance_data<-rbind(feature_0,feature_1)
    }
    balance_data$id<-fl
    train_data<-rbind(train_data,balance_data)
    print(paste0(i,'---',fl))
}
write.csv(train_data,file='/Users/zijiangred/changjiang/dataset/feature/train_data_new.csv',row.names=F)