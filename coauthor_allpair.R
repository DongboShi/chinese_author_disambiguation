library(dplyr)
library(rjson)
library(rhdf5)
library(tidyr)
library(rlist)
library(parallel)
library(stringr)
rm(list = ls())
path <- "/Users/zijiangred/changjiang/dataset"
path <- "/home/stonebird/cad"
setwd(paste0(path,"/feature"))

# function to make coauthor dataframe
makecadf <- function(j,fl){
        i <- fl[j]
        data <- fromJSON(file = paste0(path,"/inputdata/",i),simplify = T)
        papers <- data$papers
        coauthors <- data.frame()
        tmp <- list.map(papers,Coauthors)
        tmp1 <- unlist(lapply(tmp,head,n = 1))
        coauthors <- data.frame(tmp1)
        names(coauthors) <- "coauthor"
        rownames(coauthors) <- NULL
        replicate <- lapply(tmp,function(x){result <- length(unlist(x[[2]]))})
        coauthors$ut <- rep(names(tmp),replicate)
        return(coauthors)
}
# function to define neat fullname and fullnameshort
definename <- function(coauthors){
        coauthors <- coauthors %>% 
                mutate(familyname = str_sub(coauthor, 1, str_locate(coauthor, ",")[,1] - 1),
                       givenname = str_sub(coauthor,str_locate(coauthor, ",")[,1] + 1))
        coauthors$familyname[is.na(coauthors$familyname)] <- 
                str_sub(coauthors$coauthor[is.na(coauthors$familyname)],1,str_locate(coauthors$coauthor[is.na(coauthors$familyname)]," ")[,1]-1)
        coauthors$givenname[is.na(coauthors$givenname)] <- 
                str_sub(coauthors$coauthor[is.na(coauthors$givenname)],str_locate(coauthors$coauthor[is.na(coauthors$givenname)]," ")[,1]+1)
        coauthors <- coauthors %>% 
                mutate(familyname = tolower(familyname),
                       givenname = tolower(givenname),
                       givenname = str_replace_all(givenname,"-|\\.|`| |",""),
                       #familyname = str_replace_all(familyname,"-|\\.|`| |'",""),
                       givennameshort = str_sub(givenname,1,1),
                       fullname=paste(familyname,givenname,sep=","),
                       fullnameshort=paste(familyname,givennameshort,sep=","))
        return(coauthors)
}

maketfidf <- function(df){
        df <- df %>% 
                mutate(term = str_trim(str_remove_all(term, "'"), side ="both"),
                       term = as.character(term)) %>%
                group_by(term) %>%
                summarise(frequency=sum(frequency)) %>%
                ungroup() %>%
                mutate(totalfreq=sum(frequency)) %>%
                mutate(tfidf=log(totalfreq/frequency))
        return(df)
}

makepair <- function(i,fl){
        data <- fromJSON(file=paste0(path,"/inputdata/",fl[i]),simplify=T)
        papers <- data$papers
        paperut <- names(papers)
        paperut1 <- paperut
        pair <- crossing(paperut,paperut1) %>%
                rename(paperA = paperut, paperB=paperut1) %>%
                filter(paperA < paperB)
        return(pair)
}
#make local item frequency

# create feature
# import the global and local idf 
fullname_tf <- read.csv(paste0(path,"/global/fullname_tf.csv"),stringsAsFactors = F)
fullnameshort_tf <- read.csv(paste0(path,"/global/fullnameshort_tf.csv"),stringsAsFactors = F)
coauthor_tf_local<- read.csv(paste0(path,"/global/coauthor_tf_local.csv"),stringsAsFactors = F)
coauthor_short_tf_local <- read.csv(paste0(path,"/global/coauthor_short_tf_local.csv"),stringsAsFactors = F)

fullname_tf <- maketfidf(fullname_tf)
fullnameshort_tf <- maketfidf(fullnameshort_tf)
coauthor_tf_local <- maketfidf(coauthor_tf_local)
coauthor_short_tf_local <- maketfidf(coauthor_short_tf_local)

