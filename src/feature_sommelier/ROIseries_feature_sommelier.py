#+
#  ROIseries_feature_somelier: Assess the value of features from ROIseries for a given machine learning problem
#  Copyright (C) 2017 Niklas Keck
#
#  This file is part of ROIseries.
#
#  ROIseries is free software: you can redistribute it and/or modify
#  it under the terms of the GNU Affero General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  ROIseries is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU Affero General Public License for more details.
#
#  You should have received a copy of the GNU Affero General Public License
#  along with ROIseries.  If not, see <http://www.gnu.org/licenses/>.
#-

import pandas as pd
from scipy import interp
import numpy as np
import matplotlib.pyplot as plt
import copy as cp
import seaborn as sns
import itertools
from astropy.time import Time
import tempfile
import datetime

from imblearn.over_sampling import (SMOTE,
                                    RandomOverSampler)

from sklearn.preprocessing import Imputer
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import StratifiedKFold
from sklearn.metrics import (roc_curve, 
                             roc_auc_score,
                             precision_recall_curve,
                             confusion_matrix,
                             cohen_kappa_score)

class ROIseries_feature_sommelier(object):
    # static variables
    ran_stat = 42
    folds = 2
    n_trees = 50
    messages = True
    n_jobs = -1
    
    '''
    this method takes two lists holding sublists of internally unequal (e.g. x_list[k] to x_list[k+1]) 
    but between each other pairwise equal length. It returns 3 lists: mean_x_list, mean_y_list, std_y_list
    '''
    @staticmethod
    def interpol(x,y,correct_first_last = False):
 
        mean_x = np.linspace(0, 1, 100)
        
        # 1. interpolate the x/y values to the regular spacing defined by x coordinates (mean_x)
        # interpol holds y values at positions mean_x
        interpol = [interp(mean_x, x_i, y_i) for x_i,y_i in zip(x,y)]
        interpol = (np.array(interpol))
        
        # 2. calculate the sum and normalize by length of x
        mean_y = np.sum(interpol,axis=0) / len(x)
        if correct_first_last == True:
            mean_y[0] = 0.0 # is this correct
            mean_y[-1] = 1.0 # is this correct
                              
        # 3. standard deviation (using broadcasting!!! http://www.scipy-lectures.org/intro/numpy/operations.html)
        var_y = np.sum(((interpol - mean_y)**2),axis=0) / len(x)
        std_y = np.sqrt(var_y)
        
        # return results
        return mean_x, mean_y, std_y
    
    @staticmethod
    def interpolate_pr(pr,rec):
        prInv = np.fliplr([pr])[0]
        recInv = np.fliplr([rec])[0]
        j = rec.shape[0]-2
                     
        while j>=0:
            if prInv[j+1]>prInv[j]:
                prInv[j]=prInv[j+1]
            j=j-1
                
        decreasing_max_precision = np.maximum.accumulate(prInv[::-1])[::-1]
        # plt.plot(rec,pr)
        # plt.plot(recInv,decreasing_max_precision)
        return decreasing_max_precision, recInv
    
    @staticmethod
    def measures(confusion_matrix):
        # some measure from confusion_matrix
        FP,FN = np.float64(confusion_matrix[1,0]),np.float64(confusion_matrix[0,1])
        TP,TN = np.float64(confusion_matrix[0,0]),np.float64(confusion_matrix[1,1])
        nP = TP + FN
        nN = TN + FP
        result = {"true_negative_rate":TN / nN,
                  "recall":TP / nP,
                  "precision": TP /(TP + FP),
                  "overall_acc": (TP + TN) / (nP +nN),
                  "deviation":((TP + FP - nP)/nP)} # custom measure: fractional deviation from number of positive: This needs to be minimized!!!
                  # deviation = ((FP + TP)/np) - (np/np) = ((FP + TP)/np) - 1
        
        result["F"] = (2 * result["precision"] * result["recall"])/(result["precision"] + result["recall"])
        result["G"] = (result["true_negative_rate"] * result["recall"])**0.5
        return result
    
    @staticmethod
    def read_features_and_groundtruth(features_csv,scene_properties_csv):
        #----------------------------------------------------------
        #   Read features output from ROIseries
        df = [pd.read_csv(i, index_col = 0) for i in features_csv]
        df = pd.concat(df,axis=1)
        
        # transpose the features to:
        # -> use the time specified in second part of the the column name in a column
        # -> use the dimensional history in first part of colum name in a colum (e. g. spatial mean, temporal standard deviation)
        df_trans = pd.DataFrame.transpose(df)
        id_variables = ['dimensional_history','time']
        df_trans_infos = (df_trans.index).str.rsplit("_",1)
        df_trans_infos_df = pd.DataFrame(df_trans_infos.tolist())
        df_trans_infos_df.columns = id_variables
        df_trans_infos_df['time']=pd.to_numeric(df_trans_infos_df['time']) 
        df_trans_infos_df.index = df_trans.index
        temp=df_trans.join(df_trans_infos_df)
        long_format = pd.melt(temp,id_vars=id_variables)
        long_format=long_format.rename(columns ={"variable":"id"})
        long_format["id_time"]=[str(i)+"_"+"{:.10f}".format(t) for i,t in zip((long_format["id"]).tolist(),(long_format["time"]).tolist())]
        long_format.drop(["time","id"],axis=1,inplace=True)
        
        #  Change format to wide format to have rows X columns = samples X features order
        wide_format=pd.pivot_table(long_format,columns='dimensional_history',index="id_time",values="value")
        temp = [(i.split("_")) for i in wide_format.index]
        wide_format["time"]= [float(i[1]) for i in temp]
        wide_format["id"] = [i[0] for i in temp] 
        
        
        #----------------------------------------------------------
        #   Read ground truth
        scene_properties = pd.read_csv(scene_properties_csv)
        scene_properties.drop("contains_data",axis=1,inplace=True)
        a=((scene_properties['filename'])).str.split("_")
        a_df = pd.DataFrame(a)
        b = (a_df['filename']).apply(pd.Series)
        time_datetime=[datetime.datetime.strptime(i,"%Y%m%dT%H%M%S") for i in b[3]]
        time_astropy = [Time(i,format="datetime") for i in time_datetime]
        scene_properties["time_julian"]=[i.jd for i in time_astropy]
        scene_properties.drop("filename",axis=1,inplace=True)
        
        # convert to integer and round to make join possible
        significant_digits = 6
        scene_properties["time_julian"]=[int(10**significant_digits *i) for i in scene_properties["time_julian"]]
        wide_format["time"]=[int(10**significant_digits *i) for i in wide_format["time"]]
        
        #----------------------------------------------------------
        #  Join ground truth to features and write result to disc
        result = pd.merge(wide_format,scene_properties,how='left',left_on="time",right_on="time_julian",sort=False)
        result.index=list(zip(result["id"],(result["time"])*(10**-significant_digits)))
        result.drop(["time","time_julian"],axis=1,inplace=True)
        
        outcsv = tempfile.gettempdir()+"\\temporary.csv"
        result.to_csv(outcsv)
        return(outcsv)
        
    def __init__(self, csv, class_column, strata_column, positive_classname):
        # read in data
        df = pd.read_csv(csv, index_col = 0)
        self.y = df[class_column]
        self.strata = df[strata_column]
        df_reduced = df.drop([class_column,strata_column,'X.y'],axis = 1)
        self.id = df_reduced.index
        self.feature_names = df_reduced.columns
        self.X = df_reduced.values
        self.positive = positive_classname
        
    def impute_missing(self):       
        # impute missing values with mean (Optimization possible)
        imp = Imputer(missing_values='NaN', strategy='mean', axis=0)   
        self.X = imp.fit_transform(self.X)
        if self.messages == True:
            print("missing NaN imputed with column mean")
    
    def SMOTE(self):
        X,y = self.X,self.y
        if self.messages == True:
            print("Of full sample %s, %s are True" %(len(y),len((np.where(y))[0])))
        # set strata to None since it is not clear of what strata the newly generated samples are
        self.strata = None
        sm = SMOTE(random_state = self.ran_stat)
        self.X,self.y = sm.fit_sample(X,y)
        if self.messages == True:
            print("Of full sample %s, %s are True" %(len(self.y),len((np.where(self.y))[0])))
    
    def select_strata(self,stratum):
        positions = (np.where(self.strata == stratum)[0])
        newObject = cp.deepcopy(self)
        newObject.X = self.X[positions]
        newObject.y = self.y[positions]
        return newObject
    
    def select_features(self,feature_string,exclude = False):
        feat = self.feature_names
        full_indices = range(len(feat))        
        select_indices = [c for c,i in enumerate(feat) if feature_string in i]
        if exclude:
            indices = [i for i in full_indices if i not in select_indices]
        else:
            indices = select_indices        
        new_object = cp.deepcopy(self)
        new_object.X = ((new_object.X)[:,indices])
        new_object.feature_names = feat[indices]        
        return(new_object)
    
    def select_by_feature_range(self,feature,minimum,maximum):
        # create indices
        names = self.feature_names
        column = np.argmax(names == feature)
        data = self.X[:,column]
        indices = (np.where(np.logical_and(data >= minimum,data <= maximum)))[0]
        
        # make subset and return
        new_object = cp.deepcopy(self)
        new_object.X = self.X[indices,:]
        new_object.y = self.y[indices]
        new_object.strata = self.strata[indices]
        return new_object
        
    def RF_cv_by_strata(self):
        """ Train on own data, test on other data """
        # set up randomForest
        rf = RandomForestClassifier(random_state = self.ran_stat, n_estimators = self.n_trees, n_jobs=self.n_jobs) 
        
        # REPLACE all_all with self!
        strata = set(all_all.strata) 
        #strata_indices = [np.where(all_all.strata == s) for s in strata]
        
        res_dict = {}
        for i in itertools.permutations(strata,r=2):
            o1 = all_all.select_strata(i[0])
            o2 = all_all.select_strata(i[1])
            rf.fit(o1.X,o1.y)
            y_probability = rf.predict_proba(o2.X)
            y_predicted = rf.predict(o2.X)
            res_dict[i] = zip(y_predicted,y_probability)
            
    def RF_predict_other(self,other_object):
        y_probability = (self.rf).predict_proba(other_object.X)
        y_predicted = (self.rf).predict(other_object.X)
        return y_predicted,y_probability
        
    def CV(self,upsampling = True,method = "RANDOM", impute_missing = True):
        """ Train and test on own data """
        rf = RandomForestClassifier(random_state = self.ran_stat, n_estimators = self.n_trees, n_jobs=self.n_jobs) 
        skf = StratifiedKFold(n_splits = self.folds, random_state = self.ran_stat)

        y_probability = []
        y_predicted = []
        y_true = []
        feature_importance = [] 
        for c,(train_index, test_index) in enumerate(skf.split(self.X, self.y)):

            if self.messages == True:
                print("Fold %s/%s" %(c,self.folds))
            # Choose training / testing subsets      
            X_train, X_test = self.X[train_index], self.X[test_index]
            y_train, y_test = self.y[train_index], self.y[test_index]
            
            # impute missing values for test and training set individually
            if impute_missing == True:
                imp = Imputer(missing_values='NaN', strategy='mean', axis=0)
                X_train = imp.fit_transform(X_train)
                X_test = imp.fit_transform(X_test)
            elif ~(np.isfinite(self.X)).all():
                raise "All values need to be finite. NaN not allowed."
            
            # Do the upsampling ONLY!! for the training data
            if upsampling == True:
                if method == "SMOTE":                                     
                    sm = SMOTE(random_state = self.ran_stat)
                    X_train,y_train = sm.fit_sample(X_train,y_train)
                elif method == "RANDOM":
                    ros = RandomOverSampler(random_state = self.ran_stat)
                    X_train,y_train = ros.fit_sample(X_train,y_train)
            else:
                "no upsampling was done, please ensure equal number of samples for each class"
            
            # fit to data
            rf.fit(X_train,y_train)
            
            # apply to test data
            index_positive = np.where(rf.classes_ == self.positive)
            y_probability.append(((rf.predict_proba(X_test))[:,index_positive]).ravel())
            y_predicted.append(rf.predict(X_test))
            y_true.append(y_test.ravel())
           
            # add feature importance
            feature_importance.append(rf.feature_importances_ )
        
        # save the resulting list with length = cv folds
        self.y_probability = y_probability
        self.y_predicted = y_predicted
        self.y_true = y_true
        self.feature_importance = feature_importance
        
        # make further metrics per fold
        self.conf_matrix = [confusion_matrix(t, p, labels =[True,False]) for t,p in zip(self.y_true,self.y_predicted)]
        
        # performance measures
        kappa = [cohen_kappa_score(p,t, labels =[True,False]) for p,t in zip(self.y_predicted, self.y_true)]
        conf_measures = [self.measures(m) for m in self.conf_matrix]
        for m,k in zip(conf_measures,kappa):
            m["kappa"]=k
        self.performance_measures = conf_measures
        
        # ROC curve
        temp_roc_curve = [roc_curve(t,p,pos_label = True) for t,p in zip(self.y_true, self.y_probability)]
        self.roc_curve = [dict(zip(["fpr","tpr","thresholds"],i)) for i in temp_roc_curve]
        self.roc_auc = [roc_auc_score(t,p) for t,p in zip(self.y_true, self.y_probability)]
        
        # precision, recall curve
        temp_pr_curve = [precision_recall_curve(t,p,pos_label = True) for t,p in zip(self.y_true, self.y_probability)]
        self.pr_curve = [dict(zip(["precision","recall","thresholds"],i)) for i in temp_pr_curve]
        
    def plot_feature_importance(self,path=None,threshold = 0.5, number = 20, method = "count", get_data = False, scale_importance = 1):
        
        importance = self.feature_importance
        names = self.feature_names
        
        # 1. sort the data descending (most important first)
        imp_mean = (np.mean(importance,axis=0))*scale_importance
        order = np.argsort(imp_mean)[::-1]
        imp_mean_descending = imp_mean[order]
        names_descending = names[order]
        
        # 2. select using method
        if method == "count":
            imp = imp_mean_descending[0:number]
            nam = names_descending[0:number]
        elif method == "fraction":
            index = np.argmax(imp_mean_descending>threshold)
            imp = imp_mean_descending[0:index]
            nam = names_descending[0:index]
        else:
            print("please use method 'count' or 'fraction'")
            return 0
        
        if get_data == False:
            sns.set(style="whitegrid")
            f, ax = plt.subplots(figsize=(6, 15))
            sns.set_color_codes("pastel")
            sns.barplot(x=imp, y=nam, color="black")#, data=crashes,label="Total", color="b")
            # ax.legend(ncol=2, loc="lower right", frameon=True)
            if path != None:
                plt.savefig(path,dpi=300)
            plt.show()
            #plt.close()
            #ax.set(xlim=(0, 24), ylabel="",
            #      xlabel="")
            #sns.despine(left=True, bottom=True)
        else:
            return pd.DataFrame({"variable_importance":imp,"variable_names":nam}) # if get_data = true, do not plot but return data needed for plot!
        
    def plot_roc(self,mean=True,path=None,get_data = False):
        
        if mean == True:
            fpr = [i['fpr'] for i in self.roc_curve]
            tpr = [i['tpr'] for i in self.roc_curve]
            mean_fpr, mean_tpr, std_tpr = self.interpol(fpr,tpr,correct_first_last=True)
            mean_auc = np.mean(self.roc_auc)
        else:
            print("not implemented yet")
            return
        
        if get_data == False:
            # create plots
            plt.errorbar(mean_fpr,mean_tpr,yerr =std_tpr, label='ROC: mean & standard deviation over CV (area = %0.2f)'%mean_auc)
            plt.plot([0, 1], [0, 1], linestyle='--', color='k',
                     label='Luck')  
            plt.xlabel('False Positive Rate')
            plt.ylabel('True Positive Rate')
            plt.legend(loc='lower right')
            if path != None:
                plt.savefig(path,dpi=300)
            plt.show()
        else:
            return pd.DataFrame({"mean_fpr":mean_fpr,"mean_tpr":mean_tpr,"std_tpr":std_tpr})
        
        
    
    def plot_pr(self,mean=True,path=None,get_data = False):
        recall = [i['recall'] for i in self.pr_curve]
        precision = [i['precision'] for i in self.pr_curve]
        
        # 1. interpolate values according to: 
            # http://nlp.stanford.edu/IR-book/html/htmledition/evaluation-of-ranked-retrieval-results-1.html
            # implementation: http://stackoverflow.com/questions/39836953/how-to-draw-a-precision-recall-curve-with-interpolation-in-python
        precision2, recall2 = zip(*[self.interpolate_pr(p,r) for p,r in zip(precision,recall)])
        
        if mean == True:
            mean_x, mean_y, std_y = self.interpol(recall2,precision2)
            if get_data == False:
                plt.errorbar(mean_x,mean_y,yerr =std_y, label='PR: mean & standard deviation over CV')
                plt.xlabel('recall')
                plt.ylabel('precision')
                plt.legend(loc='lower right')
                if path != None:
                    plt.savefig(path,dpi=300)
                plt.show()
            else:
                return pd.DataFrame({"mean_recall":mean_x,"mean_precision":mean_y,"std_precision":std_y})
            
            #mean_recall, mean_precision, std_precision = self.interpol(recall,precision)
        else:
            # create plots
            if get_data == False:
                for p,r in zip(precision2,recall2):
                    plt.plot(r,p)
                    plt.xlabel('Recall')
                    plt.ylabel('Precision')
                    plt.legend(loc='lower right')
                    if path != None:
                        plt.savefig(path,dpi=300)
                    plt.show() 
            else:
                return pd.DataFrame({"precision":precision2, "recall":recall2})
    
    def plot_performance(self,mean=True,path=None,get_data=False):
        performance_df=pd.DataFrame(self.performance_measures)
        if mean == True:
            performance_df = performance_df.mean()
        else:
            pass
        
        if get_data == True:
            return performance_df
        else:
            performance_df.plot(kind="bar")