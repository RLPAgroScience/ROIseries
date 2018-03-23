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
;    RS_SELF
;    TYPES
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
FUNCTION RS_SPATIAL_MIXER,RS_SELF,TYPES
    COMPILE_OPT idl2, HIDDEN
    
    type = TYPENAME(RS_SELF)
    
    IF type EQ 'ROISERIES_3D' THEN BEGIN &$
        IF N_ELEMENTS(RS_SELF.time) EQ 0 THEN BEGIN &$
            MESSAGE,"RS_3D.time attribute before using the spatial_mixer" &$
        ENDIF ELSE BEGIN &$
            time = STRTRIM(RS_SELF.time.toarray(),2) &$
            time_count = N_ELEMENTS(time) &$
            feature_seperator = "_"
        ENDELSE &$
    ENDIF ELSE BEGIN &$
        IF N_ELEMENTS(RS_SELF.time) EQ 0 THEN BEGIN
            time = "" &$
            time_count = 1
            feature_seperator = ""
        ENDIF ELSE BEGIN
            time = STRTRIM(RS_SELF.time.toarray(),2) &$
            time_count = 1
            feature_seperator = "_"
        ENDELSE
    ENDELSE
    
    ; 2 kind of types native and custom requiring different preprocessing
    native = ['MEAN','STDDEV','COUNT','MIN','MAX','SUM','MEDIAN']
    types_native = LIST()
    types_custom = LIST()
    FOREACH t,types DO BEGIN &$
        IF native.HasValue(t) THEN BEGIN &$
            types_native.add,t &$
        ENDIF ELSE BEGIN &$
            types_custom.add,t &$
        ENDELSE &$
    ENDFOREACH
    
    ; create lists to store results
    temp_results = LIST()
    time_new = LIST()
    
    ; ======================================================================
    ; Process native types
    IF N_ELEMENTS(types_native) NE 0 THEN BEGIN &$
        
        ; Preprocessing
        IF type EQ 'ROISERIES_2D' THEN BEGIN &$
            RS_SELF_FLAT = RS_SELF.data &$
            DIMENSION = 0 &$ ; apply over all dimensions
        ENDIF ELSE IF type EQ 'ROISERIES_3D' THEN BEGIN &$
            ; Reform input into 2D array so the 'DIMENSION' keyword can be used to apply statistics
            ; over 2 dimensions at the same time (MEAN(MEAN(),MEAN()) NE MEAN() if samples are of unqual lenght)
            dims = RS_SELF.data.map(LAMBDA(x:SIZE(x,/DIMENSIONS))) &$
            RS_SELF_FLAT = RS_SELF.data.map(LAMBDA(x,d:REFORM(x,d[0]*d[1],d[2])),dims) &$
            DIMENSION = 1 &$ ; apply over first (spatial) dimension (1-based index,3D was reduced to 2D)
        ENDIF
        
        ; Processing 
        FOREACH T,types_native DO BEGIN &$
            
            IF T EQ 'COUNT' THEN BEGIN
                time_new.add,'COUNT'
            ENDIF ELSE BEGIN
                time_new.add,time + feature_seperator + T,/EXTRACT &$
            ENDELSE
            
            CASE T OF &$
                'MEAN': temp_results.add, RS_SELF_FLAT.map(LAMBDA(x,d:MEAN(x,/NAN,DIMENSION=d)),dimension) &$
                'STDDEV': temp_results.add, RS_SELF_FLAT.map(LAMBDA(x,d:STDDEV(x,/NAN,DIMENSION=d)),dimension) &$
                ; Count is constant over time
                'COUNT': temp_results.add, RS_SELF_FLAT.map(LAMBDA(x,d:(TOTAL(FINITE(x),d))[0]),dimension) &$
                'MIN': temp_results.add, RS_SELF_FLAT.map(LAMBDA(x,d:MIN(x,/NAN,DIMENSION=d)),dimension) &$
                'MAX': temp_results.add, RS_SELF_FLAT.map(LAMBDA(x,d:MAX(x,/NAN,DIMENSION=d)),dimension) &$
                'SUM': temp_results.add, RS_SELF_FLAT.map(LAMBDA(x,d:TOTAL(x,d,/NAN)),dimension) &$
                'MEDIAN': temp_results.add, RS_SELF_FLAT.map(LAMBDA(x,d:MEDIAN(x,DIMENSION=d)),dimension) &$
            ENDCASE &$
        ENDFOREACH
    ENDIF
    
    ; ======================================================================    
    ; Process custom types
    
    FOREACH T,types_custom DO BEGIN
        FOR i=0,time_count-1 DO BEGIN
            IF type EQ 'ROISERIES_3D' THEN BEGIN &$
                current_slice = RS_SELF.data.map(LAMBDA(x,i:REFORM(x[*,*,i])),i) &$
            ENDIF ELSE BEGIN  &$
                current_slice = RS_SELF.data  &$
            ENDELSE
            
            IF T EQ 'GLCM' THEN BEGIN
                glcm_lambda_arr = LAMBDA(x:(GLCM_FEATURES(x,['CON','DIS','HOM','ASM','ENE','MAX','ENT','MEAN','VAR','STD','COR'])))
                FOREACH d,['0','45','90','135'] DO BEGIN
                    glcm_d = HASH(); delete old, to save space
                    glcm_d = current_slice.map('GLCM_MATRIX', d)
                    temp_results.add,glcm_d.map(glcm_lambda_arr)
                    time_new.add,time + feature_seperator + 'GLCM_'+['CON','DIS','HOM','ASM','ENE','MAX','ENT','MEAN','VAR','STD','COR']+"_"+d,/EXTRACT
                 ENDFOREACH
                 glcm_d = HASH(); delete old, to save space
            ENDIF ELSE IF T.startswith('GLCM') THEN BEGIN
                glcm_type = (T.split('_'))[1]
                direction = (T.split('_'))[2]
                IF N_ELEMENTS(glcm) EQ 0 THEN glcm = HASH()
                IF glcm.HasKey(direction) EQ 0 THEN glcm[direction] = current_slice.map('GLCM_MATRIX', direction)
                temp_results.add,glcm[direction].map('GLCM_FEATURES',glcm_type)
                time_new.add,time + feature_seperator +T,/EXTRACT
            ENDIF ELSE IF T.startswith('PERCENTILE') THEN BEGIN
                perc = FIX((T.split('_'))[1])
                temp_results.add, current_slice.map(LAMBDA(x,p:PERCENTILE_RS(x,p)),perc)
                time_new.add,time + feature_seperator +T,/EXTRACT
            ENDIF
            
        ENDFOR     
     ENDFOREACH
     
    ; ======================================================================
    ; combining results into one big hash

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
    
    RETURN, LIST(result,time_new)
END
;k = RS_SELF.data.keys()
;orig = RS_SELF.data[k[42]]
;new = RS_SELF_FLAT[k[42]]
