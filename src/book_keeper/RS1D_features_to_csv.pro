;+
;  RS1D_FEATURES_TO_CSV: Output of features from RS1D object directly to csv. Do not call directly.
;  Copyright (C) 2017 Niklas Keck
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

;+
; Output of features from RS1D object directly to csv. Do not call directly.
;
; :Params:
;    self
;    function_names
;
; :Keywords:
;    CSV_PATH
;
; :Returns:
;
; :Examples:
;
; :Description:
;
; :Uses:
;
; :Author:
;     Niklas Keck ("niklas_keck'use at instead'gmx.de").replace("'use at instead'","@")
;-
PRO RS1D_FEATURES_TO_CSV,self,function_names,CSV_PATH=csv_path
    
    IF function_names.HasValue('RAW') AND N_ELEMENTS(self.time) EQ 0 THEN MESSAGE,"Set time attribute to output RAW features per time step"
    IF N_ELEMENTS(csv_path) EQ 0 THEN csv_path = FILEPATH(self.id+"_features_"+(TIMESTAMP()).replace(":","-")+".csv",ROOT_DIR=self.db,SUBDIRECTORY=['features'])
    IF FILE_TEST(FILE_DIRNAME(csv_path),/DIRECTORY) EQ 0 THEN FILE_MKDIR,FILE_DIRNAME(csv_path)
    
    print,"Features will be written to: "+csv_path
    
    result = ORDEREDHASH() 
    result['ID'] = ((self.data).keys()).ToArray() 
    values = ((self.data).values()).ToArray()
    time = STRTRIM((self.time).ToArray(),2)
    FOREACH f,function_names DO BEGIN
        CASE f OF
            'MEAN': result[f] = MEAN(values,DIMENSION=2,/NAN)
            'STDDEV':result[f] = STDDEV(values,DIMENSION=2,/NAN)
            'MIN':result[f] = MIN(x,DIMENSION=2,/NAN)
            'MAX':result[f] = MAX(x,DIMENSION=2,/NAN)
            'TOTAL':result[f] = TOTAL(x,DIMENSION=2,/NAN)
            'MEDIAN':result[f] = MEDIAN(x,DIMENSION=2) ; NaN automatically treated as missing data in MEDIAN according to documentation
            'RAW': FOR c=0,N_ELEMENTS(time)-1 DO result['RAW_'+time[c]] = values[*,c]
            ELSE: BEGIN
                IF f.StartsWith('PERCENTILE') THEN BEGIN
                    perc = FLOAT((f.split('_'))[1])
                    temp = ((self.data).values()).map(LAMBDA(x,perc:PERCENTILE_RS(x,perc)),perc)
                    result[f]=temp.ToArray(/NO_COPY)
                ENDIF ELSE BEGIN
                    MESSAGE,f," will not be calculated since it is not a vaild option"
                ENDELSE
            ENDELSE
        ENDCASE
    ENDFOREACH
    
    result_structure = result.ToStruct()
    WRITE_CSV,csv_path,result_structure,header=self.id+"_"+(result.keys()).ToArray()
END