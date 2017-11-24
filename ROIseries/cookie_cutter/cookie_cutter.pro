;+
;  COOKIE_CUTTER: extract image-objects from a rasterseries based on a shapefile
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

; Cookie cutting helper function, not to be called externally
FUNCTION COOKIE_CUTTER_CUT,a,b,c,d
  a[b[*,0],b[*,1],b[*,2]]=(*c)[d[*,0],d[*,1],d[*,2]]
  Return,a
END

;+
; extract image-objects from a rasterseries based on a shapefile
;
; :Params:
;     SHAPEFILE in, required, type=string
;         Path to the shapefile
;    
;     ID_COL_NAME in, required, type=string
;         The thame of the column in the shapefile that holds the IDs to be used for each image-object
;    
;     RASTERSERIES in, require, type=strarr
;         - Stringarray with pathes to the rasters to use as multilayerd dough :)
;         - They have to have equal CRS and cover exactly the same region.
;           Use "rasterseries_to_studyarea" for input preparation
;         - If multiple input rasters are provided with multiple bands:
;           "SPECTRAL_INDEXER_FORMULA" has to be applied. To reduce the dimensionality to a maximum of 3
;          
; :Keywords:
;     SPECTRAL_INDEXER_FORMULA in, required depending on input (cp. RASTERSERIES parameter description), type=string
;         Formula to be used to convert a read multibandrasters into sinle band.
;         For example for an RGBNIR raster use: "(R[3]-R[0])/(R[3]+R[0])" to calculate the NDVI per raster in the input RASTERSERIES
;    
;     UPSAMPLING : in, optional, type = numeric
;         A factor how much to oversample the input images. This can be used if the resolution of a raster is to coarse compared to the
;         Shapefile and no pixels fall into the geometries. 
;
; :Returns:
;     ORDEREDHASH('raster_object_ids':arrays_of_rasterobject)
;
; :Examples:
;     IDL> ref = get_reldir('RASTER_INFO',2,['data','sentinel_2a'])
;     IDL> shp = ref+"vector\"+"studyarea.shp"
;     IDL> rasterseries = FILE_SEARCH(ref+"rasters\" + "\*.tif")
;     IDL> id_col_name = "Id"
;     IDL> spectral_indexer_formula = "(R[3]-R[0])/(R[3]+R[0])"
;     IDL> result = COOKIE_CUTTER(shp,id_col_name,rasterseries,SPECTRAL_INDEXER_FORMULA=spectral_indexer_formula)
;     IDL> print,(result[3])[*,*,3]
;
; :Description:
;     Given a shapefile, a column name containing IDs for each vector geometry and
;     series of rasters with equal spatial reference system and coverage return
;     a Hash containing a subraster for each vector geometry.
;
;	:Uses:
;     IndexFromShpRaster_RS, IndexReduce_RS, SPECTRAL_INDEXER
;     
; :Author:
;     Niklas Keck ("niklas_keck'use at instead'gmx.de").replace("'use at instead'","@")
;-
FUNCTION COOKIE_CUTTER,SHAPEFILE,ID_COL_NAME,RASTERSERIES,SPECTRAL_INDEXER_FORMULA=spectral_indexer_formula,UPSAMPLING=upsampling 
    COMPILE_OPT idl2, HIDDEN
    
    ; =================== CHECK AND PREPARE INPUT IMAGES: Aim: One 3D Array =====================================================================================
    ; Check preconditions: Same size and dimensions for each raster 
    input_type = CHECK_RASTERSERIES(rasterseries, BANDS=bands)
    allowed_types = ['SingleString','ListOfStrings','StringArray']
    IF ~allowed_types.HasValue(input_type) THEN MESSAGE,"Please provide rasterseries in one of the following formats: " +STRJOIN(allowed_types,", ")
    
    ; Read Images into list of arrays:
    ImageList=LIST()
    FOREACH f,RASTERSERIES DO BEGIN
      IF QUERY_TIFF(f) EQ 1 THEN BEGIN
        ImageList.Add,READ_TIFF(f)
      ENDIF ELSE BEGIN
        IF N_ELEMENTS(e) EQ 0 THEN e=ENVI(/HEADLESS)
        tempRef=e.OpenRaster(f)
        ImageList.Add,tempRef.GetData()
      ENDELSE
    ENDFOREACH
    IF N_ELEMENTS(e) NE 0 THEN e.close  
    
    ; If multiple images are provided AND each with with multiple bands then
    ; reduce the number of bands to one for each image: E.g. NDVI or simple average (spectral_indexer_formula) 
    IF  N_ELEMENTS(ImageList) NE 1 && bands GT 1 THEN BEGIN
      IF N_ELEMENTS(spectral_indexer_formula) EQ 0 THEN MESSAGE,"please provide spectral_indexer_formula to reduce input raster to 2 dimension"
      ImageList=ImageList.Map(Lambda(im,Form:SPECTRAL_INDEXER(im,Form)),spectral_indexer_formula)
    ENDIF
    
    ; Convert image list to one array and create a pointer array
    ImageArray=ImageList.ToArray(/NO_COPY,/TRANSPOSE)
    IF N_ELEMENTS(spectral_indexer_formula) EQ 0 AND N_ELEMENTS(RASTERSERIES) EQ 1 THEN ImageArray=TRANSPOSE(ImageArray,[1,2,0]) ; NEU
    
    ; If one image is provided with multiple bands and spectral_indexer_formula is present than apply spectral_indexer
    IF (N_ELEMENTS(spectral_indexer_formula) NE 0) AND (N_ELEMENTS(RASTERSERIES) EQ 1) AND (bands GT 1) THEN ImageArray=SPECTRAL_INDEXER(ImageArray,spectral_indexer_formula,DATATYPE_RESULT=4)
    
    print,"images loaded"
    
    ; =================== EXTRACTION OF ROIS FROM IMAGES =====================================================================================
    ; Get number of images in series:
    IF N_ELEMENTS(SIZE(ImageArray)) NE 5 THEN Pump=(SIZE(ImageArray))[3] ELSE Pump=1
    
    ; For each vector-object: Get the indices into the original rasterarrays considering:
    Index=ARRAY_INDICES_ROI_RS(RASTERSERIES[0],SHAPEFILE,ID_COL_NAME,UPSAMPLING=upsampling,PUMPUP=Pump)
    
    ; Reduce the retrieved indices to project the image-object into an array with the minimum size to hold the original object.
    RedIndex=ARRAY_INDICES_ROI_MINIMIZE_RS(Index["Index"],PUMPUP=Pump)
    
    ; Resample the array if neccessary to a finer resolution asp specified in upsampling parameter
    IF N_ELEMENTS(UPSAMPLING) NE 0 THEN BEGIN
      s=size(ImageArray,/DIMENSION)
      ImageArray=REBIN(ImageArray,s[0]*UPSAMPLING,s[1]*UPSAMPLING,s[2],/SAMPLE)
    ENDIF
    
    ; use a pointer for the list comprehension    
    ImageArPtr=PTR_NEW(/Allocate_Heap)
    *ImageArPtr=ImageArray
    ImageArPtrL=LIST(ImageArPtr,LENGTH=N_ELEMENTS(RedIndex["Red_ArrayL"]))
    print,"array indices generated"
    
    ; =================== RETURN RESULT as ORDEREDHASH ========================================================================================
    RETURN,ORDEREDHASH(Index["ID"],((RedIndex["Red_ArrayL"]).map('COOKIE_CUTTER_CUT',(RedIndex["Red_IndexL"]),ImageArPtrL,(Index["IndexPump"]))))
    
END