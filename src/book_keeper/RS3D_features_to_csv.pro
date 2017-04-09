;+
;  RS3D_features_to_csv: Output of features from RS3D object directly to csv. Do not call directly.
;  Copyright (C) 2016 Niklas Keck
;
;  This file is part of ROIseries.
;
;  ROIseries is free software: you can redistribute it and/or modify
;  it under the terms of the GNU Affero General Public License as published by
;  the Free Software Foundation, either version 3 of the License, or
;  (at your option) any later version.
;
;  ROIseries is distributed in the hope that it will be useful,
;  but WITHOUT ANY WARRANTY; without even the implied warranty of
;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;  GNU Affero General Public License for more details.
;
;  You should have received a copy of the GNU Affero General Public License
;  along with ROIseries.  If not, see <http://www.gnu.org/licenses/>.
;-

FUNCTION tempfunc1,GLCM,features,imag
    COMPILE_OPT idl2, HIDDEN 
    ; calculation for every direction
    temp=GLCM.map(LAMBDA(glcm,features,imag:glcm_features(glcm,*features,IMG=*imag)),features,imag)
    retL=LIST()
    FOREACH l,temp DO retL.add,l,/EXTRACT,/NO_COPY
    return,retL
END

;+
; Output of features from RS3D object directly to csv. Do not call directly.
;
; :Params:
;    FEATURES
;    CSV
;    SelfData
;
; :Keywords:
;    PREFIX
;
; :Returns:
;
; :Examples:
;
; :Description:
;
;	:Uses:
;
; :Author:
;     Niklas Keck ("niklas_keck'use at instead'gmx.de").replace("'use at instead'","@")
;-
PRO RS3D_features_to_csv,FEATURES,CSV,SelfData,PREFIX=prefix
    COMPILE_OPT idl2, HIDDEN
    !EXCEPT=0 ; Turn of annoying math errors!
    OutList=LIST()
    FeatureNames=LIST()
    dat=(*SelfData).values()
    
    
    FOREACH f,FEATURES DO BEGIN
        CASE f OF
            'MEAN':BEGIN
                temp=dat.map(LAMBDA(x:MEAN(x,/NAN)))
                OutList.add,temp.ToArray(/NO_COPY)
                FeatureNames.add,"mean"
                Print,"mean calculated"
            END
                
            'STD':BEGIN
                temp=dat.map(LAMBDA(x:STDDEV(x,/NAN)))
                OutList.add,temp.ToArray(/NO_COPY)
                FeatureNames.add,"std"
                Print,"std calculated"
            END
           
            'COUNT':BEGIN
                temp=dat.map(LAMBDA(x:N_ELEMENTS(x[WHERE(FINITE(x))])))
                OutList.add,temp.ToArray(/NO_COPY)
                FeatureNames.add,"count"
                Print,"count calculated"
            END
                    
            'MIN':BEGIN
                temp=dat.map(LAMBDA(x:MIN(x,/NAN)))
                OutList.add,temp.ToArray(/NO_COPY)
                FeatureNames.add,"min"
                Print,"min calculated"
            END
            
            'MAX':BEGIN ; THIS COULD BE COUPLED WITH MIN
                temp=dat.map(LAMBDA(x:MAX(x,/NAN)))
                OutList.add,temp.ToArray(/NO_COPY)
                FeatureNames.add,"max"
                Print,"max calculated"
            END
            
            'SUM':BEGIN
                temp=dat.map(LAMBDA(x:TOTAL(x,/NAN)))
                OutList.add,temp.ToArray(/NO_COPY)
                FeatureNames.add,"sum"
                Print,"sum calculated"
            END
            
            'MEDIAN':BEGIN 
                temp=dat.map(LAMBDA(x:MEDIAN(x)))
                OutList.add,temp.ToArray(/NO_COPY)
                FeatureNames.add,"median"
                Print,"median calculated"
            END
            
            'GLCM': BEGIN
                featureNames.add,"glcm_"+["con_0","con_45","con_90","con_135","dis_0","dis_45","dis_90","dis_135","hom_0","hom_45","hom_90","hom_135","asm_0","asm_45","asm_90","asm_135","ene_0","ene_45","ene_90","ene_135","max_0","max_45","max_90","max_135","ent_0","ent_45","ent_90","ent_135","mean_0","mean_45","mean_90","mean_135","var_0","var_45","var_90","var_135","std_0","std_45","std_90","std_135","cor_0","cor_45","cor_90","cor_135"],/EXTRACT
                
                ;oritinal copied to delete_2.pro
                GLCM=dat.map(LAMBDA(x:(glcm_matrix(x,[0,45,90,135])).values()))
                print,"GLCM base calculated"
                n=N_ELEMENTS(dat)
                feat_ptr=ptr_new(/ALLOCATE_HEAP)
                *feat_ptr=["CON","DIS","HOM","ASM","ENE","MAX","ENT","MEAN","VAR","STD","COR"]
                FEAT_GLCM=LIST(LIST(feat_ptr,length=4),length=n)
                print,"Feature List compiled"
                
                ; create LIST of ptr to the original objects for each of the 4 directions e. g.: [O1,O2] (OBJECTS) -> [O1,O1,O1,O1,O2,O2,O2,O2] (POINTER)
                IMG_ptrL=LIST()
                FOR i=0,n-1 DO BEGIN &$
                    tempL=LIST() &$
                    tempPtr=PTR_NEW(/ALLOCATE_HEAP) &$
                    *tempPtr=dat[i] &$
                    tempL=LIST(tempPtr,length=4) &$ ; length=4 da 0,45,90,135 => 4 directions
                    IMG_ptrL.add,tempL &$
                ENDFOR

                Tempo=GLCM.map('tempfunc1',FEAT_GLCM,IMG_ptrL)
            END
            
            ELSE: BEGIN 
                ; calculate percentiles in the else clause to allow differnt percentiles specified by the first two letters:
                IF f.StartsWith('PERCENTILE') THEN BEGIN
                    perc = FLOAT((f.split('_'))[1])
                    temp=dat.map(LAMBDA(x,perc:PERCENTILE_RS(x,perc)),perc)
                    OutList.add,temp.ToArray(/NO_COPY)
                    FeatureNames.add,f
                    print,f," calculated"
                ENDIF ELSE BEGIN
                    MESSAGE,f," will not be calculated since it is not a vaild option"
                ENDELSE
                
            ENDELSE
        ENDCASE
    ENDFOREACH
    
    ; create results folder if it does not exist
    IF FILE_TEST(FILE_DIRNAME(CSV),/DIRECTORY) EQ 0 THEN FILE_MKDIR,FILE_DIRNAME(CSV)
    
    ; add prefix to each column so that the import into the SQL database works.
    IF N_ELEMENTS(PREFIX) GT 0 THEN BEGIN
        Cnames=(((prefix+["ID",featureNames.ToArray()])).join(","))
    ENDIF ELSE BEGIN
        Cnames=((["ID",featureNames.ToArray()]).join(","))
    ENDELSE
    
    Rnames=((*selfdata).keys()).ToArray()
    
    IF N_ELEMENTS(OutList) NE 0 && N_ELEMENTS(Tempo) NE 0 THEN x="c1"
    IF N_ELEMENTS(OutList) EQ 0 && N_ELEMENTS(Tempo) NE 0 THEN x="c2"
    IF N_ELEMENTS(OutList) NE 0 && N_ELEMENTS(Tempo) EQ 0 THEN x="c3"
    
    CASE x of
        "c1":data=[OutList.ToArray(/NO_COPY),Tempo.ToArray(/TRANSPOSE,/NO_COPY)]
        "c2":data=Tempo.ToArray(/NO_COPY,/TRANSPOSE)
        "c3":data=OutList.ToArray(/NO_COPY)
    ENDCASE   
  
    WRITE_CSV_PY,Cnames,Rnames,data,csv
  
    !EXCEPT=1 ; reanable annoying math errors
END