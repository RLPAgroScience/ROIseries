;----------------------------------;
; ROIseries "Dimensional Juggling" ;
;----------------------------------;

; This example demonstrates:
;     - The dimensional reduction from 4D to 1D
;     - Plotting during this dimensional reduction

; Literature:
; NDVI: https://ntrs.nasa.gov/archive/nasa/casi.ntrs.nasa.gov/19730017588.pdf
; S2 bands: https://earth.esa.int/web/sentinel/user-guides/sentinel-2-msi/resolutions/spatial

; Set some variables used throughout the script
cloudfree = ['S2A_L2A_UMV32N_20160902T103228_10m_studyarea.tif','S2A_L2A_UMV32N_20161002T103017_10m_studyarea.tif','S2A_L2A_UMV32N_20160922T103357_10m_studyarea.tif','S2A_L2A_UMV32N_20160823T103332_10m_studyarea.tif','S2A_L2A_UMV32N_20160813T103228_10m_studyarea.tif','S2A_L2A_UMV32N_20160624T103023_10m_studyarea.tif','S2A_L2A_UMV32N_20160505T103027_10m_studyarea.tif','S2A_L2A_UMV32N_20160126T104630_10m_studyarea.tif','S2A_L2A_UMV32N_20151207T103733_10m_studyarea.tif','S2A_L2A_UMV32N_20151227T104738_10m_studyarea.tif']
cloudfree = cloudfree[SORT(cloudfree)]
ref = GET_RELDIR('ROIseries_3D__define',1,['data','sentinel_2a'])
shp = ref+"vector\"+"studyarea.shp"
rasterseries = ref + "rasters\" + cloudfree
id_col_name = "Id"
id = "NDVI"
db = FILEPATH(id,/TMP)

; Instantiate ROIseries_3D object and add time metadata
NDVI_3D = ROIseries_3D()
NDVI_3D.COOKIE_CUTTER(id,db,shp,id_col_name,rasterseries,SPECTRAL_INDEXER_FORMULA="(R[3] - R[0])/(R[3] + R[0])")
NDVI_3D.TIME_FROM_FILENAMES(rasterseries,[15,4],[19,2],[21,2])

; Look at the available keys and make a plot with one of the keys
; In the gui: Zoom to see the full data by 1. clicking the magnifier and 2. click and hold somewhere in the visualization and move the mouse around
; turn on Contours for Z
; adjust the 'Z Plane' slider to see contour slices through time
print,(NDVI_3D.data).keys()
NDVI_3D.XVOLUME,4,/REVERSE

; Calculate the average NDVI over time and plot the result
; Compare variation of lightness in the 3D plot with the numeric variantion in 2D:
; => The time is plottet along the vertical axis in the 3D plot.
NDVI_1D_MEAN = NDVI_3D.SPATIAL_MIXER("MEAN")
NDVI_1D_MEAN.unit = LIST("time","Mean of NDVI per object")
NDVI_1D_MEAN.plot(ID = 4)

; Calculate the GLCM contrast in 45 degrees
NDVI_1D_CON45 = NDVI_3D.SPATIAL_MIXER("GLCM_CON_45")
NDVI_1D_CON45.unit = LIST("time","GLCM_CON_45 of NDVI per object")
NDVI_1D_CON45.plot(ID = 4)

; Generate 1D features values for the MEAN and CON45 ROIseries_1D objects:
; 'RAW': Individual values per image-object over time
; 'MEAN': Average over time per image-object
; 'STDDEV': Standard Deviation over time per image-object
NDVI_1D_MEAN.features_to_csv(['MEAN','STDDEV','RAW'])
NDVI_1D_CON45.features_to_csv(['MEAN','STDDEV','RAW'])

; Conclusion:
; Have a look at the pathes printed during the last two steps
; Theses are the final CSV files  holding 0D features to be used in e. g. machine learning 