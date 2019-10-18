# chinese_author_disambiguation
the project is to disambiguate the Chinese authors of web of science articles 

## 备选的feature

每个feature 注明参考文献来源

### coauthor 类
### reference 和citation 类
### journal 类
### year 类
### affiliation 类
### keywords 类
### title 类
### 其他 类

## 模型选择
理论上我们会尝试所有类型的模型

xgboost

randomforest

## 聚类方法

## data pipeline
### 规定pair顺序
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

6. Author Name Disambiguation in MEDLINE
作者: Torvik, Vetle I.; Smalheiser, Neil R.
ACM TRANSACTIONS ON KNOWLEDGE DISCOVERY FROM DATA
Author Name Disambiguation in MEDLINE，Torvik, Vetle I.; Smalheiser, Neil R. ACM TRANSACTIONS ON KNOWLEDGE DISCOVERY FROM DATA,2009

7. A probabilistic similarity metric for Medline records: A model for author name disambiguation
作者: Torvik, VI; Weeber, M; Swanson, DR; 等.
JOURNAL OF THE AMERICAN SOCIETY FOR INFORMATION SCIENCE AND TECHNOLOGY

8. Name disambiguation spectral in author citations using a K-way clustering method
作者: Han, H; Zha, HY; Giles, CL
会议: 5th ACM/IEEE Joint Conference on Digital Libraries 会议地点: Denver, CO 会议日期: JUN 07-11, 2005

9. On co-authorship for author disambiguation
作者: Kang, In-Su; Na, Seung-Hoon; Lee, Seungwoo; 等.
INFORMATION PROCESSING & MANAGEMENT   卷: 45   期: 1   页: 84-97   出版年: JAN 2009

10. Analysis of named entity recognition and linking for tweets
作者: Derczynski, Leon; Maynard, Diana; Rizzo, Giuseppe; 等.
INFORMATION PROCESSING & MANAGEMENT   卷: 51   期: 2   特刊: SI   页: 32-49   出版年: MAR 2015

11. Efficient Topic-based Unsupervised Name Disambiguation
作者: Song, Yang; Huang, Jian; Councill, Isaac G.; 等.
会议: 7th ACM/IEEE Joint Conference on Digital Libraries 会议地点: Vancouver, CANADA 会议日期: JUN 18-23, 2007

12. Author name disambiguation: What difference does it make in author-based citation analysis?
作者: Strotmann, Andreas; Zhao, Dangzhi
JOURNAL OF THE AMERICAN SOCIETY FOR INFORMATION SCIENCE AND TECHNOLOGY   卷: 63   期: 9   页: 1820-1833   出版年: SEP 2012

13. Efficient name disambiguation for large-scale databases
作者: Huang, Jian; Ertekin, Seyda; Giles, C. Lee
会议: 10th European Conference on Principle and Practice of Knowledge Discovery in Databases 会议地点: Berlin, GERMANY 会议日期: SEP 18-22, 2006

14. Disambiguating Authors in Academic Publications using Random Forests
作者: Treeratpituk, Pucktada; Giles, C. Lee
会议: 9th Annual International ACM/IEEE Joint Conference on Digital Libraries 会议地点: Austin, TX 会议日期: JUN 15-19, 2009

15. Accuracy of simple, initials-based methods for author name disambiguation
作者: Milojevic, Stasa
JOURNAL OF INFORMETRICS   卷: 7   期: 4   页: 767-773   出版年: 2013

16. Citation-based bootstrapping for large-scale author disambiguation
作者: Levin, Michael; Krawczyk, Stefan; Bethard, Steven; 等.
JOURNAL OF THE AMERICAN SOCIETY FOR INFORMATION SCIENCE AND TECHNOLOGY   卷: 63   期: 5   页: 1030-1047   出版年: MAY 2012

17. Author Name Disambiguation for PubMed
作者: Liu, Wanli; Dogan, Rezarta Islamaj; Kim, Sun; 等.
JOURNAL OF THE ASSOCIATION FOR INFORMATION SCIENCE AND TECHNOLOGY   卷: 65   期: 4   页: 765-781   出版年: APR 2014

18. Using Web Information for Author Name Disambiguation
作者: Pereira, Denilson Alves; Ribeiro-Neto, Berthier; Ziviani, Nivio; 等.
会议: 9th Annual International ACM/IEEE Joint Conference on Digital Libraries 会议地点: Austin, TX 会议日期: JUN 15-19, 2009
会议赞助商: ACM SIGWEB; ACM Speial Intrest Grp Informat Retrieval; IEEE Comp Soc; IEEE
JCDL 09: PROCEEDINGS OF THE 2009 ACM/IEEE JOINT CONFERENCE ON DIGITAL LIBRARIES   丛书: ACM-IEEE Joint Conference on Digital Libraries JCDL   页: 49-58   出版年: 2009

19. Distortive Effects of Initial-Based Name Disambiguation on Measurements of Large-Scale Coauthorship Networks
作者: Kim, Jinseok; Diesner, Jana
JOURNAL OF THE ASSOCIATI

20. **Counting First, Last, or All Authors in Citation Analysis: A Comprehensive Comparison in the Highly Collaborative Stem Cell Research Field**
作者: Zhao, Dangzhi; Strotmann, Andreas
JOURNAL OF THE AMERICAN SOCIETY FOR INFORMATION SCIENCE AND TECHNOLOGY   卷: 62   期: 4   页: 654-676   出版年: APR 2011

21. **A boosted-trees method for name disambiguation**
作者: Wang, Jian; Berzins, Kaspars; Hicks, Diana; 等.
SCIENTOMETRICS   卷: 93   期: 2   页: 391-411   出版年: NOV 2012
Two supervised learning approaches for name disambiguation in author citations

22. **Construction of a large-scale test set for author disambiguation**
作者: Kang, In-Su; Kim, Pyung; Lee, Seungwoo; 等.
INFORMATION PROCESSING & MANAGEMENT   卷: 47   期: 3   页: 452-465   出版年: MAY 2011

23. Dynamic author name disambiguation for growing digital libraries
作者: Qian, Yanan; Zheng, Qinghua; Sakai, Tetsuya; 等.
INFORMATION RETRIEVAL   卷: 18   期: 5   页: 379-412   出版年: OCT 2015



