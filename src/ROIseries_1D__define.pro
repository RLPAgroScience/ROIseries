;+
;  ROIseries_1D: Class responsible for handling ROIseries objects that have been reduced to one dimension.
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

;======================= Ploting ============================================================================
; Plot the RoiSeries
FUNCTION ROIseries_1D :: plot,_REF_EXTRA=e;ID=id,FORMAT=format,PATH=path,GROUNDTRUTH_TYPES=groundtruth_types,OTHEROBJECTS=otherobjects,MIX=mix,CLASS=class,TITLE=title
    COMPILE_OPT idl2, HIDDEN
    
    IF N_ELEMENTS(self.time) EQ 0 THEN MESSAGE,"Please add time attribute first"
    IF N_ELEMENTS(self.unit) EQ 0 THEN MESSAGE,"Plaase add [x,y] unit attribute first"
    
    IF N_ELEMENTS(PATH) EQ 0 THEN BEGIN
        PATH=self.DB+"plots\"
        print,"Plots will be saved to:"+PATH
        IF FILE_TEST(PATH,/DIRECTORY) EQ 0 THEN FILE_MKDIR,PATH
    ENDIF
  
    IF N_ELEMENTS(mix) EQ 0 THEN BEGIN
        RS1D_plot,self,PATH=path,_EXTRA=e;ID=id,FORMAT=format,,GROUNDTRUTH_TYPES=groundtruth_types,OTHEROBJECTS=otherobjects,TITLE=title
    ENDIF ELSE BEGIN
        IF mix EQ "Box" THEN boxplot_RS,self,PATH=path,_EXTRA=e;PATH=path,FORMAT=format,CLASS=class
    ENDELSE
    
    RETURN,1
END

;======================= Filtering & Transforming =================================================================

;; Normalize one RS object
; for formulas check: http://en.wikipedia.org/wiki/Normalization_%28statistics%29
FUNCTION ROIseries_1D :: normalize  
    COMPILE_OPT idl2, HIDDEN
    
    keys=((self.data).keys()).ToArray()
    dat=((self.data).values()).ToArray()
    
    FOR I=0,(N_ELEMENTS(dat[*,0])-1) DO BEGIN
        min=MIN(dat[I,*],/NAN)
        max=MAX(dat[I,*],/NAN)
        normal=(dat[I,*]-min)/(max-min)
        (self.data)[keys[I]]=REFORM(normal) ; REFORM to eliminate empty dimensions
    ENDFOR
    
    self->savetodb,"normalize"
    RETURN,1 
END

; Interpolate one RS Object to another to have the same time intervalls
PRO ROIseries_1D :: interpolate_to,other_object ;Extra/Intra Ultrapolate the current object onto the other one
    COMPILE_OPT idl2, HIDDEN
    
    ; Get Old (SELF) and new(OTHER) time Values
    self.data=RS_interpolate_to(self.time,other_object.time,self.data)
    
    ; store the resulting times:
    ; Generated keys:
    CALDAT,LONG(other_object.time),Months,Days,Years
    baseName=self.id+"->InterpolatedTO("+other_object.id+")"
    names=[] ;
    FOR I=0,(N_ELEMENTS(Years)-1) DO names=[names,baseName+"_"+STRTRIM(Years[I],2)+STRTRIM(Months[I],2)+STRTRIM(Days[I],2)]
    self.time=other_object.time
    self->savetodb,"InterpolatedTO_"+(other_object.id)
END

; saves the features per time step and roi to a csv.
FUNCTION ROIseries_1D :: FeaturesToCSV,FEATURES,CSV,PREFIX=prefix
    COMPILE_OPT idl2, HIDDEN
    
    IF N_ELEMENTS(PREFIX) EQ 0 THEN PREFIX=""
    
    data=self.data
    data_0=data[((data.keys())[0])]
    time=STRTRIM(self.time,2)
    
    ; compare time to last (temporal) dimension
    IF N_ELEMENTS(time) NE (SIZE(data_0,/DIMENSIONS)) THEN RETURN,"length of time attribute and temporal array dimension differ"
    
    ; loop over time and data for each date
    FOREACH c,INDGEN(N_ELEMENTS(time)) DO BEGIN
        t=time[c]
        dataCurrent=data.map(Lambda(x,count:REFORM(x[count])),c) 
        dataCurrentPTR=ptr_new(dataCurrent)
        csvCurrent=FILE_DIRNAME(csv)+"\"+FILE_BASENAME(CSV,".csv")+"_"+t+".csv"
        FtoCSV_RS,FEATURES,csvCurrent,dataCurrentPTR,PREFIX=prefix+"_"+t+"_"
    ENDFOREACH
    RETURN,1
END

;====================== OBJECT DEFINITION =====================================================================
PRO ROIseries_1D__define,void
  COMPILE_OPT idl2, HIDDEN
  void={ROIseries_1D,inherits ROIseries}
END