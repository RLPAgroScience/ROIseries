;+
;  CONTAINS_ANY_RS: Check if one variable contains any elements from another variable 
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
; Check if one variable contains any elements from another variable 
;
; :Params:
;    V1,required,type=IDL_Variable
;    V2,required,type=IDL_Variable
;    
; :Returns:
;     1 if any values in V1 are in V2
;     0 if no values from V1 are in V2
;     
; :Examples:
;     IDL> CONTAINS_ANY_RS(["a","b","c"],["c","d"])
;     IDL> CONTAINS_ANY_RS(["a","b","c"],["d","e"])
;     IDL> CONTAINS_ANY_RS([1,2,3],[3,4])
;     IDL> CONTAINS_ANY_RS([1,2,3],[5,6])
; :Description:
;
; :Uses:
;
; :Author:
;     Niklas Keck ("niklas_keck'use at instead'gmx.de").replace("'use at instead'","@")
;-
FUNCTION CONTAINS_ANY_RS,V1,V2

    r1 = (v1.NestedMap(LAMBDA(v1,v2:WHERE(v1 EQ v2)),v2))
    IF TOTAL(r1 NE -1) GT 0 THEN BEGIN
        RETURN,1
    ENDIF ELSE BEGIN
        RETURN,0
    ENDELSE

END