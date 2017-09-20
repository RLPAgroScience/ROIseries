;+
;  REPCON_RS: Replicate an array by a specific factor and concatenate results over a specific dimension. 
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
; Replicate an array by a specific factor and concatenate results over a specific dimension. 
;
; :Params:
;    arr, required, array
;        the array to be repconed
;        
;    fac, required, integer
;        the factor by which to replicate the array
;    
;    Dimension, required, integer
;        the dimension over which to concatenate the results
;
; :Returns:
;    array
;
; :Examples:
;     arr = INDGEN(7)
;     fac = 3
;     print,REPCON_RS(arr,fac,0)
;     print,REPCON_RS(arr,fac,1)
;     
; :Description:
;
; :Uses:
;
; :Author:
;     Niklas Keck ("niklas_keck'use at instead'gmx.de").replace("'use at instead'","@")
;-
FUNCTION REPCON_RS,arr,fac,Dimension
    COMPILE_OPT idl2, HIDDEN
    RETURN,(LIST(arr,LENGTH=fac)).ToArray(DIMENSION=Dimension)
END