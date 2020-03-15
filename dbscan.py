from sklearn.cluster import DBSCAN
#from sklearn.metrics import accuracy_score,precision_score,recall_score,f1_score
from sklearn.externals import joblib
from sklearn.externals.joblib import Parallel, delayed
import pandas as pd
import numpy as np
import random
import json
import os
#import sys
import time
start = time.time()

# id_remain = pd.read_csv('/mnt/disambiguation/cad/train_data/id_0201.csv')
# id_remain = id_remain.iloc[:,0].values.ravel()
# id_remain = list(id_remain)
# id_remain.remove(198)
# random.shuffle(id_remain)
# id_remain = id_remain[0:100]
#fl=os.listdir('/home/stonebird/cad/inputdata')
#id_remain=[2,13,18,19,24]

id_less_100 = open('/mnt/disambiguation/cad/train_data/id_less_100.txt','r',encoding='utf-8').readlines()
id_less_100 = id_less_100[0].split('/n')
# fl = os.listdir('/mnt/disambiguation/cad/result/param_txt/folder_0.001_1')
# id_finish = [x.split('.')[0] for x in fl]
# id_less_100 = [x for x in id_less_100 if x not in id_finish]
id_less_100.remove('')


def xg_distance(n,m):
    a=ut[int(n)]
    b=ut[int(m)]
    if a==b:
        distance = 0
    else:
        pair1=''+str(a)+str(b)
        train=similarity[similarity['ut_pair_new'].isin([pair1])]
        if len(train)==0:
            pair2=''+str(b)+str(a)
            train=similarity[similarity['ut_pair_new'].isin([pair2])]
        distance=train.iloc[0,2]
    return(distance)

def id_parallel(i):
    id = str(i)
    with open('/mnt/disambiguation/cad/inputdata/CJ_'+id+'.json',encoding = 'utf-8') as f:
        data = json.load(f)
    papers=data['papers']
    global ut
    ut=list(papers.keys())
    with open('/mnt/disambiguation/cad/truth/Exact_'+id+'.json',encoding = 'utf-8') as f:
        truth=json.load(f)
    truth=truth['ID:'+id]['Papers']
    cluster_label=[1 if x in truth else 0 for x in ut]
    global similarity
    similarity = pd.read_csv('/mnt/disambiguation/cad/feature/similarity_new/predict_'+id+'.csv')
    similarity['0']=similarity['0'].apply(lambda x:x[0:19])
    similarity['1']=similarity['1'].apply(lambda x:x[0:19])
    similarity['ut_pair_new']=similarity['0']+similarity['1']
    num = len(ut)
    X = [[x] for x in range(num)]
    db = dbscan.fit(X)
    predict_label = db.labels_
    predict_label=list(predict_label)
    c={'actual':cluster_label,'predict':predict_label}
    result=pd.DataFrame(c)
    tmp=result.groupby('predict').sum()
    max_label=tmp['actual'].max()
    final=tmp[(tmp['actual']==max_label)].index.values[0]
    result.loc[result.predict==final,'predict']='a'
    result.loc[result.predict!='a','predict']=0
    result.loc[result.predict=='a','predict']=1
    predict_label=list(result['predict'].values)
    p_plus_c=[predict_label[l]+cluster_label[l] for l in range(len(predict_label))]
    p_minus_c=[predict_label[l]-cluster_label[l] for l in range(len(predict_label))]
    TP = int(p_plus_c.count(2))
    FP = int(p_minus_c.count(1))
    FN = int(p_minus_c.count(-1))
    with open('/mnt/disambiguation/cad/result/param_txt/folder_'+str(eps)+'_'+str(min_samples)+'/'+id+'.txt','a',encoding='utf-8') as txt:
        txt.write('\t'.join([str(TP),str(FP),str(FN)])+'\n')
        txt.flush()
    print(id)


txt_1 = open('/mnt/disambiguation/cad/result/dbscan_param.txt','a',encoding='utf-8')