fullname_tf <- fullname_tf %>% select(term, frequency, tfidf)
fullnameshort_tf <- fullnameshort_tf %>% select(term, frequency, tfidf)
coauthor_tf_local <- coauthor_tf_local %>% select(term, frequency, tfidf)
coauthor_short_tf_local <- coauthor_short_tf_local %>% select(term, frequency, tfidf)

# make features

#换到大内存机器完成这部分代码
fl <- list.files(path = paste0(path,"/inputdata"))
fl <- fl[str_detect(fl,"json")]

#############
mkid <- function(ut,df){
        v <- 1:dim(df[df$ut == ut,])[1]
        return(v)
}
mkid2 <- function(ut,df){
        v <- 1:dim(df[df$ut == ut,])[1]
        return(v)
}

mkcoauthorpair <- function(df,fullname_tf,coauthor_tf_local){
        df_c1 <- df %>%
                group_by(ut,fullname) %>%
                summarise(count = n())
        df <- left_join(df,df_c1, by=c("ut","fullname"))
        
        df_11 <- df %>% 
                filter(count == 1) %>%
                select(ut,fullname) %>%
                mutate(fullname_match = paste0(fullname, "1")) %>%
                select(ut, fullname, fullname_match)
        
        df_12 <- df %>% 
                filter(count > 1) %>%
                group_by(ut,fullname) 
        
        v1 <- unlist(lapply(unique(df_12$ut), function(x) mkid(x,df_12)))
        
        df_12$v1 <- v1
        
        df_12 <- df_12 %>% 
                mutate(fullname_match = paste0(fullname, v1)) %>%
                select(ut, fullname, fullname_match)
        df_1 <- union(df_11, df_12)
        df11 <- data.frame()
        
        for(k in seq(1,length(unique(df_1$ut)),1000)){
                tmp <- df_1[df_1$ut %in% unique(df_1$ut)[k:(k+999)],]
                df11_tmp <- inner_join(tmp[c("ut","fullname","fullname_match")],
                                             df_1[c("ut","fullname","fullname_match")],
                                             by=c("fullname","fullname_match")) %>%
                        rename(paperA = ut.x, paperB = ut.y) %>%
                        filter(paperA < paperB) %>%
                        group_by(paperA,paperB)
                df11_tmp <- inner_join(df11_tmp,fullname_tf[c("term","tfidf")],
                                             by = c("fullname"="term")) %>%
                        rename(global_tfidf=tfidf)
                
                df11_tmp <- inner_join(df11_tmp,coauthor_tf_local[c("term","tfidf")],
                                             by = c("fullname"="term")) %>%
                        rename(local_tfidf=tfidf)
                
                df11_tmp <- df11_tmp %>%
                        group_by(paperA, paperB) %>%
                        summarise(coauthor11 = n(),
                                  coauthor41 = sum(local_tfidf),
                                  coauthor51 = sum(global_tfidf))
                df11 <- rbind(df11,data.frame(df11_tmp))
                print(k)
        }
        return(df11)
}
mkcoauthorpair_short <- function(df, fullnameshort_tf, coauthor_short_tf_local){      
        df_c2 <- df %>%
                group_by(ut,fullnameshort) %>%
                summarise(count2 = n())
        df <- left_join(df,df_c2, by=c("ut","fullnameshort"))
        df_21 <- df %>% 
                filter(count2 == 1) %>%
                select(ut,fullnameshort) %>%
                mutate(fullnameshort_match = paste0(fullnameshort, "1")) %>%
                select(ut, fullnameshort, fullnameshort_match)
        df_22 <- df %>% 
                filter(count2 > 1) %>%
                group_by(ut,fullnameshort) 
        v2 <- unlist(lapply(unique(df_22$ut), function(x) mkid2(x,df_22)))
        df_22$v2 <- v2
        df_22 <- df_22 %>% 
                mutate(fullnameshort_match = paste0(fullname, v2)) %>%
                select(ut, fullnameshort, fullnameshort_match)
        
        df_2 <- union(df_21, df_22)
        df22 <- data.frame()
        for(k in seq(1,length(unique(df_2$ut)),1000)){
                tmp <- df_2[df_2$ut %in% unique(df_2$ut)[k:(k+999)],]
                df22_tmp <- inner_join(tmp[c("ut","fullnameshort","fullnameshort_match")],
                                             df_2[c("ut","fullnameshort","fullnameshort_match")],
                                             by=c("fullnameshort","fullnameshort_match")) %>%
                        rename(paperA = ut.x, paperB = ut.y) %>%
                        filter(paperA < paperB) %>%
                        group_by(paperA,paperB)
                gc()
                df22_tmp <- inner_join(df22_tmp,fullnameshort_tf[c("term","tfidf")],
                                             by = c("fullnameshort"="term")) %>%
                        rename(global_tfidf=tfidf)
                
                df22_tmp <- inner_join(df22_tmp,coauthor_short_tf_local[c("term","tfidf")],
                                             by = c("fullnameshort"="term")) %>%
                        rename(local_tfidf=tfidf)
                
                df22_tmp <- df22_tmp %>%
                        group_by(paperA, paperB) %>%
                        summarise(coauthor12 = n(),
                                  coauthor42 = sum(local_tfidf),
                                  coauthor52 = sum(global_tfidf))
                df22 <- rbind(df22,data.frame(df22_tmp))
                print(k)
        }
        return(df22)
}


