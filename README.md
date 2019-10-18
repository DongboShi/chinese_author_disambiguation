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
