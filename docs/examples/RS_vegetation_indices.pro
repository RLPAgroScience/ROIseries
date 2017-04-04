;--------------------------------;
; ROIseries "vegetation_indices" ;
;--------------------------------;

; This example demonstrates:
;     - 3D restriction of ROIseries
;     - Calculation of band indices via:
;         - operator overloading in ROIseries
;         - the spectral_indexer
;     - ROIseries_3D.boxplot method to display the distribution of values per object

; Literature:
; EVI: http://ac.els-cdn.com/S0034425702000962/1-s2.0-S0034425702000962-main.pdf?_tid=d7df32d0-194d-11e7-ac86-00000aacb35f&acdnat=1491320958_f2bde0c3f5280bd76b34562f75f78e32
; NDVI: https://ntrs.nasa.gov/archive/nasa/casi.ntrs.nasa.gov/19730017588.pdf
; S2 bands: https://earth.esa.int/web/sentinel/user-guides/sentinel-2-msi/resolutions/spatial

; Set some variables used throughout the script
cloudfree = ['S2A_L2A_UMV32N_20160902T103228_10m_studyarea.tif','S2A_L2A_UMV32N_20161002T103017_10m_studyarea.tif','S2A_L2A_UMV32N_20160922T103357_10m_studyarea.tif','S2A_L2A_UMV32N_20160823T103332_10m_studyarea.tif','S2A_L2A_UMV32N_20160813T103228_10m_studyarea.tif','S2A_L2A_UMV32N_20160624T103023_10m_studyarea.tif','S2A_L2A_UMV32N_20160505T103027_10m_studyarea.tif','S2A_L2A_UMV32N_20160126T104630_10m_studyarea.tif','S2A_L2A_UMV32N_20151207T103733_10m_studyarea.tif','S2A_L2A_UMV32N_20151227T104738_10m_studyarea.tif']
ref = GET_RELDIR('ROIseries_3D__define',1,['data','sentinel_2a'])
shp = ref+"vector\"+"studyarea.shp"
rasterseries = ref+ "rasters\" + cloudfree
id_col_name = "Id"

; Try to load multiple multispectral images
id ="S2"
db =FILEPATH(id)
RS = ROIseries_3D()
RS = RS.COOKIE_CUTTER(id,db,shp,id_col_name,rasterseries)
; This does not work: Providing multiple multispectral images would result in 4 Dimensions (1 spectral, 1 temporal, 2 spatial)
; This is not supported in ROIseries. It is however possible to eithere:
;     - 1: model 4 dimensions simply with multiple 3D objects.
;     - 2: supply the spectral_indexer_formula to remove the spectral dimension from each of the rasters

; ---------------------------------------------------------------------------------------------------
; 1: Multiple ROIseries_3D objects holding different Sentinel 2 bands

id_nir = "NIR"
db_nir = FILEPATH(id_nir,/TMP)
NIR = ROIseries_3D()
NIR.COOKIE_CUTTER(id_nir,db_nir,shp,id_col_name,rasterseries,SPECTRAL_INDEXER_FORMULA="R[3]")
NIR.TIME_FROM_FILENAMES(rasterseries,[15,4],[19,2],[21,2])
NIR.unit = ["time","Distribution of NIR Values per object"]

id_red = "RED"
db_red = FILEPATH(id_red,/TMP)
RED = ROIseries_3D()
RED.COOKIE_CUTTER(id_red,db_red,shp,id_col_name,rasterseries,SPECTRAL_INDEXER_FORMULA="R[0]")
RED.time = NIR.time

id_blue = "BLUE"
db_blue = FILEPATH(id_blue,/TMP)
BLUE = ROIseries_3D()
BLUE.COOKIE_CUTTER(id_blue,db_blue,shp,id_col_name,rasterseries,SPECTRAL_INDEXER_FORMULA="R[2]")
BLUE.time = NIR.time

; Plot the blue channel
BLUE.BOXPLOT()

; Calculate the EVI:
C1 = 6
C2 = 7.5
L = 1
G = 2.5
EVI = (NIR - RED)/(NIR + RED * C1 - BLUE * C2 + L) * G

; FIRE, GIRLS, MONEY, 9.1*10^-31 (or whatever makes you read the next lines :)):
; Caution has to be exercised when using numbers in such an expression (Like C1, C2, L and G):
;     They need to be placed as the 'right' argument e. g.:
;          Correct: NIR * 42
;          Wrong: 42 * NIR 
;      The reason is that the arithmetic functionality is defined for the ROIseries object, but undefined for a numeric value
;      For background information check the operator overloading functionality on e. g.:
;          https://www.harrisgeospatial.com/docs/IDL_Object_overloadAsterisk.html

; When array arithmetics are applied all metadata is lost since it is unpredictable what metadata would make sense to be kept.
; One exception is the time attribute which has to be the same for all objects anyway and is checked and handed over internally.
EVI.id = "EVI"
EVI.db = FILEPATH("EVI",/TMP)
EVI.unit = ["time","Distribution of EVI Values per object"]
EVI.boxplot()

; It is possible to use the objects to calculate any arbitrary indices like the NDVI
NDVI = (NIR-RED)/(NIR+RED)
NDVI.id = "NDVI"
NDVI.db = FILEPATH("NDVI",/TMP)
NDVI.unit = ["time","Distribution of NDVI Values per object"]
NDVI.boxplot()

; -----------------------------------------------------------------------------------------------------------
; 2: Using the spectral_indexer_formula to remove the spectral dimension from each of the rasters right away
EVI_2 = ROIseries_3D()
EVI_2.COOKIE_CUTTER("EVI_2",FILEPATH("EVI_2",/TMP),shp,id_col_name,rasterseries,SPECTRAL_INDEXER_FORMULA="(R[3] - R[0])/(R[3] + R[0] * 6 - R[2] * 7.5 + 1) * 2.5")
EVI_2.time = NIR.time
EVI_2.unit = ["time","Distribution of EVI Values per object"]
EVI_2.boxplot()

; Conclusion:
; Comparing the output from EVI_2.boxplot() and EVI.boxplot() you should notice that both ways lead to the same result.
; However they provide different levels of interactivity:
; Method 1 lets you explore and work on the individual bands first before combining them.
; Method 2 provides a convenient way to start your analysis after a specific index has already been calculated.