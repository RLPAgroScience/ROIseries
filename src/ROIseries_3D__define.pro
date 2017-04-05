;+
;  ROIseries_3D:  Class responsible for handling ROIseries objects with three dimension.
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
;  :Examples:

;
;-db_nir

; Extract 3D image-objects
FUNCTION ROIseries_3D :: COOKIE_CUTTER,id,db,SHAPEFILE, ID_COLNAME , RASTER, SPECTRAL_INDEXER_FORMULA=spectral_indexer_formula,NO_SAVE=no_save,UPSAMPLING=upsampling
    COMPILE_OPT idl2, HIDDEN
    
    ; Check inputs
    testv=[N_ELEMENTS(id),N_ELEMENTS(db),N_ELEMENTS(SHAPEFILE) NE 0,N_ELEMENTS(ID_COLNAME)NE 0,N_ELEMENTS(RASTER)NE 0]
    IF TOTAL(testv) NE N_ELEMENTS(testv) THEN BEGIN
        TESTVPos=WHERE(~TESTV)
        IF TESTVPos->HasValue(0) THEN PRINT,"Please provide id"
        IF TESTVPos->HasValue(1) THEN PRINT,"Plase provide db"
        IF TESTVPos->HasValue(2) THEN PRINT,"please provide path to SHAPEFILE"
        IF TESTVPos->HasValue(3) THEN PRINT,"please name the column in which the ID is stored"
        IF TESTVPos->HasValue(4) THEN PRINT,"please provide raster input"
        RETURN,0
    ENDIF
    
    IF FILE_TEST(DB,/DIRECTORY) EQ 0 THEN FILE_MKDIR,DB
    self.db = db
    self.id = id
    self.data=COOKIE_CUTTER(SHAPEFILE, ID_COLNAME , RASTER, SPECTRAL_INDEXER_FORMULA=spectral_indexer_formula,UPSAMPLING=upsampling)
    self->savetodb,"cookie_cutter"
    RETURN,1
END

; Reduce spatial dimension to convert 3D to 1D object:
FUNCTION ROIseries_3D :: spatial_mixer,statistics_type
    COMPILE_OPT idl2, HIDDEN

    RS1D = ROIseries_1D() 
    RS1D.parents = self.parents
    RS1D.legacy = self.legacy
    RS1D.DB = self.db
    RS1D.id = self.id
    RS1D.time = self.time
    RS1D.class = self.class
    RS1D.no_save = self.no_save
    RS1D.unit = self.unit
    RS1D.data=spatial_mixer(self.data,statistics_type)
    RS1D.savetodb,"spatial_mixer_"+statistics_type
    RETURN,RS1D
END

; calculate different attributes and save them as CSV
FUNCTION ROIseries_3D :: features_to_csv,FEATURES,CSV,PREFIX=prefix
    COMPILE_OPT idl2, HIDDEN
    
    IF N_ELEMENTS(PREFIX) EQ 0 THEN PREFIX=""
    
    data=self.data
    data_0=data[((data.keys())[0])]
    IF SIZE(data_0,/N_DIMENSIONS) EQ 3 THEN BEGIN ; check if temporal data dimension is still present
        time=STRTRIM(self.time,2)
        ; compare time to last (temporal) dimension
        IF N_ELEMENTS(time) NE (SIZE(data_0,/DIMENSIONS))[2] THEN RETURN,"length of time attribute and temporal array dimension differ"
        
        ; loop over time and data for each date
        FOREACH c,INDGEN(N_ELEMENTS(time)) DO BEGIN
            t=time[c]
            dataCurrent=data.map(Lambda(x,count:REFORM(x[*,*,count])),c) ; select current time step c
            dataCurrentPTR=ptr_new(dataCurrent)
            csvCurrent=FILE_DIRNAME(csv)+"\"+FILE_BASENAME(CSV,".csv")+"_"+t+".csv"
            RS3D_features_to_csv,FEATURES,csvCurrent,dataCurrentPTR,PREFIX=prefix+"_"+t+"_"
        ENDFOREACH
    ENDIF ELSE BEGIN
        RS3D_features_to_csv,FEATURES,CSV,self.data,PREFIX=prefix
    ENDELSE
    RETURN,1
END

; Plot functionality
FUNCTION ROIseries_3D :: plot,_EXTRA = e ; TO_FILE=to_file,PATH=path
    COMPILE_OPT idl2, HIDDEN
    
    ; Check input
    IF N_ELEMENTS(self.time) EQ 0 THEN RETURN,"Please add time attribute first"
    IF N_ELEMENTS(TO_FILE) EQ 1 && N_ELEMENTS(TO_FILE) EQ 0 THEN BEGIN
        PATH=self.DB+"plots\"
        print,"Plots will be saved to:"+PATH
        IF FILE_TEST(PATH,/DIRECTORY) EQ 0 THEN FILE_MKDIR,PATH
    ENDIF
  
    RS3D_plot,self,_STRICT_EXTRA = e
    RETURN,1
END

; Plot functionality
FUNCTION ROIseries_3D :: boxplot,_EXTRA = e ; TO_FILE=to_file,PATH=path
    COMPILE_OPT idl2, HIDDEN
    
    ; Check input
    IF N_ELEMENTS(self.time) EQ 0 THEN RETURN,"Please add time attribute first"
        IF N_ELEMENTS(TO_FILE) EQ 1 && N_ELEMENTS(TO_FILE) EQ 0 THEN BEGIN
        PATH=self.DB+"plots\"
        print,"Plots will be saved to:"+PATH
        IF FILE_TEST(PATH,/DIRECTORY) EQ 0 THEN FILE_MKDIR,PATH
    ENDIF
    
    RS3D_boxplot,self,_STRICT_EXTRA = e
    RETURN,1
END

PRO ROIseries_3D :: XVOLUME,ID,REVERSE=reverse
    COMPILE_OPT idl2, HIDDEN
    
    data = (self.data)[ID]
    
    ; Flip immage along horizontal axis
    IF KEYWORD_SET(REVERSE) THEN data = REVERSE(data,2)
    
    min=min(data,/NAN)
    max=max(data,/NAN)
    xnorm=BYTE((((data-min)/(max-min)))*255) ; scale to 0 - 255
    XVOLUME,xnorm,SCALE=[0.8, 0.8, 2.2]
END

;FORMAT=format,PATH=path,GROUNDTRUTH=GroundTruth,OTHEROBJECTS=otherobjects,MIX=mix,CLASS=class

PRO ROIseries_3D__define,void
    COMPILE_OPT idl2, HIDDEN
    void={ROIseries_3D,inherits ROIseries} ; to be able to classify rois
END