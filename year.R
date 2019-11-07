library(rhdf5)
library(dplyr)
library(rjson)
library(tidyr)
library(rlist)
library(stringr)
library(parallel)

fl <- list.files(path = "/Users/zijiangred/changjiang/dataset/inputdata")
fl <- fl[str_detect(fl,"json")]

year <- function(j){
    data <- fromJSON(file=paste0("C:/Users/liuningjie/Desktop/chinese/data/",fl[j]),simplify=T)
    pairorder_orig <- h5read(file=(paste0("C:/Users/liuningjie/Desktop/chinese/pair/",i,"_pair.h5")),name="pair")
    papers <- data$papers
    years <- data.frame()
    for(k in 1:length(papers)){
        ut <- papers[[k]]$UT
        year <- papers[[k]]$Pubyear
        if(length(year)==0){
            year = 99999
        }
        result<-data.frame()
        result <- data.frame(year,stringsAsFactors = F)
        names(result)<-"years"
        result$ut <- ut
        years <- rbind(years,result)
    }
    pairorder <- pairorder_orig
    pairorder <- left_join(pairorder,years,by=c('paperA'='ut'))
    colnames(pairorder) <- c("paperA","paperB","yearA")
    pairorder <- left_join(pairorder,years,by=c('paperB'='ut'))
    colnames(pairorder) <- c("paperA","paperB","yearA",'yearB')
    pairorder$yearA[pairorder$yearA=='NA'] <- 99999
    pairorder$yearB[pairorder$yearB=='NA'] <- 99999
    pairorder$yearA <- as.numeric(pairorder$yearA)
    pairorder$yearB <- as.numeric(pairorder$yearB)
    pairorder <- mutate(pairorder,year1=abs(yearA-yearB))
    pairorder <- mutate(pairorder,year2=ifelse(yearA <= 2008 & yearB <= 2008,0,5))
    pairorder <- mutate(pairorder,year2=ifelse(yearA > 2008 & yearB > 2008,2,year2))
    pairorder <- mutate(pairorder,year2=ifelse(yearA == 99999 | yearB == 99999,3,year2))
    pairorder <- mutate(pairorder,year2=ifelse(year2==5,1,year2))
    pairorder <- pairorder %>%
        arrange(match(paperA,pairorder_orig$paperA),
                match(paperB,pairorder_orig$paperB))
    write.csv(pairorder,file=paste0("C:/Users/liuningjie/Desktop/chinese/feature/year_",i,".csv"), row.names = F)
    print(i)    
}

#lapply(1:length(file),year)
    
mclapply(1:6,function(x) year,mc.cores=6)