addfeature <- function(pairorder){
        pairorder <- pairorder %>%
                mutate(coauthor11=if_else(is.na(coauthor11),0,as.numeric(coauthor11)),
                       coauthor12=if_else(is.na(coauthor12),0,as.numeric(coauthor12)),
                       coauthor41=if_else(is.na(coauthor41),0,as.numeric(coauthor41)),
                       coauthor42=if_else(is.na(coauthor42),0,as.numeric(coauthor42)),
                       coauthor51=if_else(is.na(coauthor51),0,as.numeric(coauthor51)),
                       coauthor52=if_else(is.na(coauthor52),0,as.numeric(coauthor52)))
        pairorder <- pairorder %>% 
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
                                            coauthor22_2)) %>%
                select(paperA,paperB,coauthor11,coauthor12,coauthor21,coauthor22,
                       coauthor31,coauthor32,coauthor41,coauthor42,coauthor51,coauthor52)
        return(pairorder)
}

for(i in 1:50){
        id <- str_extract(fl[i],pattern = "[0-9]+")
        coauthors <- makecadf(i,fl)
        coauthors <- definename(coauthors)
        coauthors <- coauthors %>%
                mutate(fullname = str_replace_all(fullname,"'",""),
                       fullnameshort = str_replace_all(fullnameshort,"'",""))
        coauthors <- coauthors %>%
                select(ut,fullname,fullnameshort)
        print("make coauthors")
        coauthorn1 <- coauthors %>%
                select(ut,fullname) %>%
                distinct() %>%
                group_by(ut) %>%
                summarise(n1=n())
        coauthor11 <- mkcoauthorpair(coauthors,fullname_tf,coauthor_tf_local)
        gc()
        pairorder <- makepair(i,fl)
        #pairorder <- h5read(paste0("/Users/zijiangred/changjiang/dataset/pairorder/",id,"_pair.h5"),"pair")
        pairorder <- left_join(pairorder,coauthorn1,by=c("paperA"="ut")) %>%
                rename(auA=n1)
        pairorder <- left_join(pairorder,coauthorn1,by=c("paperB"="ut")) %>%
                rename(auB=n1)      
        pairorder <- pairorder %>%
                mutate(auA=if_else(is.na(auA),0,as.numeric(auA)),
                       auB=if_else(is.na(auB),0,as.numeric(auB)))
        pairorder <- left_join(pairorder,coauthor11,by=c("paperA","paperB"))
        rm(coauthor11)
        coauthor22 <- mkcoauthorpair_short(coauthors,fullnameshort_tf,coauthor_short_tf_local)
        gc()
        pairorder <- left_join(pairorder,coauthor22,by=c("paperA","paperB"))
        rm(coauthor22)
        pairorder <- addfeature(pairorder)
        write.csv(pairorder,file = paste0(path,"/feature/coauthor_fullpair/coauthor_",id,".csv"),row.names = F)
        print(i)
}
