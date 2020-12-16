from sklearn.externals.joblib import Parallel, delayed
import hdbscan
from hdbscan import HDBSCAN
import numpy as np
import pandas as pd
import json
import csv
import gc
import os

# id_core = {}
# with open('/data/home/ningjie/cad/train_data/final_id_pair_size.csv','r') as f:
#     row = csv.reader(f, delimiter = ',')
#     next(row)
#     id_list=[]
#     core_list=[]
#     for r in row:
#         id_list.append(r[0])
#         core_list.append(r[4])
    
# del row
# core_unique = list(set(core_list))
# for i in range(len(core_unique)):
#     core_tmp = core_unique[i]
#     tmp = [i for i,x in enumerate(core_list) if x==core_tmp]
#     min_tmp = int(min(tmp))
#     max_tmp = int(max(tmp))+1
#     id_tmp = id_list[min_tmp:max_tmp]
#     id_core[core_tmp] = id_tmp

id_less_100 = open('/data/home/ningjie/cad/train_data/id_less_100.txt','r',encoding='utf-8').readlines()
id_less_100 = id_less_100[0].split('/n')
id_less_100.remove('')

def xg_distance(n,m):
    a=ut[int(n)]
    b=ut[int(m)]
    if a==b:
        distance = 0
    else:
        pair1=''+str(a)+str(b)
        if pair1 in dict_distance.keys():
            distance = dict_distance[pair1]
        else:
            pair2=''+str(b)+str(a)
            distance = dict_distance[pair2]
    return(distance)

def id_parallel(i):
    id = str(i)
    with open('/data/home/ningjie/cad/inputdata/CJ_'+id+'.json',encoding = 'utf-8') as f:
        data = json.load(f)
    papers = data['papers']
    global ut
    ut = list(papers.keys())

    with open('/data/home/ningjie/cad/truth/Exact_'+id+'.json',encoding = 'utf-8') as f:
        truth=json.load(f)
    truth=truth['ID:'+id]['Papers']
    cluster_label=[1 if x in truth else 0 for x in ut]

    global dict_distance
    dict_distance = {}
    with open('/data/home/ningjie/cad/similarity_check/predict_'+id+'.csv','r') as f:
        row = csv.reader(f, delimiter = ',')
        next(row)
        ut_distance = []
        ut_pair = []
        for r in row:
            ut_distance.append(float(r[2]))
            ut_pair.append(r[3])
        del row
        gc.collect()
        for u in range(len(ut_pair)):
            dict_distance[ut_pair[u]] = ut_distance[u]

    num = len(ut)
    X = [[x] for x in range(num)]

    # clusterer = clusterer_fun.fit(X)
    # threshold = pd.Series(clusterer.outlier_scores_).quantile(qua)
    # outliers = list(np.where(clusterer.outlier_scores_ > threshold)[0])
    # y = np.delete(X,outliers)
    # Y = [[x] for x in y]
    # if len(Y) ==  0:
    #     Y = X
    # predict_label = clusterer_fun.fit_predict(Y)
    predict_label = clusterer_fun.fit_predict(X)
    predict_label = list(predict_label)
    index = list(set(predict_label))
    if -1 in index:
        index.remove(-1)
    if index == []:
        label_final = -1
    else:
        f1_score_ini = 0
        label_final = index[0]
        for i in range(len(index)):
            label = index[i]
            predict_label_new = [1 if x == label else 0 for x in predict_label]
            
            p_plus_c = [predict_label_new[l]+cluster_label[l] for l in range(len(predict_label_new))]
            p_minus_c = [predict_label_new[l]-cluster_label[l] for l in range(len(predict_label_new))]
            TP = int(p_plus_c.count(2))
            FP = int(p_minus_c.count(1))
            FN = int(p_minus_c.count(-1))
            if TP == 0:
                f1_score = 0
            else:
                precision_score = TP/(TP+FP)
                recall_score = TP/(TP+FN)
                f1_score = (2*precision_score*recall_score)/(precision_score+recall_score)
            if f1_score > f1_score_ini:
                label_final = label
                f1_score_ini = f1_score

    predict_label_new = [1 if x == label_final else 0 for x in predict_label]
    p_plus_c = [predict_label_new[l]+cluster_label[l] for l in range(len(predict_label_new))]
    p_minus_c = [predict_label_new[l]-cluster_label[l] for l in range(len(predict_label_new))]
    TP = int(p_plus_c.count(2))
    FP = int(p_minus_c.count(1))
    FN = int(p_minus_c.count(-1))

    with open('/data/home/ningjie/cad/result/hdb_txt_248_2/folder_'+str(samples)+'_'+str(eps)+'/'+id+'.txt','w',encoding='utf-8') as txt:
