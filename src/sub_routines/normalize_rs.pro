;+
;  NORMALIZE_RS: Scale the values of a numeric array to a specific range
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
; Scale the values of a numeric array to a specific range.
;
; :Params:
;    array
;    new_minimum
;    new_maximun
;
; :Returns:
;
; :Examples:
;     IDL> print,NORMALIZE_RS(INDGEN(42),[0,1])
;     IDL> print,NORMALIZE_RS(INDGEN(42),[-42,42])
;     IDL> print,NORMALIZE_RS(INDGEN(5,5),[-3.14,9.81])
;     
; :Description:
;
; :Uses:
;
; :Author:
;     Niklas Keck ("niklas_keck'use at instead'gmx.de").replace("'use at instead'","@")
;-
FUNCTION NORMALIZE_RS,array,new_min_max
    COMPILE_OPT idl2, HIDDEN
    
    IF N_ELEMENTS(array) EQ 0 THEN MESSAGE, "Please provide 'array'"
    array = DOUBLE(array)
    IF N_ELEMENTS(new_min_max) NE 2 THEN MESSAGE,"Please provide 'new_min_max' array, form: [new_min,new_max]"
    
    new_range = ABS(new_min_max[0] - new_min_max[1])
    old_minimum = MIN(array,/NAN,MAX=old_maximum)
    
    zero_to_one = (array-old_minimum)/(old_maximum-old_minimum)
    zero_to_range = zero_to_one*new_range
    result =  zero_to_range + new_min_max[0] ; if new_minimum is negative it will be subtracted
    
    RETURN,result
END