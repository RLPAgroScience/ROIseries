;+
;  RS3D_plot: ROIseries_3D plot method implementation. Do not call directly
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
; ROIseries_3D plot method implementation. Do not call directly
;
; :Params:
;    self
;
; :Keywords:
;    ID
;    PERCENT_TO_PLOT
;    NONTEMPORALUNIT
;    _STRICT_EXTRA
;
; :Returns:
;
; :Examples:
;
; :Description:
;
;	:Uses:
;	    RS3D_reform_for_plots
;
; :Author:
;     Niklas Keck ("niklas_keck'use at instead'gmx.de").replace("'use at instead'","@")
;-
PRO RS3D_plot,self,ID=id,PERCENT_TO_PLOT=percent_to_plot,NONTEMPORALUNIT=nontemporalunit,_STRICT_EXTRA = e
    
    ; Check inputs
    IF N_ELEMENTS(self.unit) EQ 0 THEN MESSAGE,"Please specify [x,y] units"    
    IF N_ELEMENTS(ID) EQ 0 THEN BEGIN
        BUF = 1 ; to pass to the plot commands to hide the plot windows
        ID=(self.data).keys()
        path=self.db+"plots\"
        IF FILE_TEST(path,/DIRECTORY) EQ 0 THEN FILE_MKDIR,path
        print,"plots will be saved to: ",path
    ENDIF ELSE BEGIN
        BUF = 0
        ID=LIST(ID)
    ENDELSE
    IF KEYWORD_SET(NONTEMPORALUNIT) THEN XTICK="" ELSE XTICK="time"
    IF N_ELEMENTS(PERCENT_TO_PLOT) EQ 0 THEN BEGIN
        PERCENT_TO_PLOT = 100
        PRINT,'100 % will be plottet, this might overwhelm your computer and more importantly: Your patience. In that case: adjust the PERCENT_TO_PLOT keyword"
    ENDIF
    
    ; make plots for each pixel
    plot_data = RS3D_reform_for_plots(self.data,ID=id)
    FOREACH id_current,plot_data.keys() DO BEGIN
        IF N_ELEMENTS(self.class) NE 0 THEN class=(self.class)[id_current] ELSE class="unclassified"
        plot_data_current=plot_data[id_current]
        
        temp=PLOT(self.time,plot_data_current[0,*],":2+",$
                TITLE="'"+id_current+"'"+" of object [id="+STRTRIM(id_current,2)+", "+"class="+class+"]",$
                xtitle=((self.unit)[0]), $
                ytitle=((self.unit)[1]),XTICKUNITS=[XTICK],BUFFER=BUF)
        ; overplot for each pixel
        n = (SIZE(plot_data_current))[1]-1
        step =  FLOOR(100/PERCENT_TO_PLOT) 
        IF step LT n THEN BEGIN
            FOR i=LONG64(1),n,step DO temp=PLOT(self.time,plot_data_current[i,*],":2+",XTICKUNITS=[XTICK],/OVERPLOT,BUFFER=BUF)
        ENDIF
        
        IF N_ELEMENTS(ID) GT 1 THEN BEGIN
            w=GetWindows(NAMES=winNames,/CURRENT)
            w.save,path+"ID_"+STRTRIM(id_current,2)+".png"
            w.Close
        ENDIF
    ENDFOREACH

END