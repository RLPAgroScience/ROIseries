;+
;  ROIseries__define: Root class of the ROIseries library. For inheritance only, do not instantiate directly.
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

; Initialize with defaults
FUNCTION RoiSeries :: init
    COMPILE_OPT idl2, HIDDEN
    
    self.data=HASH()
    self.parents=HASH()
    self.legacy=ORDEREDHASH()
    self.DB=''
    self.id=''
    self.time=LIST()
    self.class=HASH()
    self.no_save = 0
    self.unit=LIST()
    self.on_error = 1
    RETURN,1
END

; Extractimage-objects
FUNCTION ROIseries :: COOKIE_CUTTER,id,db,SHAPEFILE, ID_COLNAME , RASTER, SPECTRAL_INDEXER_FORMULA=spectral_indexer_formula,UPSAMPLING=upsampling
    COMPILE_OPT idl2, HIDDEN
    ON_ERROR,self.on_error

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
    result = COOKIE_CUTTER(SHAPEFILE, ID_COLNAME , RASTER, SPECTRAL_INDEXER_FORMULA=spectral_indexer_formula,UPSAMPLING=upsampling,TYPE=TYPENAME(self))
    self.data=result
    self->savetodb,"cookie_cutter"

    RETURN,1
END


; Save object to db
PRO RoiSeries :: savetodb,step
    COMPILE_OPT idl2, HIDDEN
    ON_ERROR,self.on_error
    
    IF self.no_save THEN BEGIN
        path=!Values.F_NAN
    ENDIF ELSE BEGIN
        path=self.db+step+".sav"
        IF N_ELEMENTS(self.legacy) EQ !NULL THEN BEGIN
            self.legacy=ORDEREDHASH(step,path)
        ENDIF ELSE BEGIN
            self.legacy=(self.legacy)+ORDEREDHASH(step,path)
        ENDELSE
        (SCOPE_VARFETCH(step,/ENTER))=self.clone(/KEEP_ID)
        SAVE,FILENAME=path,(SCOPE_VARFETCH(step,/ENTER))
        temp=(size(temporary((SCOPE_VARFETCH(step,/ENTER)))))
    ENDELSE
END

; Restore object to specified "step" from DB folder
FUNCTION RoiSeries :: reset,step
    COMPILE_OPT idl2, HIDDEN
    ON_ERROR,self.on_error
    
    ; Test if save was enabled.
    ; Not testing on self.no_save makes it possible to save only certain steps:
    ; IF ((*(self.legacy))[step]) EQ !Values.F_NAN THEN RETURN,"NO_SAVE was set"
    RESTORE,((self.legacy)[step])
    RETURN,(scope_varfetch(step,/ENTER))
END

;-------------------------------------------------------------------------------------
; Overloading some standard methods
; [] Overloading
FUNCTION RoiSeries::_overloadBracketsRightSide,isRange, sub
    COMPILE_OPT idl2, HIDDEN
    ON_ERROR,self.on_error
    
    IF isRange THEN print,"Ranges are not yet supported, use a list of keys instead"
    ; make a copy of the object and remove values that are not in the list sub1
    x=COPY_HEAP_RS(self)
    x.data=x.data[sub]
    IF typename(x.class) EQ "HASH" THEN x.class=x.class[sub]
    RETURN,x
END

