;+
;  ROIseries_ut: Unit Testing of ROIseries using mgunit
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
FUNCTION ROIseries_ut :: TEST_DETER_MINSIZE
    COMPILE_OPT idl2, HIDDEN
    
    ; Unsigned integers
    ASSERT,DETER_MINSIZE(ULONG(255),/NAME) EQ 'BYTE','ULONG(255) not converted to BYTE by deter_minsize'
    ASSERT,DETER_MINSIZE(ULONG64(4294967295),/NAME) EQ 'ULONG','LONG64(4294967295) not converted to ULONG by deter_minsize'
    
    ; Signed integers 
    ASSERT,DETER_MINSIZE(LONG64(-32768),/NAME) EQ 'INT','LONG(-32768) not converted to INT by deter_minsize'
    ASSERT,DETER_MINSIZE(LONG64(-2147483648),/NAME) EQ 'LONG','LONG64(21474836647) not converted to LONG by deter_minsize'
    
    ; Floating points
    ASSERT,DETER_MINSIZE(DOUBLE(1.0),/NAME) EQ 'FLOAT','DOUBLE(1.0) not converted to FLOAT by deter_minsize'
    ASSERT,DETER_MINSIZE(DOUBLE(-10.0)^200,/NAME) EQ 'DOUBLE','DOUBLE(-10.0)^200 not kept as FLOAT by deter_minsize'
    
    ; Changing Groups
    ASSERT,DETER_MINSIZE(DOUBLE(42.0),/NAME,/CHANGE_GROUP) EQ 'BYTE','DOUBLE(-42.0) was not converted to BYTE by deter_minsize, even though /CHANGE_GROUP was set'
    RETURN,1
END

FUNCTION ROIseries_ut :: TEST_CHECK_RASTERSERIES
    COMPILE_OPT idl2, HIDDEN
    ; Set Up
    dir = GET_RELDIR("CHECK_RASTERSERIES",2,["data","sentinel_2a","rasters"])
    string_array = FILE_SEARCH(dir,"*studyarea.tif")
    list_of_strings = string_array.toList()
    list_of_numeric_arrays = list_of_strings.map(LAMBDA(i:READ_TIFF(i)))
    numeric_array = list_of_numeric_arrays[0]
    single_string = string_array[0]
    ;------------------------------------------------------------------------------------
    ASSERT,CHECK_RASTERSERIES(string_array,BANDS=bands,EXTENT=extent) EQ 'StringArray','StringArray not detected' 
    ASSERT, bands EQ 4, 'Number of bands not detected'
    ASSERT, ARRAY_EQUAL(extent,[70,41]), 'Extent not detected successfully'
    ASSERT,CHECK_RASTERSERIES(list_of_strings) EQ 'ListOfStrings', 'ListOfStrings'
    ASSERT,CHECK_RASTERSERIES(list_of_numeric_arrays) EQ 'ListOfNumericArrays','ListOfNumericArrays not detected' 
    ASSERT,CHECK_RASTERSERIES(numeric_array) EQ 'NumericArray','NumericArray not detected' 
    ASSERT,CHECK_RASTERSERIES(single_string) EQ 'SingleString','SingleString not detected'
    RETURN,1
END

FUNCTION ROIseries_ut :: TEST_SPECTRAL_INDEXER
    COMPILE_OPT idl2, HIDDEN
    
    ;setup
    im = FINDGEN(4,10,10)
    im[0,*,*] = FINDGEN(10,10)
    im[1,*,*] = TRANSPOSE(REFORM(im[0,*,*]))
    im[2,*,*] = ROTATE(REFORM(im[1,*,*]),1)
    im[3,*,*] = TRANSPOSE(REFORM(im[2,*,*]))
    
    ndvi = REFORM((im[3,*,*]-im[0,*,*])/(im[3,*,*]+im[0,*,*]))
    path = FILEPATH("spectral_indexer_test.tif",/TMP)
    WRITE_TIFF,path,im,/FLOAT
    string_array = [path,path,path]
    list_of_strings = string_array.toList()
    single_string = string_array[0]
    list_of_numeric_arrays = list_of_strings.map(LAMBDA(i:READ_TIFF(i)))
    numeric_array = list_of_numeric_arrays[0]    
    formula_ndvi = "(R[3]-R[0])/(R[3]+R[0])"
    
    ; tests
    T1 = (SPECTRAL_INDEXER(string_array,formula_ndvi));[1]
    ASSERT,(TOTAL(SQRT((T1[1]-NDVI)^2))) LT 0.001,"String_array: ndvi index = 1 deviates too strongly"
    ASSERT,ARRAY_EQUAL(T1[0],T1[1]) AND ARRAY_EQUAL(T1[1],T1[2]),"String_array: NDVIs do not match"
    
    T2 = (SPECTRAL_INDEXER(list_of_strings,"R[2]"))
    ASSERT,ARRAY_EQUAL(T2[0],im[2,*,*]),"list_of_strings: channel index=2, index=3 do not match"
    ASSERT,ARRAY_EQUAL(T2[0],T2[1]) AND ARRAY_EQUAL(T2[1],T2[2]),"list_of_strings: NDVIs do not match"
    
    T3 = SPECTRAL_INDEXER(single_string,formula_ndvi)
    ASSERT,(TOTAL(SQRT((T3-NDVI)^2))) LT 0.001,"single_string: ndvi deviates too strongly"
    
    T4 = (SPECTRAL_INDEXER(list_of_numeric_arrays,formula_ndvi))
    ASSERT,(TOTAL(SQRT((T4[-1]-NDVI)^2))) LT 0.001,"list_of_numeric_arrays: ndvi deviates too strongly"
    ASSERT,ARRAY_EQUAL(T4[0],T4[1]) AND ARRAY_EQUAL(T4[1],T4[2]),"list_of_numeric_arrays: NDVIs do not match"
    
    T5 = (SPECTRAL_INDEXER(numeric_array,"R[-1]"))
    ASSERT,ARRAY_EQUAL(T5,im[3,*,*]),"numeric_array: index -1 does not work"
    
    RETURN,1
END

PRO ROIseries_ut__define
  COMPILE_OPT idl2, HIDDEN
  define = { ROIseries_ut, INHERITS MGutTestCase }
END