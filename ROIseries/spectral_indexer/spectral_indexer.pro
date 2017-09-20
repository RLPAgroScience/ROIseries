;+
;  SPECTRAL_INDEXER: Combine multiple 2D arrays (image bands) into one 2D array using arithmetic, logical and/or indexing operations
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
; Combine multiple 2D arrays (image bands) into one 2D array using arithmetic, logical and/or indexing operations
;
; :Params:
;     Images : in, required
;         - various types of input allowed. See below for details.
;
;     formula : in, required, type=string
;         formula to be used to combine the bands. E.g. "(R[3]-R[0])/(R[3]+R[0])"
;         or get a band e.g. "R[2]"
;
; :Returns:
;     Depending on input (in -> out):
;         3D: 
;             - list_of_numeric_arrays 3D -> list_of_numeric_arrays 2D
;             - singe_string 3D -> single_array 2D
;             - numeric_array 3D -> single_array 2D
;             - string_array 3D -> list_of_numeric_arrays 2D
;             - list_of_strings 3D -> list_of_numeric_arrays 2D
;         2D:
;             - string_array_2D -> single_array 2D
;             - list_of_strings_2D -> single_array 2D
;             - list_of_numeric_arrays_2D -> single_array 2D
;
; :Examples:
;     For example::
;         IDL> rasterseries_location = get_reldir('SPECTRAL_INDEXER',2,['data','sentinel_2a','rasters'])
;         IDL> rasterseries = FILE_SEARCH(rasterseries_location,"*studyarea.tif")
;         IDL> formula_1 = "(R[3]-R[0])/(R[3]+R[0])" ; calculate a vegetation_'index'
;         IDL> formula_2 = "R[1]" ; 'index' one band
;         IDL> ndvi = SPECTRAL_INDEXER(rasterseries,formula_1)
;         IDL> green = SPECTRAL_INDEXER(rasterseries,formula_2) 
;
; :Description:
;     Given raster(s)/array(s):
;     - Arithmetically combine the raster(s)/array(s) to calculate e. g. the NDVI
;     - Attention: Please check the order in which the rasters are input, as this is the order in which to reference them using "formula"
;
;     The input can be:
;     -> A "list of numeric arrays", "list of strings", "string array":
;         IF 2D each array THEN calculate index over the length of the list. Result: 2D array
;         IF 3D each array THEn calculate index over each element in the list, removing the 3rd dimension per list element. Result: Multiple 2D arrays
;     -> A numeric array
;         IF 3D array THEN calculate index over 3rd dimension. RESULT: 2D array
;
;	:Uses:
;
; :Author:
;     Niklas Keck ("niklas_keck'use at instead'gmx.de").replace("'use at instead'","@")
;-
FUNCTION SPECTRAL_INDEXER,Images,formula,DATATYPE_RESULT=datatype_result
    COMPILE_OPT idl2, HIDDEN 
    
    ; Input
    IF N_ELEMENTS(Images) EQ 0 THEN Message,"Please provide parameter 'images'"
    IF N_ELEMENTS(formula) EQ 0 THEN Message,"Please provide parameter 'formula'"
    IF N_ELEMENTS(datatype_result) EQ 0 THEN datatype_result = "DOUBLE"
    
    ; Detailed input checking
    cas = CHECK_RASTERSERIES(Images,BANDS=bands,EXTENT=extent)
    
    ;=====================================================================================================================
    ; reformat into a List of arrays (R) depending on the differnt cases 
    
    CASE cas OF
        ;-----------------------------------------------------------------------------------------------------------------
        'ListOfNumericArrays': BEGIN
                                   CASE bands OF
                                       1: BEGIN
                                              R = Images.Map(Lambda(x,type:SET_TYPE(x,type)),datatype_result) 
                                              temp = EXECUTE("result = "+formula)
                                          END
                                       ELSE: BEGIN
                                           result = LIST()
                                           R = LIST()
                                           FOREACH i,Images DO BEGIN &$
                                               FOR k = 0,BANDS-1 DO R.add,SET_TYPE(REFORM(i[k,*,*]),datatype_result) &$
                                               temp = EXECUTE("result.add,"+formula) &$
                                           ENDFOREACH
                                           END
                                   ENDCASE
                               END
        ;-----------------------------------------------------------------------------------------------------------------
        'SingleString':        BEGIN
                                   x=SET_TYPE(READ_IMAGE(Images),datatype_result)
                                   R=LIST()
                                   FOREACH k,[0:bands-1] DO R.add,SET_TYPE(REFORM(x[k,*,*]),datatype_result)
                                   temp = EXECUTE("result="+formula)
                               END
        ;-----------------------------------------------------------------------------------------------------------------
        'NumericArray':        BEGIN
                                   R=LIST()                        
                                   FOREACH k,[0:bands-1] DO R.add,SET_TYPE(REFORM(Images[k,*,*]),datatype_result)
                                   temp = EXECUTE("result="+formula)             
                               END
        ;-----------------------------------------------------------------------------------------------------------------
        ELSE:                  BEGIN
                                   IF (cas NE 'StringArray') AND (cas NE 'ListOfStrings') THEN MESSAGE,'This type of input "Images" is not supported.'
                                   image_list = list(images,/EXTRACT) ; if images are list already, nothing happens
                                   image_list = image_list.map(LAMBDA(x,type:SET_TYPE(READ_IMAGE(x),type)),datatype_result)
                                   CASE bands OF
                                       1:    BEGIN
                                                 R = image_list
                                                 temp = EXECUTE("result = "+formula)
                                             END
                                             
                                       ELSE: BEGIN
                                                 result = LIST()
                                                 R = LIST()
                                                 FOREACH i,image_list DO BEGIN &$
                                                     FOR k = 0,bands-1 DO R.add,SET_TYPE(REFORM(i[k,*,*]),datatype_result) &$
                                                     temp = EXECUTE("result.add,"+formula) &$
                                                 ENDFOREACH
                                             END
                                   ENDCASE
                               END  
    ENDCASE
    ;=====================================================================================================================
    
    RETURN,result

END