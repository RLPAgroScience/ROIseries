;+
;  GET_RELDIR: Return a path relavive to a given routine
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
; Return a path relavive to a given routine
;
; :Params:
;     routine_name, required, type=string
;         the name of a routine on the IDL path 
;        
;     numbers_up, required, type=integer
;         the number of directories to walk up
;        
;     folders_down, required, type=strarr
;         the names of the folders to walk down
;
; :Keywords:
;     SKIP_TEST, optional, type=bool
;         if set, skip test if resulting directory exists.
;
; :Returns:
;     a path relative to the given routine
;     
; :Examples:
;     IDL> routine_name = 'updir'
;     IDL> numbers_up = 2
;     IDL> folders_down = ['data','sentinel_2a']
;     IDL> folder_new = get_reldir(routine_name,numbers_up,folders_down)
;     IDL> print,folder_new
;     ...\ROIseries\data\sentinel_2a\
;     
; :Description:
;
;	:Uses:
;     UPDIR
;
; :Author:
;     Niklas Keck ("niklas_keck'use at instead'gmx.de").replace("'use at instead'","@")
;-
FUNCTION GET_RELDIR,routine_name,numbers_up,folders_down,SKIP_TEST=skip_test
    COMPILE_OPT idl2, HIDDEN
    
    IF N_ELEMENTS(routine_name) EQ 0 THEN MESSAGE,"Please provide the routine_name"
    IF N_ELEMENTS(numbers_up) EQ 0 THEN MESSAGE,"Please provide numbers_up"
    IF N_ELEMENTS(folders_down) EQ 0 THEN MESSAGE,"Please provide folders_down"
    
    RESOLVE_ROUTINE,routine_name, /EITHER, /NO_RECOMPILE
    routine_dir = FILE_DIRNAME(ROUTINE_FILEPATH(routine_name, /EITHER))
    root_dir = UPDIR(routine_dir,numbers_up)
    new_dir = FILEPATH('',ROOT_DIR=root_dir,SUBDIRECTORY=folders_down)
    
    IF KEYWORD_SET(SKIP_TEST) THEN BEGIN
        RETURN,new_dir
    ENDIF ELSE BEGIN
        IF ~FILE_TEST(new_dir,/DIRECTORY) THEN BEGIN
            MESSAGE,new_dir+" does not exist"
        ENDIF ELSE BEGIN
            RETURN,new_dir
        ENDELSE
    ENDELSE

END