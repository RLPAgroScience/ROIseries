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
;    RS_DATA
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
FUNCTION RS3D_SPATIAL_MIXER,RS_DATA,TYPE
    COMPILE_OPT idl2, HIDDEN
    
    time_count = (SIZE((RS_DATA.values())[0],/DIMENSIONS))[-1]
    time_indgen = INDGEN(time_count)
    
    arr = PTR_NEW(/ALLOCATE_HEAP)
    result_hash = HASH()
    FOREACH key,RS_DATA.keys() DO BEGIN
        *arr=RS_DATA[key]
        CASE TYPE OF
            'MEAN': result = time_indgen.map(LAMBDA(i,x:MEAN(((*x)[*,*,i]),/NAN)),arr)
            'SD': result = time_indgen.map(LAMBDA(i,x:STDDEV(((*x)[*,*,i]),/NAN)),arr)
            'COUNT': result = REPLICATE(N_ELEMENTS(WHERE(FINITE((RS_DATA[key])[*,*,0]))),time_count)
            'MIN': result = time_indgen.map(LAMBDA(i,x:MIN(((*x)[*,*,i]),/NAN)),arr)
            'MAX': result = time_indgen.map(LAMBDA(i,x:MAX(((*x)[*,*,i]),/NAN)),arr)
            'SUM': result = time_indgen.map(LAMBDA(i,x:TOTAL(((*x)[*,*,i]),/NAN)),arr)
            'MEDIAN': result = time_indgen.map(LAMBDA(i,x:MEDIAN(((*x)[*,*,i]),/NAN)),arr)
        ENDCASE
        result_hash[key] = result
    ENDFOREACH
    
    return,result_hash
END