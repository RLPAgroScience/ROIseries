;+
;  STRDGEN: Generate array of up to 26 english letters
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
; Concise Desription of what the routine does.
;
; :Params:
;    D
;
; :Returns:
;
; :Examples:
;
; :Description:
;
; :Uses:
;
; :Author:
;     Niklas Keck ("niklas_keck'use at instead'gmx.de").replace("'use at instead'","@")
;-
FUNCTION STRDGEN,D
    
    IF N_ELEMENTS(D) EQ 0 THEN MESSAGE,'Please supply the number of characters you want to generate'
    IF D LE 0 || D GT 26 THEN MESSAGE,'This function supports only the generation of 1 to 26 characters'
    
    alphabet = ['a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z']
    
    RETURN,alphabet[0:D-1]
END