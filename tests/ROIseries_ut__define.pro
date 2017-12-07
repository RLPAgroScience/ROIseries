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
    ASSERT,DETER_MINSIZE(ULONG(255),/NAME) EQ 1,'ULONG(255) not converted to BYTE by deter_minsize'
    ASSERT,DETER_MINSIZE(ULONG64(4294967295),/NAME) EQ 13,'LONG64(4294967295) not converted to ULONG by deter_minsize'
    
    ; Signed integers 
    ASSERT,DETER_MINSIZE(LONG64(-32768),/NAME) EQ 2,'LONG(-32768) not converted to INT by deter_minsize'
    ASSERT,DETER_MINSIZE(LONG64(-2147483648),/NAME) EQ 3,'LONG64(21474836647) not converted to LONG by deter_minsize'
    
    ; Floating points
    ASSERT,DETER_MINSIZE(DOUBLE(1.0),/NAME) EQ 4,'DOUBLE(1.0) not converted to FLOAT by deter_minsize'
    ASSERT,DETER_MINSIZE(DOUBLE(-10.0)^200,/NAME) EQ 5,'DOUBLE(-10.0)^200 not kept as FLOAT by deter_minsize'
    
    ; Changing Groups
    ASSERT,DETER_MINSIZE(DOUBLE(42.0),/NAME,/CHANGE_GROUP) EQ 1,'DOUBLE(-42.0) was not converted to BYTE by deter_minsize, even though /CHANGE_GROUP was set'
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

FUNCTION ROIseries_ut :: TEST_GLCM
    COMPILE_OPT idl2, HIDDEN
    
    ; Test 3 test cases with validation values found on: ; http://www.fp.ucalgary.ca/mhallbey/the_glcm.htm
    ; Case 1: GLCM_Matrix
    ; Case 2: Horizontal measures
    ; Case 3: Vertical measures
    ; 
    ; Test 3 test cases on normalization and binszie
    ; Case 4: Check that for this data the normalization should not change non 0 glcm fields.
    ; Case 5: Check that glcm has correct binsizes
    ; Case 6: Check that normalized glcm has correct binsize
    ; to avoid rounding errors as reason for failed ut, tests are performed only to the second second decimal place 
    
    ;---------------------------------------------------------------------------------------------------------------
    ; Setup
    img = [[0,0,1,1],[0,0,1,1],[0,2,2,2],[2,2,3,3]]
    bins = MAX(img,/NAN)-MIN(img,/NAN)+1
    new_min = 0
    new_max = 255
    bins_normalized = new_max - new_min + 1
    
    ; horizontal glcm
    glcm_horizontal_validation =[[0.166,0.083,0.042,0],[0.083,0.166,0,0],[0.042,0,0.249,0.042],[0,0,0.042,0.083]]
    glcm_horizontal = GLCM_MATRIX(img,0)
    glcm_horizontal_difference = ABS(glcm_horizontal - glcm_horizontal_validation) GT 0.01
    
    ; horizontal features
    features_validation_horizontal_names = ["CON","DIS","COR","MEAN","HOM","ASM","VAR","ENT"] ; ENE, STD and MAX are not on website
    features_validation_horizontal_values = [0.586,0.418,0.7182362,1.292,0.804,0.145,1.039067,2.0951]
    features_horizontal = GLCM_FEATURES(glcm_horizontal,features_validation_horizontal_names)
    horizontal_difference = ABS(features_horizontal - features_validation_horizontal_values) GT 0.01

    ; vertical features
    features_validation_vertical_names = ["DIS","MEAN","VAR"]
    features_validation_vertical_values = [0.664,1.162,0.969705]
    features_vertical = GLCM_FEATURES(GLCM_MATRIX(img,90),features_validation_vertical_names)
    vertical_difference = ABS(features_vertical-features_validation_vertical_values) GT 0.01
    
    ; normalization and binsize
    glcm_normalized = GLCM_MATRIX(img,0,normalize_rs_new_min_max=[new_min,new_max])
    glcm_horizontal_non0 = glcm_horizontal[WHERE(glcm_horizontal NE 0)]
    glcm_normalized_non0 = glcm_normalized[WHERE(glcm_normalized NE 0)]
    
    ;---------------------------------------------------------------------------------------------------------------
    ; Test cases
    ASSERT,TOTAL(glcm_horizontal_difference) LE 0, "glcm deviates in at least one entry more than 0.01 from validation"
    ASSERT,TOTAL(horizontal_difference) LE 0,"horizontal features deviating more than 0.01: "+ STRJOIN(features_validation_horizontal_names[WHERE(horizontal_difference)],", ") 
    ASSERT,TOTAL(vertical_difference) LE 0,"horizontal features deviating more than 0.01: " + STRJOIN(features_validation_vertical_names[WHERE(vertical_difference)],", ") 
    ASSERT,TOTAL(glcm_horizontal_non0 EQ glcm_normalized_non0)/N_ELEMENTS(glcm_horizontal_non0) EQ 1,"Normalization changed non 0 glcm fields"
    ASSERT,TOTAL(SIZE(glcm_horizontal,/DIMENSIONS) EQ [bins,bins])/2 EQ 1,"Glcm array size is not as expected: " + STRJOIN(STRTRIM(SIZE(glcm_horizontal,/DIMENSIONS),2),"X")+ " insteadt of "+ STRJOIN(STRTRIM([bins,bins],2),"X")
    ASSERT,TOTAL(SIZE(glcm_normalized,/DIMENSIONS) EQ [bins_normalized,bins_normalized])/2 EQ 1,"Normalization had effect on glcm array size: "+STRJOIN(STRTRIM(SIZE(glcm_normalized,/DIMENSIONS),2),"X")+ " insteadt of "+ STRJOIN(STRTRIM([bins_normalized,bins_normalized],2),"X")
    
    RETURN,1
END

FUNCTION ROIseries_ut :: TUTORIAL_SYSTEM_TEST
    COMPILE_OPT idl2, HIDDEN
    
    COMMON WalleWalle,ManscheStraecke
    time = ((TIMESTAMP()).replace("-",""))
    time = time.replace(":","")
    ManscheStraecke = FILEPATH("ROIseries_SystemTests\"+time+"\",/TMP)
    
    ;-----------------------------------------------------------------------------
    ; RS_WINE_TASTING tutorial
    out_folders = ManscheStraecke + ["R","G","B","NIR","NDVI"]
    
    ; Execute Script
    @rs_wine_tasting
    
    ; Get file infos
    csv_files_written = FILE_SEARCH(out_folders,"*.csv")
    csv_files_written_info = LIST(FILE_INFO(csv_files_written),/EXTRACT)
    too_small_size_per_file = csv_files_written_info.map(LAMBDA(x:x.size LT 1000))
    
    ASSERT,N_ELEMENTS(csv_files_written_info) EQ 20,"Not exactly 20 csv files where written in RS_WINE_TASTING"
    ASSERT,too_small_size_per_file.where(1) EQ !NULL,"Some csv files are less than 1kB in size, which seems daunting"
    PRINT,"Please manually clean up if required: " + ManscheStraecke
        
    RETURN,1
END


PRO ROIseries_ut__define
  COMPILE_OPT idl2, HIDDEN
  define = { ROIseries_ut, INHERITS MGutTestCase }
END