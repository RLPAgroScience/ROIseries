;+
;  RS_check_arithmetic_compatibility: Check the arithmetic compatiblity of two ROIseries objects for operator overloading. Do not call directly.
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
; Check the arithmetic compatiblity of two ROIseries objects for operator overloading. Do not call directly.
;
; :Params:
;    self
;    other_object
;
; :Returns:
;     1 if check is positive
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
FUNCTION RS_check_arithmetic_compatibility,self,other_object
    COMPILE_OPT idl2, HIDDEN 
    
    IF TYPENAME(self) NE TYPENAME(other_object) THEN MESSAGE,"TYPENAME differs"
    s=(self.DIMENSIONS())
    o=(other_object.DIMENSIONS())
    IF N_ELEMENTS(s.values()) NE N_ELEMENTS(o.values()) THEN MESSAGE,"Number of Objects differs"
    n=N_ELEMENTS(s.values())
    IF TOTAL(s.values() EQ o.values()) NE n THEN MESSAGE,"Dimensions within objects differ"
    IF TOTAL(s.keys() EQ o.keys()) NE n THEN MESSAGE,"Some keys differ"
    IF (TOTAL(self.time EQ other_object.time) NE N_ELEMENTS(self.time)) && (self.time NE !NULL && other_object.time NE !NULL) THEN MESSAGE,"time variable differs"
    
    RETURN,1
END