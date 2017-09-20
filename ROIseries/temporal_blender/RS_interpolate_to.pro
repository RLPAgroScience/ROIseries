;+
;  RS_interpolate_to: Adjust the resolution of one ROIseries object to another ROIseries object. Do not call directly.
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

;+
; Adjust the resolution of one ROIseries object to another ROIseries object. Do not call directly.
;
; :Params:
;    S_TIME
;    O_TIME
;    S_VALUES
;
; :Returns:
;    The values from the self object adjusted to the resolution of the other object.
;
; :Examples:
;
; :Description:
;     ATTENTION: this function works only on ROIseries_1D objects.
;
; :Uses:
;
; :Author:
;     Niklas Keck ("niklas_keck'use at instead'gmx.de").replace("'use at instead'","@")
;-
FUNCTION RS_interpolate_to,S_TIME,O_TIME,S_VALUES
    COMPILE_OPT idl2, HIDDEN
    
    ; Get Positions in the OTHER where time matches with SELF
    MatchPos=[]
    FOREACH TIME_O,O_TIME DO MatchPos=[MatchPos,WHERE(S_TIME eq TIME_O)]
    
    ; Positions In OTHER where time matches with SELF
    O_TIME_MatchPos=WHERE(MatchPos ne -1)
    
    ; Position in OTHER where time DOES NOT match with self: These values have to be interpolated
    O_TIME_NoMatchPos=WHERE(MatchPos eq -1,/NULL)
    
    ; Position in SELF where time matches OTHER
    S_TIME_MatchPos=MatchPos[WHERE(MatchPos ne -1)]
    
    ; Get the values from SELF of S_TIME which has occourence in O_TIME: THIS IS DONE FOR ALL ROIS (since each roi on one raster has the same date)
    S_VALUES_FromMatch=[]
    FOREACH ROI,S_VALUES DO S_VALUES_FromMatch=[[S_VALUES_FromMatch],[ROI[S_TIME_MatchPos]]]
    
    ; Make NAN Array to store the results
    RESULT=MAKE_ARRAY(N_ElEMENTS(O_TIME),(N_ELEMENTS(S_VALUES)),VALUE=!VALUES.D_NAN)
    
    
    ; If no match was found do the following interpolation and fill in the values
    IF O_TIME_NoMatchPos NE !NULL THEN BEGIN
        ; new version
        O_TIME_POS_INSIDE=WHERE((O_TIME GE MIN(S_TIME)) * (O_TIME LE MAX(S_TIME)))
        
        ; Position vector with matching Positions
        UNIQUE_POS=UNIQ([O_TIME_NoMatchPos,O_TIME_POS_INSIDE]) ; To realise the testing in one loop
    
        ; Get positions that are in both vectors
        O_TIME_POS_NET=[]
        FOREACH pos,UNIQUE_POS DO IF O_TIME_NoMatchPos.HasValue(pos) * O_TIME_POS_INSIDE.HasValue(pos) THEN O_TIME_POS_NET=[O_TIME_POS_NET,pos]
    
        O_TIME_NoMatch_TIMEVals=O_TIME[O_TIME_POS_NET]
    
        S_VALUES_Interpol=[]
        FOREACH ROI,S_VALUES DO S_VALUES_INTERPOL=[[S_VALUES_INTERPOL],[INTERPOL(ROI,S_TIME,O_TIME_NoMatch_TIMEVals)]]
     
        ; fill in the calculated values
        FOR I=0,(N_ELEMENTS(S_VALUES_Interpol[1,*])-1) DO RESULT[O_TIME_POS_NET,I]=S_VALUES_Interpol[*,I] ; O_TIME_NoMatch_POS_INSIDE: Nicht die position in originaldaten! ODER
     
    ENDIF

    ; Store the matching time values. It has to be done after the if clause above since the if clause produced unecpected interpolation at dates where data in self already existed!
    ; It thus overwrites these miscalculated interpolations
    FOR I=0,(N_ELEMENTS(S_VALUES_FromMatch[1,*])-1) DO RESULT[O_TIME_MatchPos,I]=S_VALUES_FromMatch[*,I]

    c=0
    FOREACH key,S_VALUES.keys() DO BEGIN &$
        S_VALUES[key]=RESULT[*,c] &$
        c++ &$
    ENDFOREACH

    RETURN,S_VALUES

END