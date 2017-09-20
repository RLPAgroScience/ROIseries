;+
;  MOVING_STATS_RS: Calculate moving window statistics over last dimension of an array
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
;  Calculate moving window statistics over last dimension of an array
;
; :Params:
;    Array
;    Intervall
;
; :Returns:
;
; :Examples:
;     IDL> MOVING_STATS_RS(INDGEN(10),3)
;
; :Description:
;     Wrapper for the moment.pro function that calculates the 
;     moving version of all functions over the last dimension
;     => Mean, Variance, Skewness, Kurtosis, Mean Absolute Deviation, Standard Deviation,
;     and Min, Max (not part of moment.pro)
; 
; :Uses:
;
; :Author:
;     Niklas Keck ("niklas_keck'use at instead'gmx.de").replace("'use at instead'","@")
;-
FUNCTION MOVING_STATS_RS,Array,Intervall

    ; get some usefull variables
    GlobalDimensions=Array.dim
    DimLen=N_ELEMENTS(Array.DIM)
    
    ; prepare lists to hold results
    resHash=HASH("mean",list(),$
        "variance",list(),$
        "skewness",list(),$
        "kurtosis",list(),$
        "std",list(),$
        "mdev",list(),$
        "min",list(),$
        "max",list(),$
        "total",list())
  
    FOREACH i,INDGEN(GlobalDimensions[-1]-(intervall-1)) DO BEGIN &$
    
    ; 1. Slice array
    CASE DimLen OF &$
        1: curarr = array[i:i+(intervall-1)] &$
        3: curarr=array[*,*,i:i+(intervall-1)] &$
        ELSE: MESSAGE,"Only 1 or 3 dimensional arrays are supported" &$
    ENDCASE &$
    
    ; 2. Do calculations
    res0=moment(curarr,DIMENSION=DimLen,/NAN,MDEV=mdev,SDEV=sdev) &$
    min=MIN(curarr,DIMENSION=DimLen,/NAN,MAX=max) &$
    tot=TOTAL(curarr,DimLen,/NAN)
    
    ; 3. Reform Results
    CASE DimLen OF &$ 
        1:BEGIN &$
            resHash["mean"].add,res0[0] &$
            resHash["variance"].add,res0[1] &$
            resHash["skewness"].add,res0[2] &$
            resHash["kurtosis"].add,res0[3] &$
        END &$
        3:BEGIN &$
            resHash["mean"].add,res0[*,*,0] &$
            resHash["variance"].add,res0[*,*,1] &$
            resHash["skewness"].add,res0[*,*,2] &$
            resHash["kurtosis"].add,res0[*,*,3] &$
            END  &$
        ENDCASE &$
        
        resHash["std"].add,sdev &$
        resHash["mdev"].add,mdev &$
        resHash["min"].add,min &$
        resHash["max"].add,max &$
        resHash["total"].add,tot &$
    ENDFOREACH
  
    ; convert the lists to arrays
    FOREACH k,resHash.keys() DO resHash[k]=(resHash[k]).ToArray(/TRANSPOSE)

    RETURN,resHash
END