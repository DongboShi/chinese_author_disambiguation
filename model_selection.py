# import pandas as pd
# import gc

# df = pd.read_csv('train_omitna.csv')#,usecols=a)
# from sklearn.model_selection import train_test_split
# train,test=train_test_split(df,test_size=0.5, random_state=3)
# train=train[0:int(0.4*len(train))]
# test=test[0:int(0.4*len(test))]

# train_label = train.iloc[:,2].values.ravel()
# train_input = train.iloc[:,list(range(3,39))].values
# test_label = test.iloc[:,2].values.ravel()
# test_input = test.iloc[:,list(range(3,39))].values
import csv
import random
import gc

feature=[]
with open('./train_omitna.csv') as csvfile:
    csv_reader=csv.reader(csvfile)
    colnames=next(csv_reader)
    for row in csv_reader:
        feature.append(row)

random.shuffle(feature)
feature_input = [row[3:39] for row in feature]
feature_input=[[float(x) for x in row] for row in feature_input]
feature_label=[row[2] for row in feature]
feature_label=[int(x) for x in feature_label]

del(feature)
gc.collect()

train_input=feature_input[0:int(0.2*len(feature_input))]
train_label=feature_label[0:int(0.2*len(feature_label))]

test_input=feature_input[int(0.8*len(feature_input)):]
test_label=feature_label[int(0.8*len(feature_label)):]

del(feature_input)
del(feature_label)
gc.collect()

print('FINISH DATA!')

from sklearn.ensemble import RandomForestClassifier
from sklearn.linear_model.logistic import LogisticRegression
from sklearn.naive_bayes import BernoulliNB
from sklearn.svm import LinearSVC
#from xgboost import XGBClassifier
from sklearn.metrics import accuracy_score,precision_score,recall_score,f1_score
from sklearn.externals import joblib
from sklearn.externals.joblib import Parallel, delayed
#model
clf1 = RandomForestClassifier()
clf2 = LogisticRegression()
clf3 = BernoulliNB()
clf4 = LinearSVC()
model_pool = [clf1,clf2,clf3,clf4]

def model_selection(model):
    clf = model
    clf.fit(train_input,train_label)
    predict_results=clf.predict(test_input)
    f1 = f1_score(test_label,predict_results)
    precision = precision_score(test_label,predict_results)
    recall = recall_score(test_label,predict_results)
    with open('model_selection.txt','a',encoding='utf-8') as txt:
        txt.write('\t'.join([str(model_pool.index(model)),str(precision),str(recall),str(f1)])+'\n')
    print('move on!')

Parallel(n_jobs=4)(delayed(model_selection)(model) for model in model_pool)

# clf = LogisticRegression()
# clf.fit(train_input,train_label)
# predict_results=clf.predict(test_input)
# precision = precision_score(test_label,predict_results)
# recall = recall_score(test_label,predict_results)
# f1 = f1_score(test_label,predict_results)
# with open('model_selection.txt','a',encoding='utf-8') as txt:
#     txt.write('\t'.join(['LogisticRegression',str(precision),str(recall),str(f1)])+'\n')
# print('FINISH LG!')

# clf = BernoulliNB()
# clf.fit(train_input,train_label)
# predict_results=clf.predict(test_input)
# precision = precision_score(test_label,predict_results)
# recall = recall_score(test_label,predict_results)
# f1 = f1_score(test_label,predict_results)
# with open('model_selection.txt','a',encoding='utf-8') as txt:
#     txt.write('\t'.join(['BernoulliNB',str(precision),str(recall),str(f1)])+'\n')
# print('FINISH NB!')

# clf = LinearSVC()
# clf.fit(train_input,train_label)
# predict_results=clf.predict(test_input)
# precision = precision_score(test_label,predict_results)
# recall = recall_score(test_label,predict_results)
# f1 = f1_score(test_label,predict_results)
# with open('model_selection.txt','a',encoding='utf-8') as txt:
#     txt.write('\t'.join(['LinearSVC',str(precision),str(recall),str(f1)])+'\n')
# print('FINISH SVM!')