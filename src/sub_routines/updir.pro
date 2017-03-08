;+
;  UPDIR: Given a 'path' and a 'number', return the path 'number' steps up the directory hirarchy    
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
; Given a 'path' and a 'number', return the path 'number' steps up the directory hirarchy  
;
; :Params:
;    dir : required, type=string
;    number : required, type=integer
;    
; :Returns:
;     the path, type=string
;     
; :Examples:
;     IDL> path = "C:\a\b\c\d\e"
;     IDL> number = 2
;     IDL> new_path = updir(path,number)
;     IDL> print,new_path
;     C:\a\b\c
;
; :Description:
;
;	:Uses:
;
; :Author:
;     Niklas Keck ("niklas_keck'use at instead'gmx.de").replace("'use at instead'","@")
;-
FUNCTION UPDIR,dir,number
    IF N_ELEMENTS(dir) EQ 0 THEN MESSAGE,"Please input dir"
    IF N_ELEMENTS(number) EQ 0 THEN MESSAGE,"Please input number"
    result = dir
    FOR i=1,number DO result=FILE_DIRNAME(result)
    RETURN,result
END