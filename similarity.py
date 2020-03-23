#from xgboost.sklearn import XGBClassifier
from sklearn.externals import joblib
from sklearn.externals.joblib import Parallel,delayed
import pandas as pd
import numpy as np
import sys
import gc
import xgboost as xgb
#import os

id_remain = pd.read_csv('/mnt/disambiguation/cad/train_data/id_0201.csv')
id_remain = id_remain.iloc[:,0].values.ravel()
id_remain = list(id_remain)

# fl=os.listdir('/mnt/disambiguation/cad/feature/similarity')
# fl=[int(x.split('.')[0].split('_')[1]) for x in fl]

# id_remain=[x for x in id_remain if x not in fl]
bst = xgb.Booster({'nthread':4})
bst.load_model('/mnt/disambiguation/cad/result/xg_final_model_new.model')

#clf = joblib.load("/mnt/disambiguation/cad/result/xg_final_model_new.model")

txt = open('/mnt/disambiguation/cad/train_data/aff_false.txt','a',encoding='utf-8')

start = int(sys.argv[1])
end = int(sys.argv[2])

for i in range(start,end):
#def similarity(i):
    id = str(id_remain[i])
    #id = '1'
    author = pd.read_csv('/mnt/disambiguation/cad/feature/author_full/Feature_author_'+id+'.csv')
    author = author.sort_values(by=['paperA','paperB'])

    aff = pd.read_csv('/mnt/disambiguation/cad/feature/all_feature_aff/Feature_aff_'+id+'.csv')
    if len(aff.columns)!=8:
        txt.write(str(id)+'\n')
        continue
    aff = aff.sort_values(by=['paperA','paperB'])
    aff = aff.iloc[:,2:]

    field = pd.read_csv('/mnt/disambiguation/cad/feature/field_full/field_'+id+'.csv')
    field = field.sort_values(by=['paperA','paperB'])
    field = field.iloc[:,2:]

    title = pd.read_csv('/mnt/disambiguation/cad/feature/title_full/title_'+id+'.csv')
    title = title.sort_values(by=['paperA','paperB'])
    title = title.iloc[:,2:]

    year = pd.read_csv('/mnt/disambiguation/cad/feature/year_full/year_'+id+'.csv')
    year = year.sort_values(by=['paperA','paperB'])
    year = year.iloc[:,2:]

    coauthor = pd.read_csv('/mnt/disambiguation/cad/feature/coauthor_fullpair/coauthor_'+id+'.csv')
    coauthor = coauthor.sort_values(by=['paperA','paperB'])
    if len(coauthor.columns)==13:
        coauthor = coauthor.iloc[:,3:]
    else:
        coauthor = coauthor.iloc[:,2:]

    ref = pd.read_csv('/mnt/disambiguation/cad/feature/ref_full/feature_ref_'+id+'.csv')
    ref = ref.sort_values(by=['paperA','paperB'])
    ref = ref.iloc[:,2:]

    df = pd.concat([author,coauthor,year,aff,field,title,ref],axis=1,ignore_index=True)
    del(author)
    del(aff)
    del(title)
    del(field)
    del(year)
    del(coauthor)
    del(ref)
    gc.collect()

    train_input=df.iloc[:,2:]
    pair_order=df.iloc[:,0:2]
    del(df)
    gc.collect()
    #train_input = train_input.values
    predict_results = bst.predict(xgb.DMatrix(train_input))
    del(train_input)
    gc.collect()

    #pd.DataFrame(y_bst).apply(lambda row: 1 if row[0]>=0.5 else 0, axis=1)

    predict = pd.DataFrame(predict_results)
    predict['distance']=1-predict[0]
    predict=predict.iloc[:,1]
    predict = pd.concat([pair_order,predict],axis=1,ignore_index=True)
    predict['ut_pair']=predict[0]+predict[1]
    del(predict_results)
    gc.collect()
    predict.to_csv('/mnt/disambiguation/cad/feature/similarity_new/predict_'+id+'.csv',index=False)

    print(str(i)+'--'+str(id))

#Parallel(n_jobs=3)(delayed(similarity)(i) for i in range(len(id_remain)))
