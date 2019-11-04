library(dplyr)
library(rjson)
library(rhdf5)
library(tidyr)
library(rlist)
library(parallel)
library(stringr)
rm(list=ls())
setwd("/Users/zijiangred/changjiang/dataset/feature")

#make local item frequency
#setwd("/Users/birdstone/Documents/Data")
fl <- list.files(path = "/Users/zijiangred/changjiang/dataset/inputdata")
fl <- fl[str_detect(fl,"json")]
# input data
coauthor_global <- list()
# function to make coauthor dataframe
makecadf <- function(j,fl){
        i<-fl[j]
        data <- fromJSON(file=paste0("/Users/zijiangred/changjiang/dataset/inputdata/",i),simplify=T)
        papers <- data$papers
        coauthors <- data.frame()
        tmp <- list.map(papers,Coauthors)
        tmp1 <- unlist(lapply(tmp,head,n=1))
        coauthors <- data.frame(tmp1)
        names(coauthors)<-"coauthor"
        rownames(coauthors)<- NULL
        replicate <- lapply(tmp,function(x){result <-length(unlist(x[[2]]))})
        coauthors$ut <- rep(names(tmp),replicate)
        return(coauthors)
}
# function to define neat fullname and fullnameshort
definename <- function(coauthors){
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
        return(coauthors)
}

maketfidf <- function(df){
        df <- df %>% 
                mutate(tfidf=log(sum(frequency)/frequency))
        return(df)
}

for(j in 1:length(fl)){
        coauthor_global[[j]] <- makecadf(j,fl)
        print(j)
}

coauthor_tf_local <- data.frame()
coauthor_short_tf_local <- data.frame()
for(k in 1:length(coauthor_global)){
        coauthors <- coauthor_global[[k]]
        coauthors <- definename(coauthors)
        coauthors_tf <- data.frame(table(coauthors$fullname))
        names(coauthors_tf) <- c("term","frequency")
        coauthors_short_tf <- data.frame(table(coauthors$fullnameshort))
        names(coauthors_short_tf) <- c("term","frequency")
        coauthor_tf_local <- rbind(coauthor_tf_local,coauthors_tf)
        coauthor_short_tf_local <- rbind(coauthor_short_tf_local,coauthors_short_tf)
        print(k)
}
coauthor_tf_local <- coauthor_tf_local %>%
        group_by(term) %>%
        summarise(frequency=sum(frequency))
coauthor_short_tf_local <- coauthor_short_tf_local %>%
        group_by(term) %>%
        summarise(frequency=sum(frequency))
write.csv(coauthor_tf_local,file="/Users/zijiangred/changjiang/dataset/global/coauthor_tf_local.csv",row.names = F)
write.csv(coauthor_short_tf_local,file="/Users/zijiangred/changjiang/dataset/global/coauthor_short_tf_local.csv",row.names = F)

