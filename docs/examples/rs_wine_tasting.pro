;--------------------------;
; ROIseries "Wine Tasting" ;
;--------------------------;

; This example demonstrates:
;     - the feature sommelier

; ===================================================
; aim: Identify clouds in a series of Sentinel 2 (S2) Satellite images
; strategy:
;     1. -------------------------------------------------------------
;     For each combination of:
;         image-object, S2 scene, S2 band (10m)
;             calculate MEAN and STDDEV
;     2. -------------------------------------------------------------
;     Feed the results to the feautre_sommelier together with cloud-truth to get
;     her opinion.

; 1. -------------------------------------------------------------
; Input variales
ref = GET_RELDIR('ROIseries_3D__define',1,['data','sentinel_2a'])
shp = ref+"vector\"+"studyarea.shp"
id_col_name = "Id"
x=READ_CSV(ref+"table\scene_properties.csv")
filenames_csv = (x.FIELD1)[1:*]
cloudy_csv = (x.FIELD2)[1:*]
cloudy_knowledge_indices = WHERE((cloudy_csv EQ 'False') OR (cloudy_csv EQ 'True'))
cloudy_knowledge = cloudy_csv[cloudy_knowledge_indices]

; A little hacky way to make a list appear as a scalar to the map function (https://www.harrisgeospatial.com/docs/HASH.html => Filter => Args
; If anyone knows something more elegant: Please let me know! This does not seem very ideomatic...
rasterseries = ref + "rasters\"+filenames_csv[cloudy_knowledge_indices]

; Make ROIseries_3D for individual bands
ids = LIST("R","G","B","NIR")
indexer_formula = LIST("R[0]","R[1]","R[2]","R[3]")
bands = LIST()
csv_written = LIST()
FOR i=0,3 DO BEGIN &$
    print,"==================================================================" &$
    print,i &$
    current_object_3D = ROIseries_3D() &$
    temp = current_object_3D.COOKIE_CUTTER(ids[i],FILEPATH(ids[i]),shp,id_col_name,rasterseries,SPECTRAL_INDEXER_FORMULA=indexer_formula[i]) &$
    temp = current_object_3D.TIME_FROM_FILENAMES(rasterseries,[15,4],[19,2],[21,2]) &$
    current_object_1D = current_object_3D.SPATIAL_MIXER("MEAN") &$
    csv_written.add, current_object_1D.FEATURES_TO_CSV(['RAW']) &$
    current_object_1D = current_object_3D.SPATIAL_MIXER("STDDEV") &$
    csv_written.add, current_object_1D.FEATURES_TO_CSV(['RAW']) &$
ENDFOR

; 2. -------------------------------------------------------------