import pandas as pd
import gc
from sklearn.model_selection import train_test_split
from xgboost.sklearn import XGBClassifier
from sklearn.metrics import accuracy_score,precision_score,recall_score,f1_score
from sklearn.externals import joblib
from sklearn.externals.joblib import Parallel, delayed

# label=[2]
# aff=list(range(23,29))
# au=list(range(3,6))
# year=list(range(21,23))
# field=list(range(32,35))
# coau=list(range(6,16))
# title=list(range(35,38))
# ref=list(range(16,19))
# email=[38]
# keyword=list(range(29,32))
# journal=list(range(19,21))
#index=[label,aff,au,year,field,coau,title,ref,email,keyword,journal]
#index=[3,22,6,24,26,28,34,37,25,35,38,29,27,4,23,5,18,19,16,14,10,33,12,39,8,36,7,9,21,15,11,13,31,30,32,20,17]
#index=[2, 21, 5, 23, 25, 27, 33, 36, 24, 34, 37, 28, 26, 3, 22, 4, 17, 18, 15, 13, 9, 32, 11, 38, 7, 35, 6, 8, 20, 14, 10, 12, 30, 29, 31, 19, 16]

clf = XGBClassifier(learning_rate=0.2,n_estimators=1800,max_depth=10,min_child_weight=1,
gamma=0.1,subsample=1,colsample_bytree=0.7,reg_alpha=0,reg_lambda=1,seed=27)
# def test(num):
#     index_col=index[0:num]
#     # for i in range(num):
#     #     tmp=index[i]
#     #     index_col.extend(tmp)
#     df = pd.read_csv('train_omitna.csv',usecols=index_col)
#     train,test=train_test_split(df,test_size=0.5, random_state=3)
#     train=train[0:int(0.4*len(train))]
#     test=test[0:int(0.4*len(test))]
#     train_label = train.iloc[:,0].values.ravel()
#     train_input = train.iloc[:,1:].values
#     test_label = test.iloc[:,0].values.ravel()
#     test_input = test.iloc[:,1:].values
#     del(df)
#     del(train)
#     del(test)
#     gc.collect()
#     clf.fit(train_input,train_label)
#     predict_results=clf.predict(test_input)
#     f1 = f1_score(predict_results,test_label)
#     with open('feature.txt','a',encoding='utf-8') as txt:
#         txt.write('\t'.join([str(num-1),str(f1)])+'\n')
#         txt.flush()
#     print('move on!')
# Parallel(n_jobs=10)(delayed(test)(num) for num in range(2,38))






