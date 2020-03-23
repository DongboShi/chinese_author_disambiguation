#final model p r f fp
#save model
import pandas as pd
import gc
a=list(range(2,16))
b=list(range(21,29))
c=list(range(32,38))
d=list(range(39,42))
a.extend(b)
a.extend(c)
a.extend(d)
df = pd.read_csv('/home/stonebird/cad/train_data/train_id_new.csv',usecols=a)
from sklearn.model_selection import train_test_split
train,test=train_test_split(df,test_size=0.3, random_state=3)
train_label = train.iloc[:,0].values.ravel()
train_input = train.iloc[:,1:].values
test_label = test.iloc[:,0].values.ravel()
test_input = test.iloc[:,1:].values

del(df)
del(train)
del(test)
gc.collect()

from xgboost.sklearn import XGBClassifier
from sklearn.metrics import accuracy_score,precision_score,recall_score,f1_score
from sklearn.externals import joblib
clf = XGBClassifier(learning_rate=0.1,n_estimators=3000,max_depth=10,min_child_weight=1,gamma=0.1,
subsample=1,colsample_bytree=0.6,reg_alpha=0.1,seed=27)
clf.fit(train_input,train_label)
joblib.dump(clf, "/home/stonebird/cad/result/xg_final_model.m")
predict_results = clf.predict(test_input)
precision = precision_score(predict_results,test_label)
recall = recall_score(predict_results,test_label)
f1 = f1_score(predict_results,test_label)
with open('/home/stonebird/cad/result/final_model_result.txt','a',encoding='utf-8') as f:
    f.write(str(precision)+'\t'+str(recall)+'\t'+str(f1)+'\n')
    f.flush()

import numpy as np
importances = clf.feature_importances_
colnames=['Feature_authororder', 'Feature_givenname', 'Feature_lName', 'coauthor11', 'coauthor12', 'coauthor21', 'coauthor22', 'coauthor31', 'coauthor32', 'coauthor41', 'coauthor42', 'coauthor51', 'coauthor52', 'year1', 'year2', 'aff11', 'aff12', 'aff21', 'aff22', 'aff31', 'aff32','field1', 'field2', 'field3', 'title1', 'title2', 'title3', 'ref2_new','ref3_new','ref1_new']
indices = np.argsort(importances)[::-1]
with open('/home/stonebird/cad/result/final_model_result.txt','a',encoding='utf-8') as txt:
    for i in indices:
        txt.write('\t'.join([str(colnames[i]),str(importances[i])])+'\n')
        txt.flush()


# from sklearn.externals.joblib import Parallel, delayed

# def param_selection(n_esti):
#     clf = XGBClassifier(learning_rate=0.1,n_estimators=n_esti,max_depth=10,min_child_weight=1,gamma=0.1,
#     subsample=1,colsample_bytree=0.6,reg_alpha=0.1,seed=27)
#     clf.fit(train_input,train_label)
#     predict_results = clf.predict(test_input)
#     f1 = f1_score(predict_results,test_label)
#     with open('./result/xg_param_selection_new.txt','a',encoding='utf-8') as f:
#         f.write(str(n_esti)+'\t'+str(f1)+'\n')
#         f.flush()
#     print('move on!')

# Parallel(n_jobs=5)(delayed(param_selection)(n_esti) for n_esti in [1000,2000,3000,4000,5000])
# clf = XGBClassifier(learning_rate=0.2,n_estimators=1800,max_depth=10,min_child_weight=1,
# gamma=0.1,subsample=1,colsample_bytree=0.7,reg_alpha=0,reg_lambda=1,seed=27)
# train=train[0:int(0.4*len(train))]
# test=test[0:int(0.4*len(test))]
# train_label = train.iloc[:,2].values.ravel()
# train_input = train.iloc[:,list(range(3,42))].values
# test_label = test.iloc[:,2].values.ravel()
# test_input = test.iloc[:,list(range(3,42))].values

# param_grid = {'max_depth':range(3,10,2),'min_child_weight':range(1,6,2)}
# clf = XGBClassifier(learning_rate=0.2,n_estimators=2000)
# grid_search = GridSearchCV(clf, param_grid, cv=2, scoring='f1')
# grid_search.fit(train_input,train_label)
# print('best_params_')
# print(grid_search.best_params_)

# clf = XGBClassifier()
# clf.fit(test_input,test_label)
# predict_results=clf.predict(test_input)
# accuracy = accuracy_score(test_label,predict_results)
# f1 = f1_score(test_label,predict_results)
# # print(accuracy)
# # print(f1)
# # conf_mat = confusion_matrix(test_label.values.ravel(),predict_results)
# # print(conf_mat)
# # print(classification_report(test_label.values.ravel(),predict_results))
# # #保存模型
# # #预测全体
# # #输出不同id的表现
# # #输出importance

# with open('model_selection.txt','a',encoding='utf-8') as txt:
#     txt.write('\t'.join(['XGBClassifier',str(accuracy),str(f1)])+'\n')
# print('FINISH XGB!')