#    with open('/data/home/ningjie/cad/result/hdb_txt_full/folder_'+str(size)+'_'+str(qua)+'/'+id+'.txt','w',encoding='utf-8') as txt:
        txt.write('\t'.join([str(TP),str(FP),str(FN)])+'\n')
        txt.flush()
    print(id)

for samples in [1,5,10,15,20]:
    for eps in [0.0001,0.01,0.1,0.2,0.3]:
        clusterer_fun = hdbscan.HDBSCAN(min_cluster_size=9,min_samples=1,cluster_selection_epsilon=0.0001,gen_min_span_tree=True,metric=lambda n, m: xg_distance(n,m))

        if not os.path.exists('/data/home/ningjie/cad/result/hdb_txt_248_2/folder_'+str(samples)+'_'+str(eps)):
            os.mkdir('/data/home/ningjie/cad/result/hdb_txt_248_2/folder_'+str(samples)+'_'+str(eps))
        folder_tmp = os.listdir('/data/home/ningjie/cad/result/hdb_txt_248_2/folder_'+str(samples)+'_'+str(eps))
        

        # if not os.path.exists('/data/home/ningjie/cad/result/hdb_txt_full/folder_'+str(size)+'_'+str(qua)):
        #     os.mkdir('/data/home/ningjie/cad/result/hdb_txt_full/folder_'+str(size)+'_'+str(qua))
        # folder_tmp = os.listdir('/data/home/ningjie/cad/result/hdb_txt_full/folder_'+str(size)+'_'+str(qua))
        if len(folder_tmp) == 248:
            continue
    #    print('size:'+str(size)+'--'+'qua:'+str(qua))
        
        # for k in id_core.keys():
        #     para_core = int(k)
        #     para_list = id_core[k]
        #     print('para_core:'+str(para_core))
        Parallel(n_jobs=100)(delayed(id_parallel)(i) for i in id_less_100)
        #    print('para_core:'+str(para_core))
        
        fl=os.listdir('/data/home/ningjie/cad/result/hdb_txt_248_2/folder_'+str(samples)+'_'+str(eps))

        #fl=os.listdir('/data/home/ningjie/cad/result/hdb_txt_full/folder_'+str(size)+'_'+str(qua))
        TP=0
        FP=0
        FN=0
        for f in fl:
            open_txt = open('/data/home/ningjie/cad/result/hdb_txt_248_2/folder_'+str(samples)+'_'+str(eps)+'/'+str(f),'r',encoding = 'utf-8').readlines()

            #open_txt = open('/data/home/ningjie/cad/result/hdb_txt_full/folder_'+str(size)+'_'+str(qua)+'/'+str(f),'r',encoding = 'utf-8').readlines()
            list_per = open_txt[0].strip().split('\t')
            tp_tmp=int(list_per[0])
            fp_tmp=int(list_per[1])
            fn_tmp=int(list_per[2])
            TP+=tp_tmp
            FP+=fp_tmp
            FN+=fn_tmp
        if TP==0:
            f1_score = 0
        else:
            precision_score=TP/(TP+FP)
            recall_score=TP/(TP+FN)
            f1_score=(2*precision_score*recall_score)/(precision_score+recall_score)
        with open('/data/home/ningjie/cad/result/hdb_param2_248_id.txt','a',encoding='utf-8') as txt_1:
        #with open('/data/home/ningjie/cad/result/hdb_param_full_id.txt','a',encoding='utf-8') as txt_1:
            #txt_1.write('\t'.join([str(size),str(qua),str(f1_score)])+'\n')
            txt_1.write('\t'.join([str(samples),str(eps),str(f1_score)])+'\n')
            txt_1.flush()
        #print(str(size)+'--'+str(qua)) 


