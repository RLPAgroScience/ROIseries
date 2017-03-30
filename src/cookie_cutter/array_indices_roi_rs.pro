;+
;  ARRAY_INDICES_ROI_RS: Get the array indices of ROIs defined by a shapefile for a certain raster
;  Copyright (C) 2016 Niklas Keck
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

; internal map function. Not to be called externally
FUNCTION MapFunk,data,ind
    COMPILE_OPT idl2, HIDDEN
    result=LIST()
    FOR i=0,N_ELEMENTS((*ind))-1 DO result.add,(*data)[*,((*ind)[i]): (i LE N_ELEMENTS((*ind))-2) ? ((*ind)[i+1])-1 : -1]; ternary operator to set index -1 for last element since not included in original
    RETURN,result
END

;+
;  Get the array indices of ROIs defined by a shapefile for a certain raster
;
; :Params:
;    Raster,required,string
;        path to the raster for which the ROI indices shall betermined
;     
;    Shp,required,string
;        path to the shapefile containing the geometries of the ROIs
;        
;    ID,required,string
;        name of the column within the shp that stores the IDs for each geometry
;
; :Keywords:
;    UPSAMPLING,optional,integer
;        Factor by which the raster is upsampled. Can be used to e. g. make sure that every ROI has at least one pixel.
;        
;    PUMPUP,optional,integer
;        If the aim are ARRAY_INDICES for a rasterseries, give the number of raster in the rasterseries.
;        For more information on rasterseries cp. the check_rasterseries routine.
;
; :Returns:
;     
; :Examples:
;     IDL> ref = get_reldir('ARRAY_INDICES_ROI_RS',2,['data','sentinel_2a'])
;     IDL> shp = ref+"vector\"+"studyarea.shp"
;     IDL> raster = (FILE_SEARCH(ref+"rasters\" + "\*.tif"))[0]
;     IDL> ID = "Id"
;     IDL> result = ARRAY_INDICES_ROI_RS(raster,shp,ID) 
;     IDL> print,result
;     IDL> help,(result['Index'])[0]
;
; :Description:
;     inspired by posts on https://groups.google.com/forum/#!topic/comp.lang.idl-pvwave/4E5kR9DxybQ
;
; :Uses:
;
; :Author:
;     Niklas Keck ("niklas_keck'use at instead'gmx.de").replace("'use at instead'","@")
;-
FUNCTION ARRAY_INDICES_ROI_RS,Raster,Shp,ID,UPSAMPLING=upsampling,PUMPUP=pumpup
    COMPILE_OPT idl2, HIDDEN
    
    ; Get the image properties: ;get the size and the geokeys from the raster
    IF N_ELEMENTS(UPSAMPLING) NE 0 THEN BEGIN
        RASTER_INFO,Raster[0],PNX=pnx,PNY=pny,PSX=psx,PSY=psy,X0=x0,Y0=y0,UPSAMPLING=upsampling
    ENDIF ELSE BEGIN
        RASTER_INFO,Raster[0],PNX=pnx,PNY=pny,PSX=psx,PSY=psy,X0=x0,Y0=y0
    ENDELSE
    
    ;import shapefile and get its attributes
    myshape= OBJ_NEW('IDLffShape', SHP)
    myshape->GetProperty,ATTRIBUTE_NAMES=attribute_names
    attr=(myshape->getAttributes(/ALL)).(WHERE(attribute_names eq ID))
    
    IF N_ELEMENTS(attr) LE 1 THEN RETURN,"YOU FOUND A BUG: IndexFromShp needs more than 1 Shape object to work.!!!"
    
    ; indexfrom_shptiff list listorized
    polyg=(myshape->IDLffShape::GetEntity(/ALL))
    
    ; try the same with polyg.Vertices
    vertices2=(polyg.Vertices).Map('mapfunk',polyg.PARTS)
    
    ; flatten the list
    vertices2_flat=LIST()
    FOREACH i,vertices2 DO BEGIN &$
        FOREACH k,i DO BEGIN &$
            vertices2_flat.add,k &$
        ENDFOREACH &$
    ENDFOREACH
    
    ; now calculated the featix/ys :)
    featix=vertices2_flat.map(LAMBDA(x,x0,psx:Round((Reform((x)[0,*])-x0)/psx)),x0,psx)
    featiy=vertices2_flat.map(LAMBDA(x,y0,psy:Round((y0-Reform((x)[1,*]))/psy)),y0,psy)
    
    ;===========================================================
    ; calculate indices
    func=LAMBDA(x,y,pnx,pny:POLYFILLV(x, y, pnx,pny))
    featis=featix.map(func,featiy,pnx,pny) ; old: featis=featix.map(func,featiy,pnx,pny)
    
    ; okay: use the legth given for each of the parts in the polygon to find indices that belong to the respective main and the hole polygons.
    ; Then Find unique pixel locations and assign them to the main polygon
    ; delete the rest of the list elements when the main elements have successfully been replaced by their respective reduced versions.
    
    terra=TOTAL(polyg.N_PARTS,/CUMULATIVE,/INTEGER)-1 ; can this overflow? ; polyg.N_PARTS used to be polyg->N_PARTS() befor compile opt_2 !!
    
    ; now find values that only appear once!!!
    luna=LIST()
    FOR i=0,N_ELEMENTS(terra)-1 DO BEGIN &$
        CSOF=featis[((i ne 0) ? terra[i-1]+1 : terra [i]):terra[i]] &$
        CSOF=CSOF[WHERE(CSOF NE -1)] &$ ; exclude cases where no pixel was found! This was the case for donut polygons that had and infinitesimal small hole in them: e. g. featis[terra[10136]] == -1
        CSOF_L=(LIST(CSOF,/EXTRACT)).toArray(DIMENSION=1) &$ ;CSOF=current set of pixels 
        ; this yields donuts if polygon is donut... THIS would yield seamless areas: CSOF[UNIQ(CSOF,SORT(CSOF))]:
        luna.add,[WHERE(histogram(CSOF_L,OMIN=om) EQ 1)+om] &$ 
    ENDFOR
    
    ; Now remove the indices from the main object that are present in the subobjects=holes
    
    ; erase empty:
    NullidArray=luna.WHERE(-1)
    IF N_ELEMENTS(NullidArray) EQ N_ELEMENTS(attr) THEN BEGIN
        PRINT,"None of the objects contains any pixel. Please use finer raster"
        RETALL
    ENDIF
    REMOVE,NullidArray,attr                               ; IDs
    featisClean=luna.filter(Lambda(x:x[0] NE -1))       ; indices
    
    featisCXY=featisClean.map(LAMBDA(x,pnx,pny:ARRAY_INDICES([pnx,pny],x,/DIMENSIONS)),pnx,pny)
    
    IF N_ELEMENTS(PUMPUP) NE 0 THEN BEGIN
        print,"Pumping up"
        func=LAMBDA(a,pumpup:[[REPCON(REFORM(a[0,*]),PUMPUP,1)],[REPCON(REFORM(a[1,*]),PUMPUP,1)],[REBIN(INDGEN(PUMPUP),N_ELEMENTS([REPCON(REFORM(a[1,*]),PUMPUP,1)]))]])
        featisCXYZpump=featisCXY.map(func,pumpup)
        RETURN,HASH(LIST("ID","Index","IndexPump"),LIST(attr,featisCXY,featisCXYZpump))
    ENDIF ELSE BEGIN
        RETURN,HASH(LIST("ID","Index"),LIST(attr,featisCXY))
    ENDELSE
END