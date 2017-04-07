;+
;  FIND_AND_REPLACE_RS: Find and replace text in a textfile
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
; Find and replace text within a textfile
;
; :Params:
;     file_in,required,type=string
;         path to txt file to be read and modified 
;        
;     file_out,required,type=string
;         path to txt file to be output
;         to overwrite just use the same file_path twice.
;        
;     replace_hash,required,type=hash
;         the strings found in 'keys' will be replaced with the respective 'values'
;
; :Returns:
;
; :Examples:
;     IDL> ; make dummy data:
;     IDL> ohash = ORDEREDHASH("ID",["A","B","C","D","E"])
;     IDL> 
;     IDL> a=FINDGEN(5)
;     IDL> a[3] = !VALUES.F_NAN
;     IDL> ohash = ohash + ORDEREDHASH("A",a)
;     IDL> ohash = ohash + ORDEREDHASH("B",INDGEN(5))
;     IDL> structure = (ohash.ToStruct())
;     IDL>
;     IDL> ; Write data to CSV
;     IDL> file = FILEPATH("test.csv",/TMP)
;     IDL> WRITE_CSV,file,structure,HEADER = TAG_NAMES(structure)
;     IDL>
;     IDL> ; Find and Replace " and NaN with nothing.
;     IDL> replace_hash = HASH(['"','NaN'],['',''])
;     IDL> FIND_AND_REPLACE_RS,file,file,replace_hash
;
; :Description:
;
; :Uses:
;
; :Author:
;     Niklas Keck ("niklas_keck'use at instead'gmx.de").replace("'use at instead'","@")
;-
PRO FIND_AND_REPLACE_RS,file_in,file_out,replace_hash
    COMPILE_OPT idl2, HIDDEN
    
    IF N_ELEMENTS(file_in) EQ 0 THEN MESSAGE,"Please provide path to input text file"
    IF N_ELEMENTS(file_out) EQ 0 THEN MESSAGE,"Plase provide path to output text file. To overwrite original input file_in twice."
    IF N_ELEMENTS(replace_hash) EQ 0 THEN MESSAGE,"Please provide replace_hash" 
    
    ; read
    OpenR, lun, file_in, /GET_LUN
    text_list = LIST()
    line = ''
    WHILE NOT EOF(lun) DO BEGIN & $
        READF, lun, line & $
        text_list.add,line & $
    ENDWHILE
    FREE_LUN,lun
    
    ; replace
    text_array = text_list.toarray()
    FOREACH key,replace_hash.keys() DO text_array = text_array.replace(key,replace_hash[key])
    
    ; write
    OpenW,lun,file_out, /GET_LUN
    FOREACH l,text_array DO printf,lun,l
    FREE_LUN,lun
END