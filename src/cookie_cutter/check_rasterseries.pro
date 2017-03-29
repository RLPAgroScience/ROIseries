;+
;  CHECK_RASTERSERIES: Check if a valid type of rasterseries was input and return the type
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

; optional helper function for CHECK_RASTERSERIES not to be called externally
FUNCTION ENVI_QUERY_IMAGE,im,CHANNELS=channels,DIMENSIONS=dimensions
    e=ENVI(/HEADLESS)
    TempRef=e.OpenRaster(im)
    CHANNELS = TempRef.nbands
    DIMENSIONS =[TempRef.ncolumns,TempRef.nrows]
    RETURN,1
END

;+
; Check if a valid type of rasterseries was input and return the type
;
; :Params:
;     rasterseries : in, required
;         rasterseries input of unknown type
;
; :Keywords:
;    BANDS
;    EXTENT
;
; :Returns:
;     String containing the type of rasterseries input, either of:
;         'SingleString', 'StringArray', 'ListOfStrings', 'ListOfNumericArrays', 'NumericArray'
;         
; :Examples:
;     IDL> ref = get_reldir('RASTER_INFO',2,['data','sentinel_2a','rasters'])
;     IDL> string_array = FILE_SEARCH(ref,"*studyarea.tif")
;     IDL> list_of_strings = string_array.toList()
;     IDL> list_of_numeric_arrays = list_of_strings.map(LAMBDA(i:READ_TIFF(i)))
;     IDL> numeric_array = list_of_numeric_arrays[0]
;     IDL> single_string = string_array[0]
;---------------------------------------------------------------------------------------------
;     IDL> CHECK_RASTERSERIES(string_array,BANDS=bands,EXTENT=extent)
;     IDL> print,bands
;     IDL> print,extent
;     IDL> CHECK_RASTERSERIES(list_of_strings,BANDS=bands,EXTENT=extent)
;     IDL> CHECK_RASTERSERIES(list_of_numeric_arrays,BANDS=bands,EXTENT=extent)
;     IDL> CHECK_RASTERSERIES(numeric_array,BANDS=bands,EXTENT=extent)
;     IDL> CHECK_RASTERSERIES(single_string,BANDS=bands,EXTENT=extent)
;     IDL> print,bands
;     IDL> print,extent
;
; :Description:
;
;	:Uses:
;
; :Author:
;     Niklas Keck ("niklas_keck'use at instead'gmx.de").replace("'use at instead'","@")
;-
FUNCTION CHECK_RASTERSERIES, rasterseries, BANDS=bands,EXTENT=extent
    ;=====================================================================================================================
    ; Determine type of rasterseries and save result to variable cas
    CASE TYPENAME(rasterseries) OF
        ;-----------------------------------------------------------------------------------------------------------------
        'STRING': BEGIN
                      IF N_ELEMENTS(rasterseries) EQ 1 THEN BEGIN
                          cas = 'SingleString'
                      ENDIF ELSE BEGIN
                          cas = 'StringArray'
                      ENDELSE
                  END
        ;-----------------------------------------------------------------------------------------------------------------
        'LIST':   BEGIN
                      IF TYPENAME(rasterseries[0]) EQ 'STRING' THEN BEGIN
                          cas = 'ListOfStrings'
                      ENDIF ELSE BEGIN
                          IF ISA(rasterseries[0],/NUMBER,/ARRAY) THEN BEGIN
                              cas = 'ListOfNumericArrays'
                          ENDIF ELSE BEGIN
                              MESSAGE,'Unsupported type of "rasterseries" parameter, please refer to documentation'
                          ENDELSE
                      ENDELSE
                  END
        ;-----------------------------------------------------------------------------------------------------------------
        ELSE:     BEGIN
                      IF ISA(rasterseries,/NUMBER,/ARRAY) THEN BEGIN
                          cas = 'NumericArray'
                      ENDIF ELSE BEGIN
                          MESSAGE,'Unsupported type of "rasterseries" parameter, please refer to documentation'
                      ENDELSE
                  END
    ENDCASE
    
    ;=====================================================================================================================
    ; Check input and get dimensionality
    ; 1. Multiple images with differing dimensions: Throw error!
    ; 2. Multiple images with 3 dimensions
    ; 3. Multiple images with more than 3 dimensions
    CASE cas OF
        'StringArray': BEGIN
                           temp = QUERY_IMAGE(rasterseries[0],CHANNELS=bands0,DIMENSIONS=extent0)
                           CASE temp OF
                               1: BEGIN
                                      FOREACH r,rasterseries[1:*] DO BEGIN
                                          temp=QUERY_IMAGE(r,CHANNELS=bands,DIMENSIONS=extent)
                                          IF bands NE bands0 THEN MESSAGE,"Raster has a different number of bands than the first one: "+r
                                          IF TOTAL(extent NE extent0) NE 0 THEN MESSAGE,"Raster has a different number of pixels in each band than the first one: "+r
                                      ENDFOREACH
                                  END
                               0: BEGIN
                                      tempE = ENVI_QUERY_IMAGE(rasterseries[0],CHANNELS=bands0,DIMENSIONS=extent0)
                                      FOREACH r,rasterseries[1:*] DO BEGIN
                                          temp=ENVI_QUERY_IMAGE(r,CHANNELS=bands,DIMENSIONS=extent)
                                          IF bands NE bands0 THEN MESSAGE,"Raster has a different number of bands than the first one: "+r
                                          IF TOTAL(extent NE extent0) NE 0 THEN MESSAGE,"Raster has a different number of pixels in each band than the first one: "+r
                                      ENDFOREACH
                                      ENVI.Close
                                  END
                           ENDCASE

                       END
        ;----------------------------------------------------------------------------------------------------------------------------------------
        'ListOfStrings': BEGIN
                             temp = QUERY_IMAGE(rasterseries[0],CHANNELS=bands0,DIMENSIONS=extent0)
                             CASE temp OF
                                 1: BEGIN
                                        FOREACH r,rasterseries[1:*] DO BEGIN
                                            temp=QUERY_IMAGE(r,CHANNELS=bands,DIMENSIONS=extent)
                                            IF bands NE bands0 THEN MESSAGE,"Raster has a different number of bands than the first one: "+r
                                            IF TOTAL(extent NE extent0) NE 0 THEN MESSAGE,"Raster has a different number of pixels in each band than the first one: "+r
                                        ENDFOREACH
                                    END
                                 0: BEGIN
                                        tempE = ENVI_QUERY_IMAGE(rasterseries[0],CHANNELS=bands0,DIMENSIONS=extent0)
                                        FOREACH r,rasterseries[1:*] DO BEGIN
                                            temp=ENVI_QUERY_IMAGE(r,CHANNELS=bands,DIMENSIONS=extent)
                                            IF bands NE bands0 THEN MESSAGE,"Raster has a different number of bands than the first one: "+r
                                            IF TOTAL(extent NE extent0) NE 0 THEN MESSAGE,"Raster has a different number of pixels in each band than the first one: "+r
                                        ENDFOREACH
                                        ENVI.Close
                                    END
                             ENDCASE
                         END
        ;----------------------------------------------------------------------------------------------------------------------------------------                         
        'ListOfNumericArrays': BEGIN
                                   sizeFull = SIZE(rasterseries[0])
                                   CASE sizeFull[0] OF
                                       3: BEGIN 
                                              bands0 = sizeFull[1]
                                              extent0 = sizeFull[2:3]
                                              FOREACH r,rasterseries[1:*] DO BEGIN
                                                  sizeFull = size(r)
                                                  IF sizeFull[1] NE bands0 THEN MESSAGE, "One of the arrays has a different number of bands than the first one"
                                                  IF TOTAL((sizeFull[2:3]) NE extent0) NE 0 THEN MESSAGE, "One of the arrays has a different number of pixels in each band"
                                              ENDFOREACH
                                          END
                                       2: BEGIN
                                              bands0 = 1
                                              extent0 = sizeFull[1:2]
                                              FOREACH r,rasterseries[1:*] DO BEGIN
                                                  sizeFull = size(r)
                                                  IF TOTAL((sizeFull[1:2]) NE extent0) NE 0 THEN MESSAGE,"One of the arrays has a different number of pixels"
                                              ENDFOREACH
                                          END
                                       ELSE: MESSAGE, "Arrays not with 2 or 3 dimensions are not supported"
                                   ENDCASE
                               END
        ;----------------------------------------------------------------------------------------------------------------------------------------                               
        'SingleString': BEGIN
                            temp = QUERY_IMAGE(rasterseries,CHANNELS=bands0,DIMENSIONS=extent0)
                            IF temp EQ 0 THEN BEGIN
                                tempE=ENVI_QUERY_IMAGE(rasterseries,CHANNELS=bands0,DIMENSIONS=extent0)
                                ENVI.close
                            ENDIF
                        END
        ;----------------------------------------------------------------------------------------------------------------------------------------
        'NumericArray': BEGIN
                            sizeFull = SIZE(rasterseries)
                            CASE sizeFull[0] OF
                                3:BEGIN
                                      bands0 = sizeFull[1]
                                      extent0 = sizeFull[2:3]
                                  END
                                2:MESSAGE,"Not 3D numeric arrays are not suitable. Please check documentation" 
                             END
                        END
    ENDCASE
    
    ; return data
    BANDS = bands0
    EXTENT = extent0
    RETURN,cas
END