# chinese_author_disambiguation
the project is to disambiguate the Chinese authors of web of science articles 



## 说明
1. 对于每一个名字的备选集，输出确定顺序的论文ut_pairs.由于我们使用的是部分消岐的grand truth，所以这部分要筛选出确定的positive pairs 和negative pairs，后续的feature构造结束后，只能选择相应的pair进入训练集；


2. 针对每一个制造相关的feature，其中部分idf依赖于wos全库的数据信息，这部分我来选出来，存入特定的数据文件

idf 给定作者后，在备选集里面用内部分布；另一种做法是全库？

3. 在person层面，对一部分人流出来20%作为test集合；然后剩下的人作为training data；特别是不是每一对pair都是traning data pairs，这一步要完成筛选；


4. 训练模型
5. 调参数


## 备选的feature

每个feature 注明参考文献来源
### author 类
如何结合torvik 和 kim的做法?

| feature | reference | definition | 负责人|
| -----| ---- | ---- |----|
| givenname|Pucktada 2009|0 if fnameA ≠ fnameB and both are fullname;<br /> 1 if fnameA ≠ fnameB and are not both fullname;<br />2 if fnameA ＝ fnameB and both are not fullname;<br />3 if fnameA ＝ fnameB and both are fullname|宁杰、李萌|
| authororder|Pucktada 2009|2 if both authors are the 1st author;<br />1 if both authors are the last author;<br /> 2 one first and the other last;<br /> 0 otherwise|宁杰、李萌|
|IDFlname-weight of the author last name|Pucktada 2009|直接计算相关lastauthorname的备选论文数量的导数|宁杰、李萌|

### coauthor 类
coauthor这部分需要保留两种coauthor的名字形式：首先去掉名字中的特殊符号，包括"-，\_\`'"。然后再仅保留family name的第一个首字母；因此每一个coauthor name可以有两个形式，一个是given name 首字母 + family name，一个是original full given name + family name。后续的feature相应的也会有两套。

| feature | reference | definition | 负责人|
| -----| ---- | ---- |----|
|coauthor11|Pucktada 2009|# coauthorA ∩ coauthorB |史冬波|
|coauthor12|Pucktada 2009|# coauthorA ∩ coauthorB|史冬波|
|coauthor21|Schulz 2014|# coauthorA ∩ coauthorB / min(#coauthorA,#coauthorB)|史冬波|
|coauthor22|Schulz 2014|# coauthorA ∩ coauthorB / min(#coauthorA,#coauthorB)|史冬波|
|coauthor31|Pucktada 2009|# coauthorA ∩ coauthorB / (#coauthorA + #coauthorB)<br />可以使用stringdist包直接计算|史冬波|
|coauthor32|Pucktada 2009|# coauthorA ∩ coauthorB / (#coauthorA + #coauthorB)<br />可以使用stringdist包直接计算|史冬波|
|coauthor41|Pucktada 2009|∑ logIDF coauthor，使用局部的idf|史冬波|
|coauthor42|Pucktada 2009|∑ logIDF coauthor，使用局部的idf|史冬波|
|coauthor51|Pucktada 2009|∑ logIDF coauthor，全局idf|史冬波|
|coauthor52|Pucktada 2009|∑ logIDF coauthor，全局idf|史冬波|
|coauthor61|自创|min (step between A and B，5)|史冬波|
|coauthor62|自创|min (step between A and B，5)|史冬波|

### reference 和citation 类
| feature | reference | definition | 负责人|
| -----| ---- | ---- |----|
|ref1|Schulz 2014|#pA ∩ RB + # pB ∩ RA|涵谦|
|ref2|Schulz 2014|# RB ∩ # RA|涵谦|
|ref3|自创|∑logidf(R)局部idf|涵谦|
|ref4|Schulz 2014|#citingA ∩ citingB / min(#citingA,#citingB)||史冬波，缺数据|
|ref5|Schulz 2014|#citingA ∩ citingB / #citingA+#citingB||史冬波，缺数据|


### journal 类
| feature | reference | definition | 负责人|
| -----| ---- | ---- |----|
|so1|自创|1 if in same so;<br />0 if not in same so|宁杰,李萌|
|so2|Pucktada 2009|logidf so;<br />0 if not in same so|宁杰,李萌,局部idf|
|so3|Pucktada 2009|logidf so;<br />0 if not in same so|宁杰,李萌,我提供全局idf|

### year 类
| feature | reference | definition | 负责人|
| -----| ---- | ---- |----|
|year1|Pucktada 2009|year dif|宁杰，李萌|
|year2|Pucktada 2009|0,if both are before 2008;<br />1,if one is before 2008 and one is after 2008;<br />2,if both are after 2008|宁杰，李萌|

### affiliation 类
首先把org1字段，也就是地址字段的第一个逗号之前的内容选出来作为affiliation
其次org2+org1字段，也就是地址字段的第二个逗号之前的内容选出来作为affiliation

