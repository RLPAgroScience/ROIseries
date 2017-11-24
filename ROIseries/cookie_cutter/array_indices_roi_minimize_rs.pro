;+
;  ARRAY_INDICES_ROI_MINIMIZE_RS: Convert array_indices into indices into the smallest possible array that could still hold the full data indexed by the array_indices
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
; Convert array_indices into indices into the smallest possible array that could still hold the full data indexed by the array_indices.
;
; :Params:
;    Indexes into a big array as returned by ARRAY_INDICES_ROI_RS
;
; :Keywords:
;    PUMPUP
;
; :Returns:
;     HASH containing the minimized indices (Red_IndexL) and the minimized arrays (Red_ArrayL)
;
; :Examples:
;     IDL> ref = get_reldir('ARRAY_INDICES_ROI_RS',2,['data','sentinel_2a'])
;     IDL> shp = ref+"vector\"+"studyarea.shp"
;     IDL> raster = (FILE_SEARCH(ref+"rasters\" + "\*.tif"))[0]
;     IDL> ID = "Id"
;     IDL> result = ARRAY_INDICES_ROI_RS(raster,shp,ID)
;     IDL> result_2 = ARRAY_INDICES_ROI_MINIMIZE_RS(result['Index'])
;     IDL> print,result_2
;     IDL> help, (result_2['Red_ArrayL'])[0]
;     IDL> print,(result_2['Red_IndexL'])[0]
;     
; :Description:
;
; :Uses:
;
; :Author:
;     Niklas Keck ("niklas_keck'use at instead'gmx.de").replace("'use at instead'","@")
;-
FUNCTION ARRAY_INDICES_ROI_MINIMIZE_RS,Index,PUMPUP=pumpup
    COMPILE_OPT idl2, HIDDEN
    ; MAKE two list one for one dimensional 2 element arrays and one for regular arrays and two indices
    ; get the size of each element in list and the indexes of the list elements
    IndexN=((INDEX.MAP(LAMBDA(x:N_ELEMENTS(x)))))
    IndexN2=WHERE(IndexN EQ 2)
    IndexNReg=WHERE(IndexN NE 2)
    
    ; Filter the original list
    IndexRegular=INDEX.FILTER(LAMBDA(x:N_ELEMENTS(x) NE 2))
    IndexIrregular=INDEX.FILTER(LAMBDA(x:N_ELEMENTS(x) EQ 2))
    
    ;  =================================================================================================================
    ; Regular (> 1 pixel) ARRAYS
    IF N_ELEMENTS(Indexregular) NE 0 THEN BEGIN ; to account for rois that all have only one pixel in them (e. g. when pixels are verry verry large)
        
        MINI=IndexRegular.MAP(LAMBDA(x:MIN(x,DIMENSION=2)))
        MAXI=IndexRegular.MAP(LAMBDA(x:MAX(x,DIMENSION=2)))
        
        RANGE=MAXI.MAP(LAMBDA(x,y:(x-y)+1),MINI)
    
        ; Add the template array to the list and if PUMPuP was specified create a 3D array with the last dimension = pumpup
        IF N_ELEMENTS(PUMPUP) NE 0 THEN BEGIN
            Red_ArrayL=RANGE.MAP(LAMBDA(x,y:MAKE_ARRAY([x,y],VALUE=!Values.F_NAN)),PUMPUP)
        ENDIF ELSE BEGIN
            Red_ArrayL=RANGE.MAP(LAMBDA(x:MAKE_ARRAY(x,VALUE=!Values.F_NAN)))
        ENDELSE
    
        ; Create the actual reduced index
        ; Get a List of sizes: THIS COULD BE SPEEDED UP IN FUTURE VERSION SINCE THE SIZE IS PREDICTABLE
        SN=IndexRegular.MAP(LAMBDA(x:(SIZE(x,/DIMENSIONS))[1]))                                        ; Red_ArrayL => IndexRegular
    
        func=LAMBDA(a,b,c:a-REBIN(b,2,c))
        IF N_ELEMENTS(PUMPUP) EQ 0 THEN BEGIN 
            Red_IndexL=IndexRegular.MAP(func,MINI,SN)
        ENDIF ELSE BEGIN
            start=IndexRegular.MAP(func,MINI,SN)
            x=start.MAP(LAMBDA(a,b:(LIST(REFORM(a[0,*]),LENGTH=b)).ToArray(DIMENSION=1)),PUMPUP)
            y=start.MAP(LAMBDA(a,b:(LIST(REFORM(a[1,*]),LENGTH=b)).ToArray(DIMENSION=1)),PUMPUP)
            Z=SN.MAP(LAMBDA(a,b:REBIN(INDGEN(b),b*a)),PUMPUP)
            Red_IndexL=x.MAP(LAMBDA(x,y,z:[[x],[y],[z]]),y,z)
        ENDELSE
    ENDIF
    
    ; =================================================================================================================
    ; Irregular ( 1 pixel) arrays
    IF N_ELEMENTS(IndexIrregular) NE 0 THEN BEGIN
        ; template array
        Range=[1,1]
        IF N_ELEMENTS(PUMPUP) NE 0 THEN BEGIN
            Red_ArrayL_Irr=LIST((MAKE_ARRAY([RANGE,PUMPUP],VALUE=!Values.F_NAN)),LENGTH=N_ELEMENTS(IndexIrregular))
        ENDIF  ELSE BEGIN 
            Red_ArrayL_Irr=LIST((REFORM(MAKE_ARRAY(RANGE,VALUE=!Values.F_NAN),1,1)),LENGTH=N_ELEMENTS(IndexIrregular))
        ENDELSE
        
        IF N_ELEMENTS(PUMPUP) NE 0 THEN BEGIN
            Red_IndexL_Irr=LIST([[(REPLICATE(0,PUMPUP))],[(REPLICATE(0,PUMPUP))],[INDGEN(PUMPUP)]],LENGTH=N_ELEMENTS(IndexIrregular))
        ENDIF ELSE BEGIN
            Red_IndexL_Irr=LIST(([[0],[0]]),LENGTH=N_ELEMENTS(IndexIrregular))
        ENDELSE
    ENDIF
    
    ;==========================================================================================================================
    ; merge the respective lists
    ; Basis for merge:
    ; IndexN2
    ; IndexNReg
    
    ; Arrays:
    Red_ArrayL_Result=LIST(!NULL,LENGTH=N_ELEMENTS(Index))
    Red_ArrayL_Result[IndexNReg]=Red_ArrayL
    IF TOTAL(IndexN2 NE -1) NE 0 THEN Red_ArrayL_Result[IndexN2]=Red_ArrayL_Irr ; -1 if no where N2
    
    ; Indices:
    Red_IndexL_Result=LIST(!NULL,LENGTH=N_ELEMENTS(Index))
    Red_IndexL_Result[IndexNReg]=Red_IndexL
    IF TOTAL(IndexN2 NE -1) NE 0 THEN Red_IndexL_Result[IndexN2]=Red_IndexL_Irr ; -1 if no where N2
    
    RETURN, HASH(LIST("Red_IndexL","Red_ArrayL"),LIST(Red_IndexL_Result,Red_ArrayL_Result))
END