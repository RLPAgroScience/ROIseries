;--------------------------;
; ROIseries "Wine Tasting" ;
;--------------------------;

; This example demonstrates:
;     - the feature_sommelier

; =================================================================
; aim: Identify clouds in a series of Sentinel 2 (S2) Satellite images
; 
; strategy:
;     -------------------------------------------------------------
;     1: Feature Generation
;     For each combination of:
;         image-object, S2 scene, S2 band (10m) and NDVI
;             calculate MEAN, STDDEV, MIN and MAX
;     -------------------------------------------------------------
;     2: Feature Tasting
;     Feed the results to the feauture_sommelier together with
;     ground truth data to taste the usefullness of these features.
;     NOTE: The feature_sommelier is implemented in Python. 
;           In the future it will be possible to call it directly from IDL
;           via the IDL -> Python bridge. For now the feature_sommelier
;           has to be used directly within python.

; -------------------------------------------------------------
; 1: Feature Generation

; locate shapefile
ref = GET_RELDIR('ROIseries_3D__define',1,['data','sentinel_2a'])
shp = ref+"vector\"+"studyarea.shp"
id_col_name = "Id"

; create an array of pathes to Sentinel 2A scenes with known ground truth (cloudy: 'True' or 'False')
ground_truth = READ_CSV(ref+"table\scene_properties.csv")
filenames_csv = (ground_truth.FIELD1)[1:*]
cloudy_csv = (ground_truth.FIELD2)[1:*]
cloudy_knowledge_indices = WHERE((cloudy_csv EQ 'False') OR (cloudy_csv EQ 'True'))
cloudy_knowledge = cloudy_csv[cloudy_knowledge_indices]
rasterseries = ref + "rasters\"+filenames_csv[cloudy_knowledge_indices]

; Instantiate ROIseries_3D-objects for individual bands and NDVI
; Calculate MEAN, STDDEV, MIN, MAX for each image_object for each time step.
indexer_formula = LIST("R[0]","R[1]","R[2]","R[3]","(R[3]-R[0])/(R[3]+R[0])")
bands = LIST("R","G","B","NIR","NDVI")
csv_written = LIST()
FOR i=0,N_ELEMENTS(bands)-1 DO BEGIN &$
    print,"==================================================================" &$
    print,i &$
    current_object_3D = ROIseries_3D() &$
    temp = current_object_3D.COOKIE_CUTTER(bands[i],FILEPATH(bands[i]),shp,id_col_name,rasterseries,SPECTRAL_INDEXER_FORMULA=indexer_formula[i]) &$
    temp = current_object_3D.TIME_FROM_FILENAMES(rasterseries,[15,4],[19,2],[21,2], POSHOUR=[24,2],POSMINUTE=[26,2],POSSECOND=[28,2]) &$
    current_object_1D = current_object_3D.SPATIAL_MIXER("MEAN") &$
    csv_written.add, current_object_1D.FEATURES_TO_CSV(['RAW']) &$
    current_object_1D = current_object_3D.SPATIAL_MIXER("STDDEV") &$
    csv_written.add, current_object_1D.FEATURES_TO_CSV(['RAW']) &$
    current_object_1D = current_object_3D.SPATIAL_MIXER("MIN") &$
    csv_written.add, current_object_1D.FEATURES_TO_CSV(['RAW']) &$
    current_object_1D = current_object_3D.SPATIAL_MIXER("MAX") &$
    csv_written.add, current_object_1D.FEATURES_TO_CSV(['RAW']) &$
ENDFOR

; The list csv_written holds all paths to the CSVs containing the features.
; Execute the next line and then copy/paste the console output to your python script. 
csv_written