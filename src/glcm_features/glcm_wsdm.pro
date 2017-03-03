;+
;  GLCM_WSDM: Calculate the weighted squared distances matrix for GLCM
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

;+
; Calculate the weighted squared distances matrix for GLCM
;
; :Params:
;     n : in, required, type=numeric
;     exponent : in, required, type=numeric
;    
; :Returns:
;     WSDM
;     
; :Examples:
;     For example::
;         n = 4 ; for a 4X4 matrix
;         exponent = 2 ; for an increase of power 2 away from the diagonal
;         weights = WSDM(n,exponent)
;         print, weights
;             0   1   4   9
;             1   0   1   4
;             4   1   0   1
;             9   4   1   0
;
; :Description:
;     Calculate the weighted squared distances matrix [wsdm]
;     for use within GLCM. The wsdm is used to give more weight to
;     glcm entries farther away from the diagonal. This means
;     more weight to entries representing higher contrast.
;
;	:Uses:
;     DETER_MINSIZE, SET_TYPE
;     
; :Author:
;     Niklas Keck ("niklas_keck'use at instead'gmx.de").replace("'use at instead'","@")
;-
FUNCTION GLCM_WSDM,n,exponent
    COMPILE_OPT idl2, HIDDEN
    
    ; Convert n to the datatype that is needed to store the maximum number that will occur
    type=DETER_MINSIZE(ULONG64(n)^exponent,/name)
    n=SET_TYPE(n,type)
    
    ; create the wsdm
    ind=(INDGEN(n))^exponent
    r1=MAKE_ARRAY(n,n,value=SET_TYPE(0,type))
    r2=r1
    FOR i=0,n-1 DO r1[i-1,i-1:n-1]=ind[0:-i]
    r2=rotate(r1,2)
    
    ; return the result
    RETURN,r1+r2
END