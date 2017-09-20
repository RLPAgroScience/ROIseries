;+
;  SET_TYPE: Return a number converted to a datatype specified by a string
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
; Return a number converted to a datatype specified by a string
;
; :Params:
;    x: required, numeric
;    type: required, string
;    
; :Returns:
;    'x' converted to datatype 'type'
;
; :Examples:
;     IDL> x = LONG64(-42)
;     IDL> y = SET_TYPE(x,"INT")
;     IDL> x EQ y
;     IDL> typename(y)
;     IDL> print,'No validatio of results is done!:'
;     IDL> y = SET_TYPE(x,"BYTE")
;     IDL> x EQ y
;     IDL> typename(y)
;     
; :Description:
;      Return a number converted to a datatype specified by a string.
;      Attention: It is not checked if a value datatype fits into the new datatype!
;      
;	:Uses:
;
; :Author:
;     Niklas Keck ("niklas_keck'use at instead'gmx.de").replace("'use at instead'","@")
;-
FUNCTION SET_TYPE,x,type
    COMPILE_OPT idl2, HIDDEN
    CASE type OF
        'BYTE':RETURN,BYTE(x)
        'UINT':RETURN,UINT(x)
        'ULONG':RETURN,ULONG(x)
        'ULONG64':RETURN,ULONG64(x)
        'INT':RETURN,FIX(x)
        'LONG':RETURN,LONG(x)
        'LONG64':RETURN,LONG64(x)
        'FLOAT':RETURN,FLOAT(x)
        'DOUBLE':RETURN,DOUBLE(x) 
    ENDCASE
END