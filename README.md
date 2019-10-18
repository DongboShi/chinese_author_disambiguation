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
xgboost
randomforest

## 聚类方法

## data pipeline
### 规定pair顺序
### 制作feature
### train model
### predict cluster

#### 使用cv的聚类方法
1. 通过模型预测出每一对pair之间的similarity
2. 通过dbscan聚类
3. 通过cv vote出最符合cv特征的一个cluster
4. 定义超参数$\beta$ 计算cluster内部

#### 不适用cv的聚类方法

### validate 结果
