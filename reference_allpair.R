library(dplyr)
library(rjson)
library(rhdf5)
library(stringr)
library(tidyr)
library(rlist)
library(parallel)
files <- list.files(path='/Users/zijiangred/changjiang/dataset/inputdata',pattern='CJ_')
#files <- list.files(path='/home/stonebird/cad/inputdata',pattern='CJ_')

id <- sort(as.numeric(str_extract(files,'[0-9]+')))
#Ref <- read.csv("/Volumes/WDC2/feature/ref_tf.csv")
Ref <- read.csv("ref_tf.csv",stringsAsFactors = F)

makeref <- function(j){
        i <- id[j]
        #pairorder <- h5read(file=paste0("/Volumes/WDC2/pairorder/",i,"_pair.h5"),name="pair")
        #data <- fromJSON(file=paste0("/home/stonebird/cad/inputdata/CJ_",i,".json"),simplify=T)
        data <- fromJSON(file=paste0("/Users/zijiangred/changjiang/dataset/inputdata/CJ_",i,".json"),simplify=T)
        papers <- data$papers
        #ref_1 <- data.frame()
        tmp <- list.map(papers,Reference) ####
        tmp1 <- unlist(lapply(tmp,head,n = 1))
        ref <- data.frame(tmp1)
        names(ref) <- "ref"
        rownames(ref) <- NULL
        replicate <- lapply(tmp,function(x){result <- length(unlist(x))})
        ref$ut <- rep(names(replicate),replicate)
        #计算一对pair相交的ref数量
        paperut <- names(papers)
        paperut1 <- paperut
        pairorder <- crossing(paperut,paperut1) %>%
                rename(paperA = paperut, paperB=paperut1) %>%
                filter(paperA < paperB)
        pairorderAB <- inner_join(ref,ref,by="ref") %>%
                rename(paperA = ut.x, paperB = ut.y) %>%
                filter(paperA < paperB) %>%
                group_by(paperA,paperB) %>%
                mutate(ref2=n(),
                       ref = as.character(ref))
        
        Ref <- Ref %>% mutate(ref = as.character(ref)) 
        pairorderAB <- left_join(pairorderAB, Ref, by = "ref")
        # pairorderAB <- inner_join(pairorderA,pairorderB)
        # pairorderAB <- select(left_join(pairorderAB,part_ref3),-freq)
        #计算sum log idf
        #feature %>% filter(paperA=="WOS:000071394700010")
        #pairorderAB %>% filter(paperA=="WOS:000071394700010", paperB == "WOS:000078911700014")
        feature <- group_by(pairorderAB,paperA,paperB) %>%
                mutate(ref3=sum(part_idf_ref)) %>%
                select(-ref,-part_idf_ref,-freq) %>%
                distinct()
        Feature <- left_join(pairorder,feature) 
        Feature$ref2[is.na(Feature$ref2)] <- 0
        Feature$ref3[is.na(Feature$ref3)] <- 0
        #Feature[is.na(Feature)] <- 0
        
        ref <- ref %>% mutate(ref11 = 1, 
                              ref12 = 1)
        ref$ref <- as.character(ref$ref)
        Feature <- left_join(Feature, ref[c("ut","ref","ref11")], 
                             by = c("paperA" = "ut", "paperB" = "ref"))
        Feature <- left_join(Feature, ref[c("ut","ref","ref12")], 
                             by = c("paperA" = "ref", "paperB" = "ut"))
        Feature$ref11[is.na(Feature$ref11)] <- 0
        Feature$ref12[is.na(Feature$ref12)] <- 0
        #计算第一个feature，A在B的ref里，记1，B在A的ref里，也记1，加和
        Feature <- Feature %>%
                mutate(ref1 = ref11 + ref12) %>%
                select(-ref11,-ref12)
        #write.csv(Feature,file=paste0('/home/stonebird/cad/feature/ref_full/feature_ref_',i,'.csv'),row.names=F,na='')  
        write.csv(Feature,file=paste0('/Volumes/WDC2/feature/ref_fullpair/feature_ref_',i,'.csv'),row.names=F,na='')  
        print(j) 
}
mclapply(1:100,makeref,mc.cores = 8)

