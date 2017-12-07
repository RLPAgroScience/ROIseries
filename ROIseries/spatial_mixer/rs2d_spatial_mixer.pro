;+
;  RS_SPATIAL_MIXER: Quantify the distribution of values within each image-object. Do not call directly.
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
; Quantify the distribution of values within each image-object per time step. Do not call directly.
;
; :Params:
;    RS_2D_SELF
;    TYPE
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
FUNCTION RS2D_SPATIAL_MIXER,RS_2D_SELF,TYPE
    COMPILE_OPT idl2, HIDDEN
    
    temp_results = LIST()
    time = LIST()
    
    FOREACH T,TYPE DO BEGIN
            IF (['MEAN','STDDEV','COUNT','MIN','MAX','SUM','MEDIAN']).HasValue(T) THEN time.add,T
        CASE T OF
            ; Simple type:
            'MEAN': temp_results.add, RS_2D_SELF.data.map(LAMBDA(x:MEAN(x,/NAN)))
            'STDDEV': temp_results.add, RS_2D_SELF.data.map(LAMBDA(x:STDDEV(x,/NAN)))
            'COUNT': temp_results.add, RS_2D_SELF.data.map(LAMBDA(x:TOTAL(FINITE(x))))
            'MIN': temp_results.add, RS_2D_SELF.data.map(LAMBDA(x:MIN(x,/NAN)))
            'MAX': temp_results.add, RS_2D_SELF.data.map(LAMBDA(x:MAX(x,/NAN)))
            'SUM': temp_results.add, RS_2D_SELF.data.map(LAMBDA(x:TOTAL(x,/NAN)))
            'MEDIAN': temp_results.add, RS_2D_SELF.data.map(LAMBDA(x:MEDIAN(x)))
            'GLCM': BEGIN
                glcm_lambda_arr = LAMBDA(x:(GLCM_FEATURES(x,['CON','DIS','HOM','ASM','ENE','MAX','ENT','MEAN','VAR','STD','COR'])))

                FOREACH d,['0','45','90','135'] DO BEGIN
                    glcm_d = HASH(); delete old, to save space
                    glcm_d = RS_2D_SELF.data.map('GLCM_MATRIX', d)
                    temp_results.add,glcm_d.map(glcm_lambda_arr)
                    time.add,'GLCM_'+['CON','DIS','HOM','ASM','ENE','MAX','ENT','MEAN','VAR','STD','COR']+"_"+d,/EXTRACT
                ENDFOREACH
                glcm_d = HASH(); delete old, to save space
                
            END
            ELSE: BEGIN
                IF T.StartsWith('PERCENTILE') THEN BEGIN
                    perc = FIX((T.split('_'))[1])
                    temp_results.add, RS_2D_SELF.data.map(LAMBDA(x,p:PERCENTILE_RS(x,p)),perc)
                    time.add,T
                ENDIF ELSE IF T.StartsWith('GLCM') THEN BEGIN
                    ; TODO: Test this
                    glcm_type = (T.split('_'))[1]
                    direction = (T.split('_'))[2]
                    IF N_ELEMENTS(glcm) EQ 0 THEN glcm = HASH()
                    IF glcm.HasKey(direction) EQ 0 THEN glcm[d] = arr_bytscl.map(glcm_matrix_lambda, d)
                    temp_results.add, glcm[direction].map(glcm_features_lambda,glcm_type,arr_bytscl)
                    time.add,T
                    ; TODO: Test this
                ENDIF
            END      
        ENDCASE
    ENDFOREACH

    ; for whatever reason the following lambda function does not work with more than 9 elements.
    ; if 10 or more are found: iterative merging!
    alphabet = STRDGEN(9)

    WHILE N_ELEMENTS(temp_results) GT 9 DO BEGIN
      letters_string = STRJOIN(alphabet,',')
      fun_lamb = CALL_FUNCTION('LAMBDA',letters_string+":["+letters_string+"]")
      additional_arguments = STRJOIN("temp_results["+STRTRIM(INDGEN(8,START=1),2)+"]",',')
      exe = "result = temp_results[0].map(fun_lamb,"+ additional_arguments+")"
      void = EXECUTE(exe)
      temp_results.remove,[0,1,2,3,4,5,6,7,8]
      temp_results = LIST(result)+temp_results
    ENDWHILE
    
    n = N_ELEMENTS(temp_results)
    IF n GT 1 THEN BEGIN
        letters_string = STRJOIN(alphabet[0:n-1],',')
        fun_lamb = CALL_FUNCTION('LAMBDA',letters_string+":["+letters_string+"]")
        additional_arguments = STRJOIN("temp_results["+STRTRIM(INDGEN(n-1,START=1),2)+"]",',')
        exe = "result = temp_results[0].map(fun_lamb,"+ additional_arguments+")"
        void = EXECUTE(exe)
        temp_results.remove,/ALL
    ENDIF ELSE BEGIN
        result = temp_results
    ENDELSE
    
    RETURN, LIST(result,time)
END