for eps in np.arange(0.001,0.45,0.2):
    for min_samples in range(1,202,100):
        dbscan = DBSCAN(eps=eps,min_samples=min_samples,metric=lambda n, m: xg_distance(n,m))
        os.mkdir('/mnt/disambiguation/cad/result/param_txt/folder_'+str(eps)+'_'+str(min_samples))
        #txt = open('/mnt/disambiguation/cad/result/param_txt/param_'+str(eps)+'_'+str(min_samples)+'.txt','a',encoding='utf-8')
        Parallel(n_jobs=100)(delayed(id_parallel)(i) for i in id_less_100)
        fl=os.listdir('/mnt/disambiguation/cad/result/param_txt/folder_'+str(eps)+'_'+str(min_samples))
        TP=0
        FP=0
        FN=0
        for f in fl:
            open_txt = open('/mnt/disambiguation/cad/result/param_txt/folder_'+str(eps)+'_'+str(min_samples)+'/'+str(f),'r',encoding = 'utf-8').readlines()
            list_per = open_txt[0].strip().split('\t')
            tp_tmp=int(list_per[0])
            fp_tmp=int(list_per[1])
            fn_tmp=int(list_per[2])
            TP=TP+tp_tmp
            FP=FP+fp_tmp
            FN=FN+fn_tmp
        precision_score=TP/(TP+FP)
        recall_score=TP/(TP+FN)
        f1_score=(2*precision_score*recall_score)/(precision_score+recall_score)
        txt_1.write('\t'.join([str(eps),str(min_samples),str(f1_score)])+'\n')
        txt_1.flush()

end = time.time()
print(end-start)      




# import h5py
# import sys
# import numpy as np
# import jieba
# import math
# import random
# from sklearn.cluster import DBSCAN
# from sklearn import metrics
# from sklearn.metrics import accuracy_score,precision_score,recall_score,f1_score
# from joblib import Parallel,delayed
# import json
# from sklearn.ensemble import RandomForestClassifier
# from sklearn.externals import joblib

# clf = XGBClassifier(learning_rate=0.2,n_estimators=1800,max_depth=10,min_child_weight=1,
# gamma=0.1,subsample=1,colsample_bytree=0.7,reg_alpha=0,reg_lambda=1,seed=27)

# import json
# with open('./output/'+name+'.json',encoding = 'utf-8') as f:
#     data = json.load(f)

# import pandas as pd
# df = pd.read_csv('feature_1.csv')#,usecols=a)
# df['ut_pair']=df['paperA']+df['paperB']
# papers=data['papers']
# ut=list(papers.keys())
# n = len(ut)
# X = [[i] for i in range(n)]
# db = dbscan.fit(X)
# predict_label = db.labels_

# with open('./Exact_1.json',encoding = 'utf-8') as f:
#     truth=json.load(f)
# truth=truth['ID:1']['Papers']

# def xg_distance(n,m):
#     ut=list(papers.keys())
#     a=ut[int(n)]
#     b=ut[int(m)]
#     pair1=''+str(a)+str(b)
#     train=df[df['ut_pair'].isin([pair1])]
#     if len(train)==0:
#         pair2=''+str(b)+str(a)
#         train=df[df['ut_pair'].isin([pair2])]
#     train_input=train.iloc[:,list(range(3,39))].values
#     predict_proba = clf.predict_proba(train_input)
#     distance = predict_proba[0][0]
#     return(distance)

# f1 = f1_score(predict_label,cluster_label,average='weighted')

# cluster_label=[1 if x in truth else 0 for x in ut]

# dbscan = DBSCAN(eps=0.345,min_samples=1,metric=lambda n, m: xg_distance(n, m))
# def cluster_function(file_name):
#     predict_labels = []     
#     global data
#     with open('./output/'+name+'.json',encoding = 'utf-8') as f:
#         data = json.load(f)
#     n = len(data.keys())
#     keys = list(data.keys())
#     X = [[i] for i in range(n)]
#     db = dbscan.fit(X)
#     predict_label = db.labels_
#     predict_labels.extend(predict_label)
#     with open('results.txt','a',encoding='utf-8') as txt:
#         for k in range(n):
#             j = keys[int(k)]
#             grandid = data[j]['grandid']
#             label = predict_labels[k]
#             psncode = str(name)+'_'+str(label)
#             txt.write('\t'.join([str(name),str(grandid),str(label),str(psncode)])+'\n')
#             txt.flush()

# Parallel(n_jobs=4)(delayed(cluster_parallel)(name) for name in psnname)

# ut1=df.iloc[:,0].values
# ut1=ut1.tolist()
# ut2=df.iloc[:,1].values
# ut2=ut2.tolist()
# ut1.extend(ut2)
# ut=list(set(ut1))

