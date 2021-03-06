;+
;  RS_SPATIAL_MIXER: Quantify the distribution of values within each image-object per time step. Do not call directly.
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
;    RS_3D_SELF
;    TYPE
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
FUNCTION RS3D_SPATIAL_MIXER,RS_3D_SELF,TYPE
    COMPILE_OPT idl2, HIDDEN
    
    IF N_ELEMENTS(RS_3D_SELF.time) EQ 0 THEN BEGIN
        MESSAGE,"Please set RS_3D.time attribute before using the spatial_mixer. E. g. LIST(0) for monotemporal images"
    ENDIF ELSE BEGIN
        time_count = N_ELEMENTS(RS_3D_SELF.time)
    ENDELSE

    time_indgen = INDGEN(time_count)
    arr = PTR_NEW(/ALLOCATE_HEAP)
    result_hash = HASH()
    data = RS_3D_SELF.data
    
    FOREACH key,data.keys() DO BEGIN &$
        *arr = data[key]
        CASE TYPE OF
            'MEAN': result = time_indgen.map(LAMBDA(i,x:MEAN(((*x)[*,*,i]),/NAN)),arr)
            'STDDEV': result = time_indgen.map(LAMBDA(i,x:STDDEV(((*x)[*,*,i]),/NAN)),arr)
            'COUNT': result = REPLICATE(N_ELEMENTS(WHERE(FINITE((data[key])[*,*,0]))),time_count)
            'MIN': result = time_indgen.map(LAMBDA(i,x:MIN(((*x)[*,*,i]),/NAN)),arr)
            'MAX': result = time_indgen.map(LAMBDA(i,x:MAX(((*x)[*,*,i]),/NAN)),arr)
            'SUM': result = time_indgen.map(LAMBDA(i,x:TOTAL(((*x)[*,*,i]),/NAN)),arr)
            'MEDIAN': result = time_indgen.map(LAMBDA(i,x:MEDIAN(((*x)[*,*,i]))),arr)
            ELSE: BEGIN
                IF TYPE.StartsWith('GLCM') THEN BEGIN

                    glcm_type = (TYPE.split('_'))[1]
                    direction = (TYPE.split('_'))[2]

                    ; For GLCM matrix: Scale values to 0-255 while pertaining nan values
                    arr_bytscl = BYTSCL(*arr,/NAN)*(*arr/*arr)

                    result = LIST()
                    FOR i=0,time_count-1 DO BEGIN &$
                        glcm = GLCM_MATRIX(arr_bytscl[*,*,i],direction,NORMALIZE_RS_NEW_MIN_MAX=[0,255]) &$
                        result.add,GLCM_FEATURES(glcm,glcm_type,img=arr_bytscl[*,*,i]),/EXTRACT &$
                    ENDFOR
                ENDIF ELSE IF TYPE.StartsWith('PERCENTILE') THEN BEGIN
                    perc = REPLICATE(FIX((TYPE.split('_'))[1]),time_count)
                    result = time_indgen.map(LAMBDA(i,x,p:PERCENTILE_RS(((*x)[*,*,i]),p)),arr,perc)
                ENDIF ELSE BEGIN
                    MESSAGE,TYPE," will not be calculated since it is not a vaild option"
                ENDELSE
            ENDELSE

        ENDCASE
        result_hash[key] = result
    ENDFOREACH
    
    RETURN,LIST(result_hash,result_time)
END