; Get attributes out of Object: Thanks a lot for the inspiration!! (https://www.idlcoyote.com/tips/getproperty.html)
PRO RoiSeries::GetProperty,_ref_extra=extra
    COMPILE_OPT idl2, HIDDEN
    ON_ERROR,self.on_error

    Call_Procedure , Obj_Class(self)+'__define', struct
    index=(WHERE(Tag_Names(struct) EQ ((STRUPCASE(extra))[0]),count))[0]
  
    IF count NE 1 THEN BEGIN
        print,"Keyword not found"
    ENDIF ELSE BEGIN
        IF TYPENAME(self.(index)) EQ 'POINTER' THEN BEGIN
            (scope_varfetch(extra, /ref_extra)) = *(self.(index))           ; Do not give access to pointers inside the object!
        ENDIF ELSE BEGIN
            (scope_varfetch(extra, /ref_extra)) = self.(index)
        ENDELSE
    ENDELSE
END

PRO RoiSeries::SetProperty,_extra=extra
    COMPILE_OPT idl2, HIDDEN
    ON_ERROR,self.on_error
    
    Call_Procedure , Obj_Class(self)+'__define', struct
    name=((STRUPCASE(tag_names(extra)))[0])
    index=(WHERE(Tag_Names(struct) EQ name,count))[0]
  
    IF count NE 1 THEN BEGIN
        PRINT,"Keyword not found"
    ENDIF ELSE BEGIN
        IF TYPENAME(self.(index)) EQ 'POINTER' THEN BEGIN ; do not give access to pointer inside object
            *(self.(index))=extra.(0)
        ENDIF ELSE BEGIN
            self.(index)=extra.(0)
        ENDELSE
    ENDELSE
    self->savetodb,"set_"+name
END

; Overloading Arithmetics
; +
FUNCTION RoiSeries::_overloadPlus,left,right
    COMPILE_OPT idl2, HIDDEN
    ON_ERROR,self.on_error
    
    ; Check preconditions and return result
    result=OBJ_NEW(TYPENAME(left))
    IF ISA(right,'ROISERIES') THEN BEGIN
        test=RS_CHECK_ARITHMETIC_COMPATIBILITY(left,right)
        IF TYPENAME(test) EQ 'STRING' THEN Return,test
        result.data = ORDEREDHASH(((left.data).keys()),((left.data).values()).map(LAMBDA(x,y:x+y),((right.data).values())))
    ENDIF ELSE BEGIN
        result.data = ORDEREDHASH(((left.data).keys()),((left.data).values()).map(LAMBDA(x,y:x+y),right))
    ENDELSE
    result.time = left.time
    RETURN,result
END

; -
FUNCTION RoiSeries::_overloadMinus ,left,right
    COMPILE_OPT idl2, HIDDEN
    ON_ERROR,self.on_error
    
    ; Check preconditions and return result
    result=OBJ_NEW(TYPENAME(left))
    IF ISA(right,'ROISERIES') THEN BEGIN
        test=RS_CHECK_ARITHMETIC_COMPATIBILITY(left,right)
        IF TYPENAME(test) EQ 'STRING' THEN Return,test
        result.data = ORDEREDHASH(((left.data).keys()),((left.data).values()).map(LAMBDA(x,y:x-y),((right.data).values())))
    ENDIF ELSE BEGIN
        result.data = ORDEREDHASH(((left.data).keys()),((left.data).values()).map(LAMBDA(x,y:x-y),right))
    ENDELSE
    result.time = left.time
    RETURN,result
END

; *
FUNCTION RoiSeries::_overloadAsterisk,left,right
    COMPILE_OPT idl2, HIDDEN
    ON_ERROR,self.on_error
    
    ; Check preconditions and return result
    result=OBJ_NEW(TYPENAME(left))
    IF ISA(right,'ROISERIES') THEN BEGIN
        test=RS_check_arithmetic_compatibility(left,right)
        IF TYPENAME(test) EQ 'STRING' THEN Return,test
        result.data = ORDEREDHASH(((left.data).keys()),((left.data).values()).map(LAMBDA(x,y:x*y),((right.data).values())))
    ENDIF ELSE BEGIN
        result.data = ORDEREDHASH(((left.data).keys()),((left.data).values()).map(LAMBDA(x,y:x*y),right))
    ENDELSE
    result.time = left.time
    RETURN,result
END

; /
FUNCTION RoiSeries::_overloadSlash ,left,right
    COMPILE_OPT idl2, HIDDEN
    ON_ERROR,self.on_error
    
    ; Check preconditions and return result
    result=OBJ_NEW(TYPENAME(left))
    IF ISA(right,'ROISERIES') THEN BEGIN
        test=RS_check_arithmetic_compatibility(left,right)
        IF TYPENAME(test) EQ 'STRING' THEN Return,test
        result.data = ORDEREDHASH(((left.data).keys()),((left.data).values()).map(LAMBDA(x,y:x/y),((right.data).values())))
    ENDIF ELSE BEGIN
        result.data = ORDEREDHASH(((left.data).keys()),((left.data).values()).map(LAMBDA(x,y:x/y),right))
    ENDELSE
    result.time = left.time
    RETURN,result
END

; Overloading some standard methods
;------------------------------------------------------------------------------
; Custom size method since overloading the standard size method does not allow a hash to be returned
; Returns a hash with key:Dimensions
FUNCTION RoiSeries::DIMENSIONS
  COMPILE_OPT idl2, HIDDEN
  ON_ERROR,self.on_error
  
  RETURN,((self.data).map(LAMBDA(x:[size(x,/DIMENSIONS)])))
END

; Copy the whole object
FUNCTION RoiSeries::clone,KEEP_ID=keep_id
    COMPILE_OPT idl2, HIDDEN
    ON_ERROR,self.on_error
    
    ; make sure that the id is replaced by "ID_systime(1)" if KEEP_ID was not set:
    IF KEYWORD_SET(KEEP_ID) THEN BEGIN
        return,COPY_HEAP_RS(self)
    ENDIF ELSE BEGIN
        x=COPY_HEAP_RS(self)
        IF STRMID(x.id,2,/REVERSE_OFFSET) EQ "_C_" THEN BEGIN
            x.id=STRMID(x.id,0,STRLEN(x.id)-21)+"_"+STRTRIM(STRING(systime(1),FORMAT='(D0)'),2)+"_C_"
            return,x
        ENDIF ELSE BEGIN
            x.id=x.id+"_"+STRTRIM(STRING(systime(1),FORMAT='(D0)'),2)+"_C_"
            return,x
        ENDELSE
    ENDELSE
END

;===================== ADD INFOS ============================================================================
; Store time information from filenames and position within those filenames. If /BASENAME is set position can be specified from start of filename (opposed to start of path)
FUNCTION RoiSeries :: TIME_FROM_FILENAMES,Filenames,posYear,posMonth,posDay,_REF_EXTRA = ex
    COMPILE_OPT idl2, HIDDEN
    ON_ERROR,self.on_error
    
    ; Check input
    IF TYPENAME(Filenames) NE "STRING" THEN RETURN,"Please provide filenames"

    ; Generate a 1D array of dates    
    basenames = FILE_BASENAME(filenames)
    self.time=LIST(GEN_DATE(basenames,posYear,posMonth,posDay,_STRICT_EXTRA=ex),/EXTRACT)
    self->savetodb,"TIME_FROM_FILENAMES"
    RETURN,1
END


; Store groundtruth information in object
FUNCTION RoiSeries :: GROUNDTRUTH_FROM_CSV,csv,types,ID_Colname,posYear,posMonth,posDay,AGGREGATE=aggregate
    COMPILE_OPT idl2, HIDDEN
    ON_ERROR,self.on_error
    
    ; get groundtruths
    self.groundtruth=GROUNDTRUTH_FROM_CSV(csv,types,ID_Colname,posYear,posMonth,posDay,AGGREGATE=aggregate)
    self->savetodb,"GroundTruth"
    RETURN,1
    
END

; Store class information for each roi in object
FUNCTION RoiSeries :: classify,shp,ID_Colname,Class_Colname
    COMPILE_OPT idl2, HIDDEN
    ON_ERROR,self.on_error
    
    IF N_ELEMENTS(SHP) EQ 0 THEN RETURN,"Please provide path to shapefile"
    IF N_ELEMENTS(ID_Colname) EQ 0 THEN RETURN,"Please provide name of id column"
    IF N_ELEMENTS(Class_Colname) EQ 0 THEN RETURN, "Please provide name of class colum"
    
    ; extract attributes
    myshape= OBJ_NEW('IDLffShape', SHP)
    myshape->GetProperty,ATTRIBUTE_NAMES=attribute_names
    id=(myshape->getAttributes(/ALL)).(WHERE(attribute_names eq ID_Colname))
    class=(myshape->getAttributes(/ALL)).(WHERE(attribute_names eq Class_Colname))
    cHash=HASH(TEMPORARY(id),TEMPORARY(class))
    
    ; remove entries that do not exist in self.data 
    self.class=cHash[(self.data).keys()]
    self->savetodb,"classify"
    return,1
END

; Extract certain classes out of object
FUNCTION RoiSeries :: GetClass, class
    COMPILE_OPT idl2, HIDDEN
    ON_ERROR,self.on_error
    
    selfC=COPY_HEAP_RS(self)
    keys=(selfC.class).where(class)
    selfC.data=(selfC.data)[keys]
    selfC.class=(selfC.class)[keys]
    
    selfC->savetodb,"Get:"+class
    Return,selfC
END

; Filter Data
FUNCTION RoiSeries::temporal_filter,TYPE,N
    COMPILE_OPT idl2, HIDDEN
    ON_ERROR,self.on_error
    
    ; 1. Check if the time series is equally distributed (all temporal differences are the same)
    IF N_ELEMENTS(self.time) EQ 0 THEN MESSAGE,"The time property has to be set first!"
    temp_diff=((TS_DIFF((self.time).ToArray(),1))[0:-2])
    x=temp_diff[sort(temp_diff)]
    IF x[0] NE x[-1] THEN BEGIN &$
        PRINT,"The time property has unequally distributed time differences. Have a look at the returned numbers."
        RETURN,temp_diff
    ENDIF
  
    CASE TYPE OF
        "FFT": BEGIN
                   PRINT,"NEEDS TO BE UPDATED, RESULTS AND ROUTINE UNRELIABLE!: MOVED HERE FROM 1D"
                   ; test arithmetic conditions
                   conditions=RS_check_arithmetic_compatibility(self,N)
                   IF conditions NE 1 THEN RETURN,0
            
                   ; get out data
                   self_dat=self.data
                   N_dat=N->get()
            
                   ; do calculations
                   FOREACH ROI,self_dat.keys() DO BEGIN; Cannot handle NaN (FFT)
                       self_dat[ROI]=FFT(self_dat[ROI])
                       N_dat[ROI]=FFT(N_dat[ROI])
                       self_dat[ROI]=self_dat[ROI]-N_dat[ROI]
                       self_dat[ROI]=FFT(self_dat[ROI],/INVERSE)
                   ENDFOREACH
            
                   ; update legacy
                   self->savetodb,("filter_"+TYPE+(N->get("id")))
                   RETURN,1
               END
               
               ;"SUM": BEGIN
               ;  FOREACH ROI,(*(self.data)).keys() DO (*(self.data))[ROI]=MovingTotal((*(self.data))[ROI])
               ;  self->savetodb,("filter_"+TYPE+STRTRIM(N,2)+"_"+SET)
               ;  RETURN,1
               ;END
  
               ;----------- WRAPED OBJECTS -----------------------------------------------------------------------------
  
               ;    "NoDATA": BEGIN
               ;      IF STRMID(self.status,0,6) EQ "unwrap" THEN RETURN,"The NoDATA filter was designed for wraped=set objects, using an unwraped object would result in false values"
               ;      data=*(self.data)
               ;      FOREACH raster,data.keys() DO BEGIN &$
               ;        FOREACH ID,(data(raster)).keys() DO BEGIN &$
               ;          FOR I=0,(N_ELEMENTS((data(raster))(ID))-1) DO BEGIN &$
               ;            number=((data(raster))(ID))[I] &$
               ;            IF (number LT N[0] || number GT N[1]) THEN BEGIN &$
               ;              x=DOUBLE((data(raster))(ID)) &$
               ;              x[I]=!VALUES.D_NAN &$
               ;              ((data(raster))(ID))=x&$
               ;            ENDIF &$
               ;          ENDFOR  &$
               ;        ENDFOREACH &$
               ;      ENDFOREACH
               ;    (*(self.data))=data
               ;    self->savetodb,("filter_"+TYPE+"_"+STRTRIM(N[0],2)+"_"+STRTRIM(N[1],2))
               ;    RETURN,1
               ;
               ;  END
  
               ELSE: FOREACH ROI,(self.data).keys() DO (self.data)[ROI]=(MOVING_STATS_RS((self.data)[ROI],N))[STRLOWCASE(TYPE)]
    ENDCASE
    
    ; update time property
    self.time=(self.time)[N-1:*]
    RETURN,1

END

;====================== OBJECT DEFINITION =====================================================================
PRO RoiSeries__define,void
    COMPILE_OPT idl2, HIDDEN 
    void={RoiSeries, $
        data : HASH(),$
        time : LIST(),$
        groundtruth: HASH(),$ ; e. g. MAHD :)
        parents: HASH(),$; e. g. (ID1:legacy1,ID2:legacy2)
        legacy : ORDEREDHASH(),$  ; to store calculation legacy
        DB : '',$ ; The place to store the steps
        id : '',$ ;to have an ID to reference object (for legacy)
        class: HASH(), $ ; to be able to classify rois
        no_save:BOOLEAN(0), $ ; enable saving by default
        unit:LIST(),$
        on_error:1,$
    INHERITS IDL_OBJECT} ; to overload IDL get properties methods
END