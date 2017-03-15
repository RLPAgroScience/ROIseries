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
;     IDL> dates_strings=["abc_20140403_x.tif","abc_20160425_x.tif","abc_20160623_x.tif","abc_20170307_x.tif"]
;     IDL> juldate_numeric = GEN_DATE(dates_strings,[4,4],[8,2],[10,2])
;     IDL> print,juldate_numeric
;     IDL> CALDAT,juldate_numeric,Months,Days,Years
;     IDL> print,Months,Days,Years
;
; :Description:
;
; :Uses:
;
; :Author:
;     Niklas Keck ("niklas_keck'use at instead'gmx.de").replace("'use at instead'","@")
;-
FUNCTION GEN_DATE,dates,posYear,posMonth,posDay
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
    
    ; Get numbers from string
    years=[]
    months=[]
    days=[]
    FOREACH number,dates DO BEGIN $
        years=[years,STRMID(number,posYear[0],posYear[1])] &$
        months=[months,STRMID(number,posMonth[0],posMonth[1])] &$
        days=[days,STRMID(number,posDay[0],posDay[1])] &$
    ENDFOREACH
    
    IF posYear[1] EQ 2 THEN BEGIN &$
      print,"warning: The year is not specified unambiguosly. 20XX will be assumed." &$
      years='20'+years &$
    ENDIF
    
    years=FLOAT(years)
    months=FLOAT(months)
    days=FLOAT(days)
    
    ; account for year 0
    NaN_year_i=WHERE(years LE 0)
    NaN_months_i=WHERE(months LE 0)
    NaN_days_i=WHERE(days LE 0)
    
    IF NaN_year_i NE -1 THEN BEGIN
      years[NaN_year_i]=1
      months[NaN_months_i]=1
      days[NaN_days_i]=1
      datesJulian=JULDAY(months,days,years)
      datesJulian=FLOAT(datesJulian)
      datesJulian[NaN_year_i]=!VALUES.F_NAN
    ENDIF ELSE BEGIN
      datesJulian=JULDAY(months,days,years)
    ENDELSE
    
    RETURN,datesJulian 
END