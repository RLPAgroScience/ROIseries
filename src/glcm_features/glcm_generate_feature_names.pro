;+
;  GLCM_GENERATE_FEATURE_NAMES: Get a StringArray of glcm feature names.
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
; Get a StringArray of glcm feature names.
;
; :Keywords:
;    TYPES
;    DIRS
;
; :Returns:
;
; :Examples:
; GLCM_GENERATE_FEATURE_NAMES()
; GLCM_GENERATE_FEATURE_NAMES(DIRS=LIST('90'))
; GLCM_GENERATE_FEATURE_NAMES(TYPES=LIST('ENE','ASM'),DIRS=LIST('90','45'))
; GLCM_GENERATE_FEATURE_NAMES(TYPES=LIST('ENE','ASM'),DIRS=LIST('90','45','75'))
;
; :Description:
;
; :Uses:
;
; :Author:
;     Niklas Keck ("niklas_keck'use at instead'gmx.de").replace("'use at instead'","@")
;-
FUNCTION GLCM_GENERATE_FEATURE_NAMES,TYPES=types,DIRS=dirs
    COMPILE_OPT idl2, HIDDEN
    
    valid_types = LIST('CON','DIS','HOM','ASM','ENE','MAX','ENT','MEAN','VAR','STD','COR')
    valid_dirs = LIST('0','45','90','135')
    
    IF N_ELEMENTS(types) EQ 0 THEN types = valid_types
        
    IF N_ELEMENTS(dirs) EQ 0 THEN BEGIN
        dirs = valid_dirs
    ENDIF ELSE IF (N_ELEMENTS(dirs) EQ 1) && (TYPENAME(dirs) EQ 'LIST') THEN BEGIN
        dirs = dirs[0]
    ENDIF
    
    FOREACH e,dirs DO IF valid_dirs.WHERE(e) EQ !NULL THEN MESSAGE,"The following dir is not valid: " + STRING(e)
    FOREACH e,types DO IF valid_types.WHERE(e) EQ !NULL THEN MESSAGE,"The following type is not valid: " + STRING(e)
     
    RETURN, "GLCM_" + (types.NestedMap(LAMBDA(i,k:i+"_"+k),dirs)).ToArray()
END