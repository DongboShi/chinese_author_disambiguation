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
