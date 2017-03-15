;+
;  GROUNDTRUTH_FROM_CSV: Read ground truth from CSV
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
; Read ground truth from CSV
;
; :Params:
;     csv: in,required,string
;         path to the csv file containing the ground truth
;     types: in,required,strarr
;         array of column names to extract from csv
;     ID_Field: in,required,string
;         name of column that stores IDs for each row
;     posYear: in, required, numeric array
;         [First_Character,Length] (cp. documentation of STRMID)
;     posMonth:  in, required, numeric array
;         [First_Character,Length] (cp. documentation of STRMID)
;     posDay: in, required, numeric array
;         [First_Character,Length] (cp. documentation of STRMID)
;        
; :Returns:
;     nested ORDEREDHASH(ID:ORDEREDHASH(events:[datesarray])) e. g.:
;         ORDEREDHASH(LIST("a","b","c"),LIST(ORDEREDHASH(LIST("typ_1","typ_2"),LIST([2001,2002,2003],[2006,2008,2010]))))
;
; :Keywords:
;     AGGREGATE: in,required,hash
;         hash containing the translation to be applied to the resulting hash to rename or aggregate types (cp. examples)
;
; :Examples:
;     IDL> csv = GET_RELDIR("GroundTruth_from_csv",2,["data","sentinel_2a","table"])+"observations.csv"
;     IDL> types =  ["before_harvest","after_harvest","before_ploughing","after_ploughing"]
;     IDL> aggregate = HASH(LIST("harvest","ploughin"),LIST(["before_harvest","after_harvest"],["before_ploughing","after_ploughing"]))
;     IDL> groundtruth = GROUNDTRUTH_FROM_CSV(csv,types,"ID",[0,4],[4,2],[6,2])
;     IDL> groundtruth_aggregated = GROUNDTRUTH_FROM_CSV(csv,types,"ID",[0,4],[4,2],[6,2],AGGREGATE=aggregate)
;     IDL> groundtruth
;     IDL> groundtruth_aggregated
; 
; :Description:
;
; :Uses:
;     GEN_DATE
;
; :Author:
;     Niklas Keck ("niklas_keck'use at instead'gmx.de").replace("'use at instead'","@")
;-
FUNCTION GROUNDTRUTH_FROM_CSV,csv,types,ID_Field,posYear,posMonth,posDay,AGGREGATE=aggregate
    COMPILE_OPT idl2, HIDDEN 
    
    ; Read CSV and make 
    table=READ_CSV(csv,HEADER=header); COUNT=count
    
    ; Get the data in an more convenient format
    ids = table.(WHERE(header EQ ID_FIELD))
    
    ; make a nested ORDEREDHASH:
    ; ORDEREDHASH(ID:ORDEREDHASH(events:[datesarray]))
    result = ORDEREDHASH()
    FOR i=0,N_ELEMENTS(ids)-1 DO BEGIN &$
        temp_result = ORDEREDHASH() &$
        FOREACH typ,types DO BEGIN &$
             t_string = [(table.(WHERE(header EQ typ)))[i]]  &$
             ; convert timestring to juld.
             IF STRTRIM(t_string,2) NE 'NA' THEN BEGIN &$
                t = GEN_DATE(t_string,posYear,posMonth,posDay) &$
                temp_result[typ] = t &$    
             ENDIF ELSE BEGIN &$
                temp_result[typ] = 'NA'  &$
             ENDELSE &$
        ENDFOREACH &$
        result[ids[i]]=temp_result &$
    ENDFOR
    
    ; Optionally apply agrretation / translation 
    IF N_ELEMENTS(AGGREGATE) NE 0 THEN BEGIN &$
        FOREACH k_agg,aggregate.keys() DO BEGIN &$
            FOREACH id, result.keys() DO BEGIN &$
                selected_values=LIST() &$
                temp = result[id] &$
                ; the remove method returns the removed value
                FOREACH k_res,temp.keys() DO BEGIN &$
                    IF (aggregate[k_agg]).HasValue(k_res) THEN selected_values.add,temp.remove([k_res]),/EXTRACT &$
                ENDFOREACH &$
                temp[k_agg]=selected_values &$
                result[id] = temp &$
            ENDFOREACH &$
        ENDFOREACH &$
    ENDIF
    
    RETURN,RESULT
END