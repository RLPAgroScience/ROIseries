;+
;  GEN_DATE: Exract julian dates from strings by specification of positions
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
; Exract julian dates from strings by specification of positions
;
; :Params:
;    dates: in, required, string / strarr
;    posYear: in, required, numeric array
;        [First_Character,Length] (cp. documentation of STRMID)
;    posMonth:  in, required, numeric array
;        [First_Character,Length] (cp. documentation of STRMID)
;    posDay: in, required, numeric array
;        [First_Character,Length] (cp. documentation of STRMID)
; 
; :Returns:
;    numeric array containing the julian dates 
;
; :Examples:
;     IDL> dates_strings=["abc_20140403T103726_x.tif","abc_20160425T114332_x.tif","abc_20160623T231001_x.tif","abc_20170307T060101_x.tif"]
;     IDL> juldate_numeric = GEN_DATE(dates_strings,[4,4],[8,2],[10,2])
;     IDL> juldate_numeric_intraday = GEN_DATE(dates_strings,[4,4],[8,2],[10,2],POSHOUR=[13,2],POSMINUTE=[15,2],POSSECOND=[17,2])
;     IDL> print,juldate_numeric
;     IDL> print,juldate_numeric_intraday
;     IDL> CALDAT,juldate_numeric,Months,Days,Years
;     IDL> print,Months,Days,Years
;     IDL> CALDAT,juldate_numeric_intraday,Months,Days,Years,Hours,Minutes,Seconds
;     IDL> print,Months,Days,Years,Hours,Minutes,Seconds
;
; :Description:
;
; :Uses:
;
; :Author:
;     Niklas Keck ("niklas_keck'use at instead'gmx.de").replace("'use at instead'","@")
;-
FUNCTION GEN_DATE,dates,posYear,posMonth,posDay,POSHOUR=poshour,POSMINUTE=posminute,POSSECOND=possecond
    COMPILE_OPT idl2, HIDDEN
    
    ; Check input:
    IF N_ELEMENTS(dates) EQ 0 THEN MESSAGE,"Please provide 'dates'"
    dates = STRTRIM(dates,2)
    IF N_ELEMENTS(posYear) EQ 0 THEN MESSAGE,"Please provide 'posYear'"
    IF N_ELEMENTS(posMonth) EQ 0 THEN MESSAGE,"Please Provide 'posMonth'"
    length = STRLEN(dates)
    IF TOTAL((length[0] EQ length)) NE N_ELEMENTS(length) THEN MESSAGE,"All strings have to have the same format: Number of characters differs"
    mini= MIN([posYear,posMonth,posDay],MAX=maxi)
    IF (mini LT 0) OR (maxi GE length[0]) THEN MESSAGE,STRING(mini,maxi,FORMAT = "At least one pos is outside the range of the STRLEN: %d to %d")
    
    ; Input validation for fractions of days:
    n_posHour = N_ELEMENTS(poshour)
    n_posminute = N_ELEMENTS(posminute)
    n_possecond = N_ELEMENTS(possecond)
    IF (~n_posHour) && (~n_posminute) && (~n_possecond) THEN BEGIN
        cas = 0
    ENDIF ELSE BEGIN
        IF n_posHour && (~n_posminute) && (~n_possecond) THEN BEGIN
            cas = 1
        ENDIF ELSE BEGIN
            IF n_posHour && n_posminute && (~n_possecond) THEN BEGIN
                cas = 2
            ENDIF ELSE BEGIN
                 IF n_posHour && n_posminute && n_possecond THEN cas = 3 ELSE MESSAGE,"Specifying seconds without minutes and hours or minutes without hours is not supported"
            ENDELSE
        ENDELSE
    ENDELSE
    
    ; Get numbers from string
    years=[]
    months=[]
    days=[]
    IF n_posHour GT 1 THEN hours = []
    IF n_posMinute GT 1 THEN minutes = []
    IF n_possecond GT 1 THEN seconds = []
    
    FOREACH number,dates DO BEGIN $
        years=[years,STRMID(number,posYear[0],posYear[1])] &$
        months=[months,STRMID(number,posMonth[0],posMonth[1])] &$
        days=[days,STRMID(number,posDay[0],posDay[1])] &$
        IF n_posHour GT 1 THEN hours = [hours,STRMID(number,poshour[0],poshour[1])]
        IF n_posMinute GT 1 THEN minutes = [minutes,STRMID(number,posminute[0],posminute[1])]
        IF n_possecond GT 1 THEN seconds = [seconds,STRMID(number,possecond[0],possecond[1])]
    ENDFOREACH
    
    IF posYear[1] EQ 2 THEN BEGIN &$
      print,"warning: The year is not specified unambiguosly. 20XX will be assumed." &$
      years='20'+years &$
    ENDIF
    
    years=FLOAT(years)
    months=FLOAT(months)
    days=FLOAT(days)
    IF n_posHour GT 1 THEN hours=FLOAT(hours)
    IF n_posMinute GT 1 THEN minutes=FLOAT(minutes)
    IF n_possecond GT 1 THEN seconds=FLOAT(seconds)
    
    ; account for year 0
    NaN_year_i=WHERE(years LE 0)
    NaN_months_i=WHERE(months LE 0)
    NaN_days_i=WHERE(days LE 0)
    
    IF NaN_year_i NE -1 THEN BEGIN
        years[NaN_year_i]=1
        months[NaN_months_i]=1
        days[NaN_days_i]=1
        CASE cas OF
            0:datesJulian=JULDAY(months,days,years)
            1:datesJulian=JULDAY(months,days,years,hours)
            2:datesJulian=JULDAY(months,days,years,hours,minutes)
            3:datesJulian=JULDAY(months,days,years,hours,minutes,seconds)
        ENDCASE
        datesJulian=FLOAT(datesJulian)
        datesJulian[NaN_year_i]=!VALUES.F_NAN
    ENDIF ELSE BEGIN
        CASE cas OF
            0:datesJulian=JULDAY(months,days,years)
            1:datesJulian=JULDAY(months,days,years,hours)
            2:datesJulian=JULDAY(months,days,years,hours,minutes)
            3:datesJulian=JULDAY(months,days,years,hours,minutes,seconds)
        ENDCASE
    ENDELSE
    
    RETURN,datesJulian 
END