# clf = XGBClassifier()
# a=list(range(2,16))
# b=list(range(21,29))
# a.extend(b)
# c=list(range(32,38))
# a.extend(c)
# d=list(range(39,42))
# a.extend(d)
# data = pd.read_csv('/home/stonebird/cad/train_data/train_id_new.csv',usecols=a)

# from sklearn.model_selection import train_test_split
# train,test=train_test_split(data,test_size=0.2, random_state=3)
# #test=train1[0:int(0.4*len(train1))]
# test_label = test.iloc[:,0].values.ravel()
# test_input = test.iloc[:,1:].values
# del(data)
# del(train)
# del(test)
# gc.collect()
# clf.fit(test_input,test_label)
# joblib.dump(clf, "/home/stonebird/cad/result/xg_test_model.m")

# start=int(sys.argv[1])
# cluster_label=cluster_label[0:start]
# ut=ut[0:start]

# check_pair = []
# with open('/home/stonebird/cad/train_data/check_pair.txt','a',encoding='utf-8') as txt:
#     for i in range(len(fl)):
#         file_name=fl[i]
#         id=file_name.split('_')[1].split('.')[0]
#         if id not in id_omit:
#             author = pd.read_csv('/home/stonebird/cad/feature/author_full/Feature_author_'+id+'.csv')
#             aff = pd.read_csv('/home/stonebird/cad/feature/all_feature_aff/Feature_aff_'+id+'.csv')
#             for k in range(0,len(author),5000):
#                 if author.iloc[k,0]!=aff.iloc[k,0] or author.iloc[k,1]!=aff.iloc[k,1]:
#                     print(id)
#                     check_pair.extend(id)
#                     txt.write(str(id)+'\n')
#                     txt.flush()
#                     break
#             if id in check_pair:
#                 break
            
#             field = pd.read_csv('/home/stonebird/cad/feature/field_full/field_'+id+'.csv')
#             for k in range(0,len(author),5000):
#                 if author.iloc[k,0]!=field.iloc[k,0] or author.iloc[k,1]!=field.iloc[k,1]:
#                     print(id)
#                     check_pair.extend(id)
#                     txt.write(str(id)+'\n')
#                     txt.flush()
#                     break
#             if id in check_pair:
#                 break
            
#             title = pd.read_csv('/home/stonebird/cad/feature/title_full/title_'+id+'.csv')
#             for k in range(0,len(author),5000):
#                 if author.iloc[k,0]!=title.iloc[k,0] or author.iloc[k,1]!=title.iloc[k,1]:
#                     print(id)
#                     check_pair.extend(id)
#                     txt.write(str(id)+'\n')
#                     txt.flush()
#                     break
#             if id in check_pair:
#                 break

#             year = pd.read_csv('/home/stonebird/cad/feature/year_full/year_'+id+'.csv')
#             for k in range(0,len(author),5000):
#                 if author.iloc[k,0]!=year.iloc[k,0] or author.iloc[k,1]!=year.iloc[k,1]:
#                     print(id)
#                     check_pair.extend(id)
#                     txt.write(str(id)+'\n')
#                     txt.flush()
#                     break
#             if id in check_pair:
#                 break

#             coauthor = pd.read_csv('/home/stonebird/cad/feature/coauthor_fullpair/coauthor_'+id+'.csv')
#             for k in range(0,len(author),5000):
#                 if author.iloc[k,0]!=coauthor.iloc[k,0] or author.iloc[k,1]!=coauthor.iloc[k,1]:
#                     print(id)
#                     check_pair.extend(id)
#                     txt.write(str(id)+'\n')
#                     txt.flush()
#                     break
#             if id in check_pair:
#                 break

#             ref = pd.read_csv('/home/stonebird/cad/feature/ref_full/feature_ref_'+id+'.csv')
#             for k in range(0,len(author),5000):
#                 if author.iloc[k,0]!=ref.iloc[k,0] or author.iloc[k,1]!=ref.iloc[k,1]:
#                     print(id)
#                     check_pair.extend(id)
#                     txt.write(str(id)+'\n')
#                     txt.flush()
#                     break
#             if id in check_pair:
#                 break

# for i in range(len(fl)):
#     file_name=fl[i]
#     id=file_name.split('_')[1].split('.')[0]
#     if id not in id_omit: