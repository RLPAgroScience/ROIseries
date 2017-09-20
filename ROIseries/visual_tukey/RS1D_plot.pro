;+
;  RS1D_plot: ROIseries_1D plot method implementation. Do not call directly.
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
; Create 2D plot from a ROIseries_1D object
;
; :Params:
;     RS_1D_self, in, required,type = ROIseries_1D
;
; :Keywords:
;     ID, in, optional
;         id-key of the image-object to be plotted (cp. (RS1D.data).keys())   
;        
;     FORMAT, in, optional, string
;         infos: https://www.harrisgeospatial.com/docs/formattingsymsandlines.html
;        
;     COLORTABLE_NB, in, optional, integers
;         number of colortable to be used for the plots as given by COLORTABLE()
;        
;     PATH, in, optional, string
;         path to save the plot to
;    
;     GROUNDTRUTH_TYPES, in, optional, strarr
;         names of groundtruth events to be included in the plot    
;    
;     GROUNDTRUTH_COLORTABLE_NB, in, optional, strarr
;         number of colortable to be used for the groundtruth plots as given by COLORTABLE()
;    
;     INCLUDE_FIRST_COLOR,in, optional, bool
;         A lot of the color brewer colortabes have something close to white as the first color.
;         So the first color should be omitted by default. Turning this keyword on, forces the routine
;         to include this first color.
;    
;     OTHEROBJECTS
;         Other ROIseries_1D objects to be included in the plot
;    
;     TITLE
;         Title of the plot
;        
; :Examples:
;     IDL> shp = GET_RELDIR("RS1D_plot",2,["data","sentinel_2a","vector"])+"studyarea.shp"
;     IDL> raster = (FILE_SEARCH(GET_RELDIR("RS1D_plot",2,["data","sentinel_2a","rasters"])+"*.tif"))[60:75]
;     IDL> wdir = FILEPATH("ROIseries_temp_folder",/TMP)
;     IDL> csv = GET_RELDIR("RS1D_plot",2,["data","sentinel_2a","table"])+"observations.csv"
;     IDL> ID_shp = "Id"
;     IDL> RS_gt =ROIseries_1D("RS_groundtruth_example",wdir,shp,ID_shp,raster,"MEAN",BANDCOMBFORMULA="R[3]")
;     IDL> RS_gt.unit = ["NIR","intensity"]
;     IDL> RS_gt.TIME_FROM_FILENAMES(raster,[15,4],[19,2],[21,2])
;     IDL> ID_csv = "ID"
;     IDL> types = ["before_harvest","after_harvest","before_ploughing","after_ploughing","second_veg_removal_before","second_veg_removal_after"]
;     IDL> RS_gt.GROUNDTRUTH_FROM_CSV(csv,types,ID_csv,[0,4],[4,2],[6,2])
;     IDL> RS_gt.plot(ID=1,GROUNDTRUTH_TYPES=types,GROUNDTRUTH_COLORTABLE_NB=74)
;     
; :Description:
;     If multiple groundtruth events fall on the same day, the tops of the lines are jittered by 1 day. 
;     
; :Uses:
;
; :Author:
;     Niklas Keck ("niklas_keck'use at instead'gmx.de").replace("'use at instead'","@")
;-
PRO RS1D_plot,RS_1D_self,ID=id,FORMAT=format,COLORTABLE_NB=colortable_NB,PATH=path,GROUNDTRUTH_TYPES=groundtruth_types,GROUNDTRUTH_COLORTABLE_NB=groundtruth_colortable_nb,INCLUDE_FIRST_COLOR=include_first_color, OTHEROBJECTS=otherobjects,TITLE=title ; Status: e.g. unwrapSD; 
    COMPILE_OPT idl2, HIDDEN

    ; Check input and set some variables:
    IF N_ELEMENTS(RS_1D_self.unit) EQ 0 THEN MESSAGE,"Please specify [x,y] units"
    IF N_ELEMENTS(colortable_nb) EQ 0 THEN colortable_nb=62
    IF N_ELEMENTS(groundtruth_colortable_nb) EQ 0 THEN groundtruth_colortable_nb=49
    IF KEYWORD_SET(INCLUDE_FIRST_COLOR) THEN SHIFT_COLOR=0 ELSE SHIFT_COLOR=1 
    objects_n = N_ELEMENTS(otherobjects)+1
    colors = COLORTABLE(colortable_nb,NCOLORS=objects_n+SHIFT_COLOR)
    colors = colors[shift_color:objects_n-1+shift_color,*] ; remove first color if shift_color = 1
    
    groundtruth_n = N_ELEMENTS(groundtruth_types)&$
    IF groundtruth_n NE 0 THEN BEGIN&$
        col_temp = COLORTABLE(groundtruth_colortable_nb,NCOLORS=groundtruth_n+shift_color)&$ ;http://ham.space.umn.edu/johnd/ct/ct-names.html
        col_temp=col_temp[shift_color:groundtruth_n-1+shift_color,*]
        col_temp_list=LIST()&$
        FOR i=0,groundtruth_n-1 DO col_temp_list.add,REFORM(col_temp[i,*])&$
        colors_gt=HASH(groundtruth_types,col_temp_list)&$
    ENDIF
    
    IF N_ELEMENTS(id) NE 0 THEN BEGIN
        dat = ORDEREDHASH(id,(RS_1D_self.data)[id])
        buffer = 0
    ENDIF ELSE BEGIN
        dat =RS_1D_self.data
        buffer = 1
    ENDELSE
    
    plot_margin=[0.15,  0.35,0.15, 0.15]
    Time=(RS_1D_self.time).ToArray()
    plot_xrange=[MIN(Time),MAX(Time)]
    IF N_ELEMENTS(FORMAT) EQ 0 THEN FORMAT= '-.'; '__.'
    mini = MIN((dat.values()).ToArray(),MAX=maxi, /NAN)
    
    ; Now plot for each key in dat
    FOREACH id,dat.keys() DO BEGIN

        ; If dat[id] does not contain any values 
        ; AND and another object is to be plottet
        ; AND the XTICKFORMAT is set, error occurs: PLOT: SETPROPERTY: Value of Julian date is out of allowed range.
        ; Solution: replace dat[id] with dummy and plot invisible!
        transparency = 0
        IF TOTAL(FINITE(dat[id])) EQ 0 THEN BEGIN
            print,"NaN resulted in blank plot for id: "+ id
            n = N_ELEMENTS(dat[id])
            dummy = FINDGEN(n)
            dat[id] = mini + ((dummy-0)/((n-1)-0)) * (maxi-mini) ; squeze into mini/maxi (https://en.wikipedia.org/wiki/Normalization_%28statistics%29)
            transparency = 100
        ENDIF
        
        object_nb=0
        P1=PLOT(Time,dat[id],FORMAT,$
            TRANSPARENCY = transparency,$
            BUFFER=buffer, $
            axis_style=1, $
            TITLE=RS_1D_self.id+" -- "+STRTRIM(id,2),$
            margin=plot_margin, $
            dimensions=[700,600], $
            XTEXT_ORIENTATION=45,$
            XTICKFORMAT='(C(CDI,1x,CMoA))',$ ; C(): CDI: days, 1x: 1 whitespace, CMOA: month, CYI: Years 
            XMAJOR=15,$
            XMINOR=10, $
            COLOR=REFORM(colors[object_nb,*]),$
            SYM_SIZE=1,$
            SYM_FILLED=1,$
            xtitle=(RS_1D_self.unit)[0], $
            ytitle=(RS_1D_self.unit)[1], $
            NAME=RS_1D_self.id)
        
        ;------------------------ OTHER OBJECTS ---------------------------------------------
        ooV=[] 
        IF N_ELEMENTS(OTHEROBJECTS) NE 0 THEN BEGIN
            FOREACH OO,OTHEROBJECTS DO BEGIN
                
                IF TOTAL(FINITE((OO.data)[id])) EQ 0 THEN BEGIN
                    PRINT,"Object with id: "+id+ "had only NaN values and thus was skipped"
                ENDIF ELSE BEGIN
                    object_nb++
                    ooV=[ooV,PLOT((OO.time).ToAarray(),(OO.data)[id],FORMAT,COLOR=REFORM(colors[object_nb,*]),SYM_SIZE=1,SYM_FILLED=1,/OVERPLOT,NAME=OO.id)]
                ENDELSE
            ENDFOREACH
            l1=LEGEND(TARGET=[p1,oov],POSITION=[0.9,0.2])    
        ENDIF ELSE BEGIN
            l2=LEGEND(TARGET=p1,POSITION=[0.9,0.2])
        ENDELSE
    
        ;------------------- Ground Truth -----------------------------------------------------
        tplots=[]
        IF N_ELEMENTS(groundtruth_types) NE 0 THEN BEGIN 
            IF ~ (RS_1D_self.groundtruth).HasKey(id) THEN CONTINUE ; skip to next loop if events for object are found 
            
            groundtruth_current_id=(RS_1D_self.groundtruth)[id]
            
            ; jitter events tops that have exactly the same date!
            ; 1. Get Unique Dates
            vals = groundtruth_current_id.values()
            vals_unpacked = LIST()
            FOREACH v,vals DO vals_unpacked.Add,v,/EXTRACT
            vals_unpacked_arr = vals_unpacked.toArray()
            vals_uni = vals_unpacked_arr[UNIQ(vals_unpacked_arr,SORT(vals_unpacked_arr))]
            
            ; 2. Count the number of occurences of those unique dates
            vals_uni_count=LIST()
            FOREACH v,vals_uni DO vals_uni_count.add,N_ELEMENTS(WHERE(vals_unpacked_arr EQ v))
            vals_uni_mod=vals_uni_count.map(LAMBDA(x,y:INDGEN(x)+y),vals_uni)
            replace_keys_with_values = HASH(vals_uni,vals_uni_mod)

            ; 3. Replace values that occur more than once:
            FOREACH k,replace_keys_with_values.keys() DO vals_unpacked[WHERE(vals_unpacked EQ k)] = replace_keys_with_values[k]

            ; 4. Insert the new values into the original list
            vals=vals.map(LAMBDA(x:LIST(x,/EXTRACT))) ; make sure that all items are lists, so they are mutable!
            c=0
            FOR i=0,N_ELEMENTS(vals)-1 DO BEGIN &$
                FOR k=0,N_ELEMENTS(vals[i])-1 DO BEGIN &$
                    vals[i,k] = [vals[i,k],vals_unpacked[c]] &$
                    c++ &$
                ENDFOR &$
            ENDFOR
            groundtruth_current_id_jittered = ORDEREDHASH(groundtruth_current_id.keys(),vals)
            
            legend_ref=[]
            FOREACH type,groundtruth_types DO BEGIN  &$
                type_present=0
                FOREACH t,groundtruth_current_id_jittered[type] DO BEGIN &$
                    IF TYPENAME(t) EQ 'STRING' THEN CONTINUE &$
                    IF t[0] GE plot_xrange[0] && t[0] LE plot_xrange[1] THEN BEGIN  &$
                        ploti=POLYLINE([t[0],t[1]],p1.YRANGE,/DATA,Target=p1,thick=2,color=colors_gt[type],name=type)  &$
                        type_present=1
                    ENDIF ELSE BEGIN  &$
                        print,"Some events where outside the range of the plot. To plot them: print the resulting graph to paper, get out a pen and draw some beautiful lines"  &$
                    ENDELSE  &$
                ENDFOREACH  &$
                IF type_present THEN legend_ref=[legend_ref,PLOT([t[0],t[1]],[MIN(dat[id],/NAN),MIN(dat[id],/NAN)],COLOR=colors_gt[type],name=type,/OVERPLOT,SYM_SIZE=0,SYMBOL="_")] &$
            ENDFOREACH
            
            temp = (LIST(legend_ref)).map(LAMBDA(x:x))
            l3=LEGEND(TARGET=legend_ref,POSITION=[0.2,0.2])
        ENDIF
        ;-------------------------------------------------------------------------------------------------
        IF N_ELEMENTS(ID) GT 1 THEN BEGIN
            w=GetWindows(NAMES=winNames,/CURRENT)
            IF N_ELEMENTS(path) NE 0 THEN w.save,path+RS_1D_self.id+"_"+STRTRIM(id,2)+".png"
            IF buffer EQ 1 THEN w.Close    
        ENDIF
    ENDFOREACH
END