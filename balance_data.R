library(dplyr)
library(stringr)
library(readr)
library(parallel)
observations<-read_csv('/Users/zijiangred/changjiang/dataset/feature/observations.csv')
#nrow(observations)
total_data<-data.frame()
for (i in 1:nrow(observations)) {
    ntruth <- observations$ntruth[i]
    if (ntruth >= 10){
        fl <- str_remove(observations$cj[i],'CJ')
        feature<-read_csv(file=paste0('/Users/zijiangred/changjiang/dataset/feature/feature/feature_',fl,'.csv'))
        total_data<-rbind(total_data,feature)
    }else{
        a<-i+1
    }
    print(i)
}
write.csv(total_data,file='/Users/zijiangred/changjiang/dataset/feature/total_data.csv',row.names=F)

data_1<-total_data%>%filter(label==1)
data_0<-total_data%>%filter(label==0)

# ind<-sample(2,nrow(training),replace=TRUE,prob=c(0.7,0.3)) #对数据分成两部分，70%训练数据，30%检测数据
# traindata<- training [ind==1,] #训练集
# testdata<- training [ind==2,] #测试集

if(nrow(data_0)>nrow(data_1)){
    pb=nrow(data_1)/nrow(data_0)
    data_0$ind<-sample(2,nrow(data_0),replace=TRUE,prob=c(1-pb,pb))
    data_2<-data_0%>%filter(ind==2)
    data_0<-data_2[,1:39]
    train_data<-rbind(data_0,data_1)
}else{
    pb=nrow(data_0)/nrow(data_1)
    data_1$ind<-sample(2,nrow(data_1),replace=TRUE,prob=c(1-pb,pb))
    data_2<-data_1%>%filter(ind==2)
    data_1<-data_2[,1:39]
    train_data<-rbind(data_0,data_1)
}
write.csv(train_data,file='/Users/zijiangred/changjiang/dataset/feature/train_data.csv',row.names=F)
