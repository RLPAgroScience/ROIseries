;+
;  PERCENTILE_RS: Calculate a specific percentile of an array
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
; Calculate a specific percentile of an array
;
; :Params:
;    array,required,type=numeric array
;        The array holding the values to be inspected.
;    
;    percentage,required,type=numeric
;         Percentage threshold by which to devide the array into a first and a 
;         second part. If e. g. percentage = 90, then the smaller 90% of values 
;         are assigned to the first part of the array.
;        
; :Returns:
;        The return value is the hightest value in the array sorted in ascending order
;        that falls into the first part of the array.
;        
; :Examples:
;     IDL> tree_hights = RANDOMU(42, 100)*20
;     IDL> print,percentile_rs(tree_hights,90)
;
; :Description:
;     Implemeted using Nearest Rank method from: https://en.wikipedia.org/wiki/Percentile
;         
; :Uses:
;
; :Author:
;     Niklas Keck ("niklas_keck'use at instead'gmx.de").replace("'use at instead'","@")
;-
FUNCTION PERCENTILE_RS,array,percentage
    COMPILE_OPT idl2, HIDDEN
    
    IF N_ELEMENTS(array) LT 1 THEN MESSAGE,"Please provide array argument"
    IF N_ELEMENTS(percentage) LT 1 THEN MESSAGE,"Please provide percentage argument"
    IF percentage LT 0 || percentage GT 100 THEN MESSAGE,"Percentage has to be between 0 to 100"
    
    reformed = REFORM(array,(SIZE(array))[-1])
    reformed_finite = reformed[WHERE(FINITE(reformed))]
    sorted = reformed_finite[sort(reformed_finite)]
    ordinal_rank = CEIL((percentage/100.0)*N_ELEMENTS(sorted))-1 ; -1 because rank 1 = index 0!
    RETURN,sorted[ordinal_rank]

END