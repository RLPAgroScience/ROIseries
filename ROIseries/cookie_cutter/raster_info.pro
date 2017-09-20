;+
;  RASTER_INFO: Get raster infos (pixelsize, number of pixels, location)
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
; Get raster infos (pixelsize, number of pixels, location)
;
; :Params:
;    Raster: required, string
;
; :Keywords:
;    pnx: optional,variable, stores number of pixels in x direction
;    pny: optional,variable, stores number of pixels in y direction
;    PSX: optional,variable, stores size of pixels in x direction
;    PSY: optional,variable, stores size of pixels in y direction
;    X0: optional,variable, stores x position of tie point pixel  
;    Y0: optional,variable, stores y position of tie point pixel
;    UPSAMPLING: optional,numeric
;        Resampling factor used to transform all raster infos. 
;        
; :Examples:
;     IDL> raster = get_reldir('RASTER_INFO',2,['data','sentinel_2a','rasters'])+"S2A_L2A_UMV32N_20151207T103733_10m_studyarea.tif"
;     IDL> RASTER_INFO,raster,PNX=pnx,PNY=pny,PSX=psx,PSY=psy,X0=x0,Y0=y0
;     IDL> print,ORDEREDHASH(["pnx","pny","psx","psy","x0","y0"],[pnx,pny,psx,psy,x0,y0])
;     pnx:        70.0
;     pny:        41.0
;     psx:        10.0
;     psy:        10.0
;     x0:        441750.0
;     y0:        5469010.0
;     
; :Description:
;
;	:Uses:
;
; :Author:
;     Niklas Keck ("niklas_keck'use at instead'gmx.de").replace("'use at instead'","@")
;-
PRO RASTER_INFO,raster,PNX=pnx,PNY=pny,PSX=psx,PSY=psy,X0=x0,Y0=y0,UPSAMPLING=upsampling
    COMPILE_OPT idl2, HIDDEN
    
    temp=QUERY_TIFF(Raster,TIFFINFO,GEOTIFF=geokeys)
    IF temp EQ 1 THEN BEGIN ; if image is not a tiff ENVI will be used to read the file
        pnx=(TIFFINFO.DIMENSIONS)[0] ; x pixel number
        pny=(TIFFINFO.DIMENSIONS)[1] ; y pixel number
        psx= geokeys.ModelPixelSCALETAG[0] ; pixel size e. g. 1 m
        psy= geokeys.ModelPixelSCALETAG[1] ; pixel size e. g. 1 m
        IF N_ELEMENTS(UPSAMPLING) NE 0 THEN BEGIN
            pnx=pnx*UPSAMPLING
            pny=pny*UPSAMPLING
            psx=psx/upsampling
            psy=psy/upsampling
        ENDIF
        x0= geokeys.ModelTiePointTag[3] - geokeys.ModelTiePointTag[0]*psx
        y0= geokeys.ModelTiePointTag[4] + geokeys.ModelTiePointTag[1]*psy
        ; x0 and y0 are respectively the easting and northing of the NW corner of the image
    ENDIF ELSE BEGIN
        print, 'only tiff was implemented in pure IDL all other formats will be read using envi, which takes longer'
        e=ENVI(/HEADLESS)
        TempRef=e.OpenRaster(Raster)
        pnx=TempRef.NCOLUMNS
        pny=TempRef.NROWS
        SPATIAL=TempRef.SPATIALREF
        psx=SPATIAL.PIXEL_SIZE[0]
        psy=SPATIAL.PIXEL_SIZE[1]
        IF N_ELEMENTS(UPSAMPLING) NE 0 THEN BEGIN
            pnx=pnx*UPSAMPLING
            pny=pny*UPSAMPLING
            psx=psx/upsampling
            psy=psy/upsampling
        ENDIF
        x0=SPATIAL.TIE_POINT_MAP[0]-SPATIAL.TIE_POINT_PIXEL[0]*psx
        y0=SPATIAL.TIE_POINT_MAP[1]-SPATIAL.TIE_POINT_PIXEL[1]*psy
        e.Close
    ENDELSE

END