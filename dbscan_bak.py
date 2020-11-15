from sklearn.cluster import DBSCAN
#from sklearn.metrics import accuracy_score,precision_score,recall_score,f1_score
from sklearn.externals import joblib
from sklearn.externals.joblib import Parallel, delayed
import pandas as pd
import numpy as np
import random
import json
import os

id_list = pd.read_csv('/data/home/ningjie/cad/train_data/id_0201.csv')
id_list = id_list.iloc[:,0].values.ravel()
id_list = list(id_list)
# id_list.remove(198)
# id_list.remove(1448)
# id_list.remove(104)
# id_list.remove(1021)
# id_list.remove(423)
# id_list.remove(1)
# id_list.remove(7)


# id_less_100 = open('/home/ningjie/cad/train_data/id_less_100.txt','r',encoding='utf-8').readlines()
# id_less_100 = id_less_100[0].split('/n')
# id_less_100.remove('')
#id_less_100=[249,707,783,556,31]

#id_tmp=[1448,104,1021,423]

# fl=os.listdir('/home/ningjie/cad/result/db_txt_new/folder_0.001_20')
# fl=[x.split('.')[0] for x in fl]
# id_less_100=[x for x in id_less_100 if x not in fl]

def xg_distance(n,m):
    a=ut[int(n)]
    b=ut[int(m)]
    if a==b:
        distance = 0
    else:
        pair1=''+str(a)+str(b)
        train=similarity[similarity['ut_pair'].isin([pair1])]
        if len(train)==0:
            pair2=''+str(b)+str(a)
            train=similarity[similarity['ut_pair'].isin([pair2])]
        distance=train.iloc[0,2]
    return(distance)

def id_parallel(i):
    id = str(i)
    with open('/data/home/ningjie/cad/inputdata/CJ_'+id+'.json',encoding = 'utf-8') as f:
        data = json.load(f)
    papers=data['papers']
    global ut
    ut=list(papers.keys())
    with open('/data/home/ningjie/cad/truth/Exact_'+id+'.json',encoding = 'utf-8') as f:
        truth=json.load(f)
    truth=truth['ID:'+id]['Papers']
    cluster_label=[1 if x in truth else 0 for x in ut]
    global similarity
    similarity = pd.read_csv('/data/home/ningjie/cad/similarity_check/predict_'+id+'.csv')
    # similarity = similarity.iloc[:,[0,1,2]]
    # similarity['0']=similarity['0'].apply(lambda x:x[0:19])
    # similarity['1']=similarity['1'].apply(lambda x:x[0:19])
    # similarity['ut_pair']=similarity['0']+similarity['1']
    # similarity.columns=['paperA','paperB','distance','ut_pair']
    # similarity.to_csv('/mnt/disambiguation/cad/feature/similarity_check/predict_'+id+'.csv',index=None)
    num = len(ut)
    X = [[x] for x in range(num)]
    db = dbscan.fit(X)
    predict_label = db.labels_
    predict_label=list(predict_label)
    c={'actual':cluster_label,'predict':predict_label}
    index=list(set(predict_label))
    index.remove(-1)
    if index == []:
        label_final=-1
    else:
        f1_score_ini=0
        label_final=index[0]
        for i in range(len(index)):
            label=index[i]
            result=pd.DataFrame(c)
            result.loc[result.predict==label,'predict']='a'
            result.loc[result.predict!='a','predict']=0
            result.loc[result.predict=='a','predict']=1
            predict_label_new=list(result['predict'].values)
            p_plus_c=[predict_label_new[l]+cluster_label[l] for l in range(len(predict_label_new))]
            p_minus_c=[predict_label_new[l]-cluster_label[l] for l in range(len(predict_label_new))]
            TP = int(p_plus_c.count(2))
            FP = int(p_minus_c.count(1))
            FN = int(p_minus_c.count(-1))
            if TP==0:
                f1_score=0
            else:
                precision_score=TP/(TP+FP)
                recall_score=TP/(TP+FN)
                f1_score=(2*precision_score*recall_score)/(precision_score+recall_score)
            if f1_score>f1_score_ini:
                label_final=label
                f1_score_ini=f1_score
    result=pd.DataFrame(c)
    result.loc[result.predict==label_final,'predict']='a'
    result.loc[result.predict!='a','predict']=0
    result.loc[result.predict=='a','predict']=1
    predict_label_new=list(result['predict'].values)
    p_plus_c=[predict_label_new[l]+cluster_label[l] for l in range(len(predict_label_new))]
    p_minus_c=[predict_label_new[l]-cluster_label[l] for l in range(len(predict_label_new))]
    TP = int(p_plus_c.count(2))
    FP = int(p_minus_c.count(1))
    FN = int(p_minus_c.count(-1))
#    with open('/home/ningjie/cad/result/db_txt_new/folder_'+str(eps)+'_'+str(min_samples)+'/'+id+'.txt','a',encoding='utf-8') as txt:
    with open('/data/home/ningjie/cad/result/db_txt_new/folder_0.0001_3/'+id+'.txt','a',encoding='utf-8') as txt:
        txt.write('\t'.join([str(TP),str(FP),str(FN)])+'\n')
        txt.flush()
    print(id) 

#txt_1 = open('/home/ningjie/cad/result/db_param_new.txt','a',encoding='utf-8')
#0.001 50 不跑了
#eps 0.1,0.2,0.3  minpts 3,20,50
for eps in [0.0001]:
    for min_samples in [3]:
        dbscan = DBSCAN(eps=eps,min_samples=min_samples,metric=lambda n, m: xg_distance(n,m))
        # if not os.path.exists('/data/home/ningjie/cad/result/db_txt_new/folder_'+str(eps)+'_'+str(min_samples)):
        #     os.mkdir('/data/home/ningjie/cad/result/db_txt_new/folder_'+str(eps)+'_'+str(min_samples))
        fl=os.listdir('/data/home/ningjie/cad/result/db_txt_new/folder_0.0001_3')
        fl=[int(x.split('.')[0]) for x in fl]
        id_tmp=[x for x in id_list if x not in fl]
        #id_tmp=id_tmp[0:12]
        Parallel(n_jobs=12)(delayed(id_parallel)(i) for i in id_tmp)
        # fl=os.listdir('/home/ningjie/cad/result/db_txt_new/folder_'+str(eps)+'_'+str(min_samples))
        # TP=0
        # FP=0
        # FN=0
        # for f in fl:
        #     open_txt = open('/home/ningjie/cad/result/db_txt_new/folder_'+str(eps)+'_'+str(min_samples)+'/'+str(f),'r',encoding = 'utf-8').readlines()
        #     list_per = open_txt[0].strip().split('\t')
        #     tp_tmp=int(list_per[0])
        #     fp_tmp=int(list_per[1])
        #     fn_tmp=int(list_per[2])
        #     TP+=tp_tmp
        #     FP+=fp_tmp
        #     FN+=fn_tmp
        # precision_score=TP/(TP+FP)
        # recall_score=TP/(TP+FN)
        # f1_score=(2*precision_score*recall_score)/(precision_score+recall_score)
        # txt_1.write('\t'.join([str(eps),str(min_samples),str(f1_score)])+'\n')
        # txt_1.flush()