然后后续做法可以分为两种，第一种是讲org1作为整体处理，第二种将org2处理，都做一下feature

| feature | reference | definition | 负责人|
| -----| ---- | ---- |----|
|aff11|Pucktada 2009| jaccard similarity #aff A ∩ affB / (#affA + affB)|宁杰、李萌|
|aff12|Pucktada 2009| jaccard similarity #aff A ∩ affB / (#affA + affB)|宁杰、李萌|
|aff21|Pucktada 2009| ∑ logidf(aff)局部idf|宁杰、李萌|
|aff22|Pucktada 2009| ∑ logidf(aff)局部idf|宁杰、李萌|
|aff31|Pucktada 2009|  ∑ logidf(aff)全局部idf|宁杰、李萌，史冬波提供idf|
|aff32|Pucktada 2009|  ∑ logidf(aff)全局部idf|宁杰、李萌，史冬波提供idf|
|"/Users/zijiangred/changjiang/dataset/global/org1_tf.csv"||||
|"/Users/zijiangred/changjiang/dataset/global/org2_tf.csv"||||

|外国机构是否可以用一下||||

### keywords，field 类
| feature | reference | definition | 负责人|
| -----| ---- | ---- |----|
|kw1|Pucktada 2009|# keywordA ∩ keywordB|刘宁杰、李萌|
|kw2|Pucktada 2009|∑logidf(kw)|刘宁杰、李萌，局部idf|
|kw3|Pucktada 2009|∑logidf(kw)|刘宁杰、李萌，全局idf|
|field1||# fieldA ∩ fieldB|刘宁杰、李萌|
|field2||∑logidf(field)|刘宁杰、李萌，局部idf|
|field3||∑logidf(field)|刘宁杰、李萌，全局idf|### title 类

| feature | reference | definition | 负责人|
| -----| ---- | ---- |----|
|title1|Pucktada 2009|# titleA ∩ titleB / (#titleA + #titleB)<br />可以使用stringdist包直接计算|李萌、宁杰|
|title2|自创|∑ logidf(shared item),使用局部idf|李萌、宁杰|
|title3|自创|∑ logidf(shared item),使用全局idf|李萌、宁杰、史冬波，待定是否加入|
|"/Users/zijiangred/changjiang/dataset/global/title_tf.csv"|全局tf位置|
### 其他类
doc2vec

| feature | reference | definition | 负责人|
| -----| ---- | ---- |----|
|email||1,存在一个相同的email||史冬波|
## 模型选择

理论上我们会尝试所有类型的模型

xgboost

randomforest

## 聚类方法

## data pipeline
### 规定pair顺序
关于每个文件的pair的说明：每一个h5文件对应了一个待消岐的科学家，按照子江目前的命名方式，是一个自然数，所以我生成的h5文件为1_pair.h5,每一个文件包含了一个dataframe，对应的是该科学家需要生成的pair。

- 安装依赖
```
source("http://bioconductor.org/biocLite.R")
biocLite("rhdf5")
library(rhdf5)
```
- 读入
```
h5read("1_pair.h5",name="pair")
```
- 使用方法
输出的feature要与我定义的pair中的顺序完全对应，h5用下列名字写出
```
h5write(author1,file="author1.h5",name="feature")
```


### 制作feature
### train model
### predict cluster

#### 不使用cv的聚类方法
1. 通过模型预测出每一对pair之间的similarity
2. 通过dbscan聚类
3. 通过cv vote出最符合cv特征的一个cluster0
调dbscan的参数

#### 使用cv的聚类方法
1. 通过模型预测出每一对pair之间的similarity
2. 通过dbscan聚类
3. 通过cv vote出最符合cv特征的一个cluster0
4. 定义超参数$\beta_{1}$，计算cluster0内部的node i的$max(similarity)\_{i}$, 当 $max(similarity)_{i} < \beta_{1}$时，从cluster0中提出剔除i；形成cluster1
5. 定义超参数$\beta_{2}$，计算cluster1之外的节点与cluster1内建点的max(similarity), 当$max(similarity)_{j} > \beta_{2}$时，讲j加入cluster1，迭代最终形成cluster2

通过cluster2，计算聚类的结果。
同时调beta1，beta2以及dbscan的参数

### validate 结果

### 参考文献
1. A fast and integrative algorithm for clustering performance evaluation in author name disambiguation，2019
	
2. Author Name Disambiguation
作者: Smalheiser, Neil R.; Torvik, Vetle I.
ANNUAL REVIEW OF INFORMATION SCIENCE AND TECHNOLOGY  

3. A Heuristic Approach to Author Name Disambiguation in Bibliometrics Databases for Large-Scale Research Assessments
作者: D'Angelo, Ciriaco Andrea; Giuffrida, Cristiano; Abramo, Giovanni
JOURNAL OF THE AMERICAN SOCIETY FOR INFORMATION SCIENCE AND TECHNOLOGY 

4. A Brief Survey of Automatic Methods for Author Name Disambiguation
作者: Ferreira, Anderson A.; Goncalves, Marcos Andre; Laender, Alberto H. F.
SIGMOD RECORD   卷: 41   期: 2   页: 15-26   出版年: JUN 2012

5. Two supervised learning approaches for name disambiguation in author citations
作者: Han, H; Giles, L; Zha, H; 等.
会议: 4th Joint Conference on Digital Libraries 会议地点: Tucson, AZ 会议日期: JUN 07-11, 2004
**宁杰**

1.coauthor names

the individual coauthor. Author names in citations are represented by the first name initial and last name.
construct a vector A\_1 =(A\_11,A\_12, ..., A\_1k, ..., A\_1K(1)), A\_1 represents the coauthor feature, A\_11 represents one coauthor of the citation.

2.paper titles

the individual keyword in the paper title. By “keyword”, we mean the remaining words after filtering out the stop words (such as, “a”, “the” “of”, etc.).
construct a vector A\_2 =(A\_21,A\_22, ..., A\_2k, ..., A\_2K(1)), A\_2 represents the paper title feature, A\_21 represents one keyword of the citation.

3.journal titles

the individual keyword in the journal title. By “keyword”, we mean the remaining words after filtering out the stop words (such as, “a”, “the” “of”, etc.).
construct a vector A\_3 =(A\_31,A\_32, ..., A\_3k, ..., A\_3K(1)), A\_3 represents the journal titles feature, A\_31 represents one keyword of the citation.

4.Hybrid I
Hybrid I=\left\{\begin{aligned}computes the equal joint probability of different attributes & naive Bayes \\
combines different attributes in the same feature space &  SVM \end{aligned}\right.

5.Hybrid II
The “Hybrid II” scheme is specific to the naive Bayes model and uses the coauthor attribute alone when a coauthor relationship exists between a coauthor in the test citation and a candidate name entry in the citation database; otherwise, “Hybrid II” uses the equal joint probability of all the three attributes.

**NAIVE BAYES**

$$max\_iP(X\_i|C)$$:find a name entry Xi in the citation database with the maximal posterior probability of producing the citation C.

$$max\_iP(X\_i|C)= max\_i[\sum_j \sum_k log(P(A\_jk))+log(P(X\_i))] $$
where j ∈ [1, 3] and k ∈ [0,K(j)],where P(X\_i) denotes the prior probability of X\_i authoring papers

where A\_j denotes the different type of attribute; that is, A\_1 - the coauthor names; A\_2 - the paper title; A\_3 - the journal title. Each attribute is decomposed into independent elements represented by A\_jk (k ∈ [0..K(j)]). K(j) is the total number of elements in attribute A\_j. For example, A\_1 =(A\_11,A\_12, ..., A\_1k, ..., A\_1K(1)), where A\_1k indicates the kth coauthor in C.

the decomposition and estimation of the coauthor conditional probability P(A\_1|X\_i) from the training citations, where A\_1 = (A\_11,A\_12, ..., A\_1k, ..., A\_1K(1)). The probability estimation is the maximum likelihood estimation for parameters of multinomial distributions.

**P(A\_1|X\_i)= P(N|X\_i) if K(1) =0**

P(N|X\_i) - the probability of X\_i writing a future paper alone conditioned on the event of X\_i, estimated as the proportion of the papers that X\_i authors alone among all the papers of X\_i.(N stands for “No coauthor”, and “Co” below stands for “Has coauthor”).

**P(A\_1|X\_i)= P(A\_11|X\_i)...P(A\_1k|X\_i)...P(A\_1K|X\_i) if K(1) > 0**

where P(A\_1k|X\_i)= P(A\_1k,N|X\_i)+ P(A\_1k,Co|X\_i) 
                   = 0+P(A\_1k,Co|X\_i) 
		   = P(A\_1k,Seen,Co|X\_i)+ P(A\_1k,Unseen,Co|X\_i) 
		   = P(A\_1k|Seen, Co,X\_i)∗P(Seen|Co,X\_i)∗P(Co|X\_i)+ P(A\_1k|Unseen, Co, X\_i)∗P(Unseen|Co, X\_i)∗P(Co|X\_i)

P(Co|X\_i) - the probability of X\_i writing a future paper with coauthors conditioned on the event of X\_i.P(Co|X\_i)=1− P(N|X\_i)

P(Seen|Co,Xi) - We regard the coauthors coauthoring a paper with X\_i at least twice in the training citations as the “seen coauthors”; the other coauthors coauthoring a paper with X\_i only once in the training citations is considered as the “unseen coauthors”. if Xi has n coauthors in a training citation C, we count that X\_i coauthors n times in citation C.

P(Unseen|Co,X\_i) - P(Unseen|Co, X\_i) = 1 −P(Seen|Co,X\_i)

P(A\_1k|Seen, Co,X\_i) - the probability of X\_i writing a future paper with a particular coauthor A\_1k conditioned on the event that X\_i writes a paper with previously seen coauthors. We estimate it as the proportion of the number of times that X\_i coauthors with A\_1k among the total number of times X\_i coauthors with any coauthor.

P(A\_1k|Unseen, Co, X\_i) - the probability of X\_i writing a future paper with a particular coauthor A\_1k conditioned on the event that X\_i writes a paper with unseen coauthors. Considering all the names in the training citations as the population and assuming that X\_i has equal probability to coauthor with an unseen author, we estimate P(A\_1k|Unseen, Co,X\_i) as 1 divided by the total number of author (or coauthor) names in the training citations minus the number of coauthors of X\_i.

Similarly, we can estimate the conditional probability P(A2|Xi) that an author writes a paper title, and the conditional probability P(A3|Xi) that he publishes in a particular journal. Taking each title word of the paper and journal as an independent element, we estimate the probabilities that Xi uses a certain word for a future paper title, and publishes a future paper in a journal with a particular word in the journal title.

**SVM**

The SVM approach considers each author as a class, and classifies a new citation to the closest author class. With the SVM approach, we represent each citation in a vector space; each coauthor name and keyword in paper/journal title is a feature ofthe vector.

6. Author Name Disambiguation in MEDLINE
作者: Torvik, Vetle I.; Smalheiser, Neil R.
ACM TRANSACTIONS ON KNOWLEDGE DISCOVERY FROM DATA
Author Name Disambiguation in MEDLINE，Torvik, Vetle I.; Smalheiser, Neil R. ACM TRANSACTIONS ON KNOWLEDGE DISCOVERY FROM DATA,2009
**子江**

思路：

For each pair of articles within the block, compute the similarity profile, a multidimensional vector x = <x1,x2,… , x10> which is based on the different predictive features extracted from the MEDLINE records.

过程：

**Improvement to basic pairwise model(Torvik et al. 2005)**

①E-mail Address

Only reserve the records where 

*a single author name (last name, first initial) occurs on all PMIDs associated with a unique email address* 

OR

*If multiple names occur on all PMIDs associated with a unique email address, pick the one that contains the last name within the prefix of the email address* 

→保证同一个email地址下的文章记录均属于同一姓名

So Personal email address match across two articles was considered absolute evidence that the two articles were written by the same individual

②Author First Names

we first generated two new training or reference sets (in addition to the sets used for the original model): the match set consisted of ~2M pairs of names that match on email addresses. The nonmatch set was generated by randomly selecting 50k names and computing all pairwise comparisons with different last name and the same first initial.

<u>Partial match on first names</u>

Given two first names on a pair of articles being compared, the first name score x1 is the greatest of the following:

11: exact match,

10: name with or without hyphen/space (jean-francois vs. jeanfrancois or jeanfrancois vs. jean francois),

9: hyphenated name vs. name with hyphen and initial (jean-francois vs. jean-f),

8: hyphenated name with initial vs. name (jean-f vs. jean),

7: hyphenated name vs. first name only (jean-francois vs. jean)

6: nickname match (dave vs. david)

5: one edit distance (deletion: bjoern vs. bjorn, replacement: bjoern vs. bjaern, or flip order of two characters: bjoern vs. bjeorn)

4: name matches first part of other name and length > 2 (zak vs. zakaria)

3: name matches first part of other name and length = 2 (th vs. thomas)

2: 3-letter initials match (e.g., jean francois g vs. jfg)

1: one or both names are missing,

0: otherwise.

<u>Correction for first name frequency</u>

A random sample of first names was selected to span a wide range of counts in MEDLINE (n = 1,111 to 87,827) and the r-values were computed for each of the first names. A log-log plot of the r-values against the counts of the first names revealed a strong linear correlation (data not shown). Linear regression resulted in the following  relationship:

r1(x1) = $10^{5.6866}n^{−1.0024}$ if x1 = 11.

r1(x1) = $43.9$ if x1 = 8,9 or 10.

r1(x1) = $2.7$ if x1 = 7.

r1(x1) = $0.56$ if x1 = 6.

r1(x1) = $0.21$ if x1 = 5.

r1(x1) = $0.14$ if x1 = 4.

r1(x1) = $0.34$ if x1 = 3.

r1(x1) = $0.13$ if x1 = 2.

r1(x1) = $1$ if x1 = 1.

r1(x1) = $0.0009$ if x1 = 0.

A list of first names that occur 10 or more times across all of MEDLINE was compiled, together with their counts. If a name is not on the list or occurs fewer than 10 times, the count is assigned 10 which results in an r1-value of roughly 48,000 for very rare names.

③Correction for Interactive Effects: Name-Specific Correlations with Affiliation Words

All last names that occurred more than 100 times in MEDLINE were examined. For each last name we collected all the affiliation words that occurred in > 30% of the records and 10 times more than expected. As a result, a list of 1,721 correlated (last name, affiliation word) pairs were detected such as (Wang, China), (Lee, Korea), (Lin, Taiwan), (Suzuki, Japan), and (Kumar, India).Such affiliation words are stoplisted when comparisons are made for those last names.

④Summary of the Improved Pairwise Model

The ten-dimensional similarity profile x = <x1,x2,…,x10> is computed as follows:

x1 = 0,1, … , or 11 first name match defined above,

x2 = 3 if middle initials match, 2 if both records'  middle initials are missing, 1 if one record is missing middle initial, 0 if middle initials are different,

x3 = 1 if name suffix matches (e.g., Jr vs. Jr), 0 otherwise,

x4 = number of title words in common after preprocessing and stoplisting,

x5 = 1 if journal name matches exactly, 0 otherwise,

x6 = number of MeSH in common after stoplisting,

x7 = number matching coauthors names based on last name and both initials (includes matches with missing middle initial, e.g., JA Smith vs. J Smith counts),

x8 = number of affiliation words in common after preprocessing and stoplisting,

x9 = 1 if both affiliations are given, 0 otherwise,

x10 = 3 if language matches and both are non-English, 2 if both are English, 1 if one is English and the other is non-English, 0 if they don't match and both are non-English. MEDLINE records that are encoded as "undetermined language" ("und") are treated as any non-English language (i.e., are considered a match with any other non-English language).

Given the similarity profile, the r-value is computed by:

$$r(x)=r1(x1)rx(x2)r3(x3)r4(x4)...r10(x10)$$


7. A probabilistic similarity metric for Medline records: A model for author name disambiguation
作者: Torvik, VI; Weeber, M; Swanson, DR; 等.
JOURNAL OF THE AMERICAN SOCIETY FOR INFORMATION SCIENCE AND TECHNOLOGY
**子江**

**Fields**

pmid = unique (PubMed) article identification number

order = position of author name on article

last = last name of author

init1 = first initial of author name

init2 = middle initial of author name

suff = suffix of author name

title = set of title words after preprocessing and removing title-stopwords

affl = set of affiliation words after preprocessing and removing affiliation-stopwords

jrnl = journal name

lang = language of article

mesh = set of MeSH words after preprocessing and removing mesh-stopwords

title-stopwords = 
Small: PubMed’s set of stopwords as of January 2002, which consists 365 commonly used English words, like “the” and “and.”  
Medium: The small stoplist together with the 1,029 words that appear in over 0.1% of the titles. About 400 of these frequent words were not included in this list because we judged that they may be important for establishing connections between two disparate disciplines.  
Large: The small stoplist together with a list of the 8,207 words that are thought not to be important in establishing connections between two disparate disciplines.These words have been accumulated over the years as a part of the Arrowsmith Project (Swanson &
Smalheiser, 1997). All words on the medium stoplist were also on the large stoplist.

affiliation-stopwords = small title-stopwords ∪ {university, medicine, medical, usa, hospital, school, institute, center,research, science, college, health, new, laboratory, division,national},

mesh-stopwords = {human, male, female, animal, adult,support non-u.s. gov’t, middle age, aged, english abstract,support u.s. gov’t p.h.s., case report, rats, comparative study, adolescence, child, mice, time factors, child preschool, pregnancy, united states, infant, molecular sequence data, kinetics, support u.s. gov’t non-p.h.s., infant newborn}.

**Similarity Profile**

Suppose two distinct records obtained from the AUTHOR_ARTICLES table are given by:  
RA = (pmidA, orderA, lastA, init1A, init2A, suffA, coauthA, titleA, afflA, jrnlA, langA, meshA),  
RB = (pmidB, orderB, lastB, init1B, init2B, suffB, coauthB, titleB, afflB, jrnlB, langB, meshB),  
The similarity profile x = (x1, x2, x3, x4, x5, x6, x7, x8, x9) is created by comparing the two records element wise as follows:

x1 = 3 if init2A = init2B and both are given (e.g., (A, A)),  
     2 if init2A = init2B and both are not given (i.e., (∅, ∅)),  
     1 if init2A = init2B and one is not given (e.g., (A, ∅)),  
     and 0 if init2A = init2B and both are given (e.g., (A, B)).
     
x2 = 1 if suffA = suffB and both are given (e.g., (Jr, Jr)), and 0 otherwise,

x3 = |titleA ∩ titleB|,

x4 = 1 if jrnlA = jrnlB, and 0 otherwise,

x5 = |coauthA ∩ coauthB|,

x6 = |meshA ∩ meshB|,

x7 = 3 if langA = langB and non-English (e.g., (jpn, jpn)),  
     2 if langA = langB and English (i.e., (eng, eng)),  
     1 if langA ≠ langB and one is English (e.g., (eng, jpn)),  
     and 0 if langA ≠ langB and both are non-English (e.g.,(jpn, fre)).

x8 = |afflA ∩ afflB|,

x9 = 1 if afflA = ∅ or afflB = ∅, and 0 otherwise.


8. Name disambiguation spectral in author citations using a K-way clustering method
作者: Han, H; Zha, HY; Giles, CL
会议: 5th ACM/IEEE Joint Conference on Digital Libraries 会议地点: Denver, CO 会议日期: JUN 07-11, 2005
**宁杰**

1.coauthor names

each co-author name 

2.paper titles

each pre-processed word in the title of a paper

3.publication venue titles

each pre-processed word in the title of a publication venue

for one citation M, construct a vector, M =(α\_1, ·· · ,α\_m), the ith feature in the dataset appears in citation M, $$α\_i$$ is the feature i’s weight. Otherwise, $$α\_i$$ =0.

two types of feature weight assignment:
the usual “TFIDF”;
the normalized “TF” (“NTF”), where $$ntf(i, M)= freq(i, M)/max(freq(i, M))$$ , freq(i,M) refers to the term frequency of feature i in a citation M. max(freq(i, M)) refers to the maximal term frequency of feature i in any citation M. 

Construct citation vectors for each name dataset, and the Gram matrix of the citation vectors represents the pairwise cosine similarities between citations. 

9. On co-authorship for author disambiguation
作者: Kang, In-Su; Na, Seung-Hoon; Lee, Seungwoo; 等.
INFORMATION PROCESSING & MANAGEMENT   卷: 45   期: 1   页: 84-97   出版年: JAN 2009
**宁杰**
方法与12一致，可参考的意义不大。

10. Analysis of named entity recognition and linking for tweets
作者: Derczynski, Leon; Maynard, Diana; Rizzo, Giuseppe; 等.
INFORMATION PROCESSING & MANAGEMENT   卷: 51   期: 2   特刊: SI   页: 32-49   出版年: MAR 2015

11. Efficient Topic-based Unsupervised Name Disambiguation
作者: Song, Yang; Huang, Jian; Councill, Isaac G.; 等.
会议: 7th ACM/IEEE Joint Conference on Digital Libraries 会议地点: Vancouver, CANADA 会议日期: JUN 18-23, 2007

12. Author name disambiguation: What difference does it make in author-based citation analysis?
作者: Strotmann, Andreas; Zhao, Dangzhi
JOURNAL OF THE AMERICAN SOCIETY FOR INFORMATION SCIENCE AND TECHNOLOGY   卷: 63   期: 9   页: 1820-1833   出版年: SEP 2012
**史冬波**
这篇文章主要的贡献在于使用naive的方法和coauthor based disambiguation的方法来比较对科学家排名的影响；使用的消歧义方法是9中的基于网络搜索的方法。我们用不上。但是这个消岐对实证分析的影响的研究思路是可以直接借鉴的，沿着长江学者的一个后续分析。

13. Efficient name disambiguation for large-scale databases
作者: Huang, Jian; Ertekin, Seyda; Giles, C. Lee
会议: 10th European Conference on Principle and Practice of Knowledge Discovery in Databases 会议地点: Berlin, GERMANY 会议日期: SEP 18-22, 2006
**李萌**

没有详述feature，着重在讲DBSCAN聚类算法。


14. Disambiguating Authors in Academic Publications using Random Forests
作者: Treeratpituk, Pucktada; Giles, C. Lee
会议: 9th Annual International ACM/IEEE Joint Conference on Digital Libraries 会议地点: Austin, TX 会议日期: JUN 15-19, 2009
**史冬波**

变量定义：
lnamei = the author’s last name in paperi

fnamei = the author’s first name in paperi

initi = the author’s first initial in paperi

midi = the author’s middle name in paperi, if given

sufi = the author’s suffix in paperi, if given, e.g. “Jr”, “Sr”

coauthi = set of coauthors’ last name in paperi

affi = affiliation of the paperi’s 1st author

titlei = paperi’s title

jouri = paperi’s journal name

langi = paperi’s journal language e.g. English, Chinese

yeari = paperi’s year of publication

meshi = set of mesh terms in the paperi

feature

**author 类** 使用上了论文本身的作者信息

1. firstname similarity

$$auth\_fst = \left\{

\begin{aligned}

0 if fnameA \neq fnameB and both are fullname \\

1 if initA \neq initB and are not both fullname\\

2 if initA = initB and are not both fullname\\

3 if fnameA = fnameB and both are fullname\\

\end{aligned}

\right$$

2. middle name similarity

$$auth\_mid = \left\{

\begin{aligned}

0 if midA, midB are given, and midA \neq midB \\

1 if both midA, midB are not given \\

2 if only one of midA, midB are given\\

3 if midA, midB are given, and midA = midB\\

\end{aligned}

\right$$

3. auth suf:  

$$auth\_suf = \left\{

\begin{aligned}

1 if sufA, sufB are given, and sufA = sufB\\

0, otherwise\\

\end{aligned}

\right$$

4. similarity between the orders of author

$$auth\_ord = \left\{

\begin{aligned}

2 if both authors are the 1st author \\

1 if both authors are the last author \\

2 if only one of midA, midB are given\\

0, otherwise \\

\end{aligned}

\right$$


5. IDF weight of the author last name. IDF is the inverse of the fraction of names in the corpus.

auth\_lname\_idf = log(IDF(lnameA))

IDF(lnameA) = IDF(lnameB) = L/DFlnameA


**Affiliation Similarity** 类别 

6. the jaccard similarity between affA and affB

$$aff_jac = \frac{|affA \cap affB|}{|affA| + |affB|}$$

7. the sum of TFIDF weights of shared terms in affA and affB.

$$aff\_tfidf = \sigma TFIDF(t, affA)×TFIDF(t, affB) $$

where TFIDF(t,S) = log(TF(t,S) + 1) × log(IDF(t)), and TF(t,S) is the frequency of t in S.

8. the soft-TFIDF distance between affA and affB. This is a little bit complicated. It combines the string distance and idf wwights.

https://github.com/anhaidgroup/py_stringmatching/blob/master/py_stringmatching/similarity_measure/soft_tfidf.py
参考此处的函数

**coauthor 类**

9. coauth\_lname\_shared : the number of shared coauthor last names between the two papers.

$$coauth\_lname\_shared = |coauthA \cap coauthB|

10. coauth\_lname\_idf : the sum of IDF values of all shared coauthor last names.

$$coauth\_lname\_idf = \sigma log(IDF(ln))

11. the jaccard similarity between coauthA and coauthB 

$$coauth\_lname\_jac = \frac{|coauthA \cap coauthB |}{|coauthA|+|coauthB|} $$

**concept 类** 原文中使用的pubmed中的 mesh 我们需要使keyword

12. the number of shared mesh terms between the two papers

$$mesh\_shared = |meshA \cap meshB|$$

13. the sum of IDF values of all shared mesh terms

$$mesh\_shared\_idf = sigma log(IDF(t))$$

14.15无法使用

**journal 类**

16. IDF value of the shared journal, if both are published in the same journal.

$$jour\_shared\_idf = \left\{

\begin{aligned}

logIDF(journalA) if journalA = journalB\\

0, otherwise \\

\end{aligned}

\right$$

17.18用不上

**year类**
19. 根据wos和thomson的分类做一个变化型

$$jour_year = \left\{

\begin{aligned}

0,if both are before 2008 \\

1,if one is before 2008 and one is after 2008 \\

2,if both are after 2008 \\

\end{aligned}

\right$$

20. year\_diff 

$$year\_diff = |yearA - yearB|$$

**title类**

21. the jaccard similarity between titleA and titleB

$$title\_shared = \frac{|titleA \cap titleB}{|titleA|+|titleB|}$$




15. Accuracy of simple, initials-based methods for author name disambiguation
作者: Milojevic, Stasa
JOURNAL OF INFORMETRICS   卷: 7   期: 4   页: 767-773   出版年: 2013

```diff
- 下面这个文献比较重要，需要精读
```
16. Citation-based bootstrapping for large-scale author disambiguation
作者: Levin, Michael; Krawczyk, Stefan; Bethard, Steven; 等.
JOURNAL OF THE AMERICAN SOCIETY FOR INFORMATION SCIENCE AND TECHNOLOGY   卷: 63   期: 5   页: 1030-1047   出版年: MAY 2012

17. Author Name Disambiguation for PubMed
作者: Liu, Wanli; Dogan, Rezarta Islamaj; Kim, Sun; 等.
JOURNAL OF THE ASSOCIATION FOR INFORMATION SCIENCE AND TECHNOLOGY   卷: 65   期: 4   页: 765-781   出版年: APR 2014
**李萌**

**Title**
IDF算法

**Affiliation**

**Journal**

**Abstract**
给的比重比较低，因为大多是专有名词，体现不太出个体差异
the Abstract field normally consists of significantly more terms, many of which are not strongly associated with author identity, and hence are not as informative.

**Substance**
很重要
For the Grant and Substance fields, a small amount of similarity is actually evidence of a different grant or a different substance, and hence evidence against having the same author.

**Grant**
很重要
For the Grant and Substance fields, a small amount of similarity is actually evidence of a different grant or a different substance, and hence evidence against having the same author.

**MeSH**
Medical Subject Headings

**Author**
name要满足一下三个条件，简单来说就是姓一定要保证一致，名（第2点）和中间字符（第3点）符合其中之一即可

1.NAMEi.last_name == NAMEj 
2.NAMEi.first_name == NAMEj.initial letter) or NAMEi.last_name .first_name or NAMEi.first_name.first_character == NAMEj _name (the first name information for NAMEj.first_name == NULL or NAMEi.first_name == NAMEj 3. NAMEi.middle_name == NAMEj
middle_name or NAMEi.first_name.variant .middle_name or NAMEi.middle_name.first_character == NAMEj .middle_name == NULL
coauthor的相似度同样借用了IDF的做法
**Date**
year = diff(year1,year2)

18. Using Web Information for Author Name Disambiguation
作者: Pereira, Denilson Alves; Ribeiro-Neto, Berthier; Ziviani, Nivio; 等.
会议: 9th Annual International ACM/IEEE Joint Conference on Digital Libraries 会议地点: Austin, TX 会议日期: JUN 15-19, 2009
会议赞助商: ACM SIGWEB; ACM Speial Intrest Grp Informat Retrieval; IEEE Comp Soc; IEEE
JCDL 09: PROCEEDINGS OF THE 2009 ACM/IEEE JOINT CONFERENCE ON DIGITAL LIBRARIES   丛书: ACM-IEEE Joint Conference on Digital Libraries JCDL   页: 49-58   出版年: 2009


19. Distortive Effects of Initial-Based Name Disambiguation on Measurements of Large-Scale Coauthorship Networks
作者: Kim, Jinseok; Diesner, Jana
JOURNAL OF THE ASSOCIATI
**涵谦**

ShortAff=the number of words in a shorter affiliation name 

initialized match= if the single character is the same as the first letter of the token from the other name

Feature

1.**full name** used to select comparison pairs

pass the pair to a similarity calculation if

(1)all of the unmatched tokens are initialized matches

(2)all tokens in a shorter name find a match in full string format or an ‘initialized match’ with tokens in a longer name

(3)different only with/without a space

(4)different with a partial name or a nickname

(5)different with one alphabetical character

(6)different with permutated name tokens

2.**coauthors**

$$coauthor_names = \left{

\begin{aligned}

1 if share one or more coauthor names in a full given name format\

0.3 if either or both of their coauthor names come with initialized given names and match in their initialized format\

\end{aligned}

\right$$

3.**Affiliation Similarity**
   
   $$\frac{Shareditems}{ShortAff}$$
   
   Adds 0.5 if affiliation names share a zip-code
   
4.**Email similarity**

$$email_similarity = \left{

\begin{aligned}

1 if match in a full string except domain address part\

0 if not match\

\end{aligned}

\right$$

20. **Counting First, Last, or All Authors in Citation Analysis: A Comprehensive Comparison in the Highly Collaborative Stem Cell Research Field**
作者: Zhao, Dangzhi; Strotmann, Andreas
JOURNAL OF THE AMERICAN SOCIETY FOR INFORMATION SCIENCE AND TECHNOLOGY   卷: 62   期: 4   页: 654-676   出版年: APR 2011
**涵谦**

这篇文章是针对高度合作的干细胞研究领域，研究使用first-author counting，last-author counting，all-author counting这三种不同的方法会使得citation analysis（citation ranking，field mapping）产生什么不一样的结果。使用的消歧方法是基于Strot-mann et al. (2009)的一种自动消歧方法。

21. **A boosted-trees method for name disambiguation**
作者: Wang, Jian; Berzins, Kaspars; Hicks, Diana; 等.
SCIENTOMETRICS   卷: 93   期: 2   页: 391-411   出版年: NOV 2012
思路是用于给特定科学家赋值


22. **Construction of a large-scale test set for author disambiguation**
作者: Kang, In-Su; Kim, Pyung; Lee, Seungwoo; 等.
INFORMATION PROCESSING & MANAGEMENT   卷: 47   期: 3   页: 452-465   出版年: MAY 2011

23. Dynamic author name disambiguation for growing digital libraries
作者: Qian, Yanan; Zheng, Qinghua; Sakai, Tetsuya; 等.
INFORMATION RETRIEVAL   卷: 18   期: 5   页: 379-412   出版年: OCT 2015

23. McRae-Spencer D M, Shadbolt N R. Also by the same author: AKTiveAuthor, a citation graph approach to name disambiguation[C]//Proceedings of the 6th ACM/IEEE-CS joint conference on Digital libraries. ACM, 2006: 53-54.

**使用了一个citation graph 联通属性**

24. Exploiting citation networks for large-scale author name disambiguation
Christian Schulz, Amin Mazloumian, Alexander M Petersen, Orion Penner & Dirk Helbing 
EPJ Data Science volume 3, Article number: 11 (2014)

本文没有使用机器学习，而是直接使用了调参的方法，优势在于运算速度。

**coauthor类**

1. 共同作者的数量
$$feature1 =\frac{|Ai \cap Aj|}{min(|Ai|,|Aj|)}$$

**refrence类**

2. $$feature2 = |pi \cap Rj| + |pj \cap Ri|$$ 

pi,pj是否出现在对方的参考文献中

3. $$feature3 = |Ri \cap Rj|$$

**citing 类**

4. $$feature4 = \frac{|Ci \cap Cj|}{min(|Ci|,|Cj|)}

共同被引用次数


## 用到的工具
### rlist
处理list对象的工具
https://renkun-ken.github.io/rlist/



