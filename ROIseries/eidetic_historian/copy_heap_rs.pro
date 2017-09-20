;+
;  COPY_HEAP_RS: Copy an object heap variable.
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
; Copy an object heap variable.
;
; :Params:
;    OBJECT,required, type = object heap variable
;        the object heap variable to be copied
;        
; :Returns:
;     object heap variable containing the same data as the input object but without the 
;
; :Examples:
;
; :Description:
;
; :Uses:
;
; :Author:
;     Niklas Keck ("niklas_keck'use at instead'gmx.de").replace("'use at instead'","@")
;-
FUNCTION COPY_HEAP_RS,OBJECT
    COMPILE_OPT idl2, HIDDEN
    temppath=FILEPATH("tempo",/TMP)
    tempvar=OBJECT
    SAVE,FILENAME=temppath,tempvar
    temporary=TEMPORARY(tempvar)
    RESTORE,temppath
    RETURN,tempvar
END