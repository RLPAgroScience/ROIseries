;+
;  HIST_2D_NAN: Wrapper routine for HIST_2D to work with arrays containing NaN values
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
; Wrapper routine for HIST_2D to work with arrays containing NaN values
;
; :Params:
;    img_1 : in, required, type=numeric array
;    img_2 : in, required, type=numeric array
;
; :Returns:
;      Returns a LONGARR(bin,bin), where bin = difference between highest min and max from both img_1 and img_2 
;
; :Examples:
;     For example::
;
;         IDL> img_1 = [[0,1,1],[0,1,1],[2,2,2],[2,3,3]]
;         IDL> img_2 = [[0,0,1],[0,0,1],[0,2,2],[2,2,3]]
;         IDL> print, img_1
;             0    1    1
;             0    1    1
;             2    2    2
;             2    3    3
;
;         IDL> print, img_2
;             0    0    1
;             0    0    1
;             0    2    2
;             2    2    3
;
;         IDL> result = HIST_2D_NAN(img_1, img_2)
;         IDL> print,result
;             2    2    1    0
;             0    2    0    0
;             0    0    3    1
;             0    0    0    1
;
;         The 2 in the column with index 1 (second) and row index 0 (first) means:
;             -> The combination of a 1 in img_1 at the same position as a 0 in img_2 occurs 2 times.
;
;         ; With NaN
;         IDL> img_1 = [[0,!Values.D_NAN,1],[0,1,1],[2,2,2],[2,3,3]]
;         IDL> img_2 = [[0,0,1],[0,0,1],[0,!VALUES.F_NAN,2],[2,2,3]]
;         IDL> print, img_1
;             0  NaN    1
;             0    1    1
;             2    2    2
;             2    3    3
;
;         IDL> print, img_2
;             0    0    1
;             0    0    1
;             0  NaN    2
;             2    2    3
;
;         IDL> result = HIST_2D_NAN(img_1, img_2)
;         IDL> print,result
;             2    1    1    0
;             0    2    0    0
;             0    0    2    1
;             0    0    0    1
;
;         ; With NaN AND unequal min max values
;         IDL> img_1 = [[0,!Values.D_NAN,1],[0,1,1],[2,2,2],[2,3,3]]
;         IDL> img_2 = [[0,0,1],[0,0,1],[0,!VALUES.F_NAN,2],[4,2,3]]
;         IDL> print, img_1
;             0  NaN    1
;             0    1    1
;             2    2    2
;             2    3    3
;
;         IDL> print, img_2
;             0    0    1
;             0    0    1
;             0  NaN    2
;             4    2    3
;
;         IDL> result = HIST_2D_NAN(img_1, img_2)
;         IDL> print,result
;             2    1    1    0    0
;             0    2    0    0    0
;             0    0    1    1    0
;             0    0    0    1    0
;             0    0    1    0    0
;
; :Description:
;     Calculate the 2D histogram of two 2D input arrays that might contain NaN values.
;     Just a small wrapper routine for the IDL iternal hist_2D.
;     How it works: 
;         - Set NaN values to maximum value + 1 (dummy value)
;         - Calculate hist_2D
;         - Remove last column and row holding the dummy value counts
;     
;     Background:
;         The aim is to get an array such as:
;             0    1 . . |number in img_1|
;             0 a    b . .
;             1 c    d
;             . .    .
;             . .    .
;             _
;             number
;             in
;             img_2
;             _
;
;         a = number of times "0 in img_1" AND "0 in img_2"
;         b = number of times "1 in img_1" AND "0 in img_2"
;         c = number of times "0 in img_1" AND "1 in img_2"
;         d = number of times "1 in img_1" AND "1 in img_2"
;         . .
;         (considering always the same position)
;
;	:Uses:
;
; :Author:
;     Niklas Keck ("niklas_keck'use at instead'gmx.de").replace("'use at instead'","@")
;-
FUNCTION HIST_2D_NAN, img_1, img_2
    COMPILE_OPT idl2, HIDDEN
    
    IF N_ELEMENTS(img_1) EQ 0 THEN MESSAGE,"Please supply img_1"
    IF N_ELEMENTS(img_2) EQ 0 THEN MESSAGE,"Please supply img_2"

    ; Get the absolute min and max from both input images
    IF TOTAL(FINITE(img_1)) EQ 0 THEN BEGIN
        img_min = MIN(img_2,/NAN)
        img_max = MAX(img_2,/NAN)
    ENDIF ELSE BEGIN
        IF TOTAL(FINITE(img_2)) EQ 0 THEN BEGIN
            img_min = MIN(img_1,/NAN)
            img_max = MAX(img_1,/NAN)
        ENDIF ELSE BEGIN
            img_min= MIN(img_1,/NAN) LE MIN(img_2,/NAN) ? MIN(img_1,/NAN):MIN(img_2,/NAN)
            img_max= MAX(img_1,/NAN) GE MAX(img_2,/NAN) ? MAX(img_1,/NAN):MAX(img_2,/NAN)
        ENDELSE
    ENDELSE
        
    ; HIST_2D does not support NaN values:
    ; => find positions of non finite values in either input array and set those positions to max+1 
    non_finite = WHERE(~(FINITE(img_1) AND FINITE(img_2)))
    IF TOTAL(non_finite) EQ -1 THEN BEGIN
        ; if there are no NaN values DO:
        result = (HIST_2D(img_1,img_2,MAX1=img_max,MAX2=img_max,MIN1=img_min,MIN2=img_min))
    ENDIF ELSE BEGIN
        img_1[non_finite] = img_max + 1
        img_2[non_finite] = img_max + 1
        
        ; Do calculations with equal min and max values to ensure a quadratic matrix output
        result = HIST_2D(img_1, img_2, $
                          MAX1=img_max + 1,$
                          MAX2=img_max + 1,$
                          MIN1=img_min, MIN2=img_min)

        ; Remove the last row and column, which where used to store the NAN occurences.
        ; since quadratic matrix, the size of one side:
        n = SQRT(N_ELEMENTS(result))
        result = result[0:n-2,0:n-2]
    ENDELSE
    
    return,result

END