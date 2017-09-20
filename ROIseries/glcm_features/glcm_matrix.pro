;+
;  GLCM_MATRIX: Calculate the Grey Level Co-occurrence Matrix (GLCM)
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
; Calculate the Grey Level Co-occurrence Matrix (GLCM)
;
; :Params:
;    img : in, required, type=dblarr
;        2D array over which the GLCM shall be calculated
;    dir : in, Required, type=strarr
;        Directions of GLCM calculation. Valid values:
;           '0' (east <-> west),
;           '45' (northeast <-> southwest),
;           '90' (north <-> south) or
;           '135' (northwest <-> southeast)
;
; :Returns:
;     GLCM
;     
; :Examples:
;     For example::
; 
;         IDL> img = [[0,0,1,1],[0,0,1,1],[0,2,2,2],[2,2,3,3]]
;         IDL> print, img
;             0       0       1       1
;             0       0       1       1
;             0       2       2       2
;             2       2       3       3 
;         IDL> dir = ['45','135'] 
;         IDL> result = GLCM_MATRIX(img, dir)
;         IDL> print, result['45']
;             0.222      0.055     0.000      0.000
;             0.055      0.111     0.111      0.000
;             0.000      0.111     0.222      0.055
;             0.000      0.000     0.055      0.000
;         
; :Description:
;     The GLCM is the basis for the textural features as described in:
;     "Haralick, Robert M., Shanmugam, K. & Dinstein, Its'hak 1973. Textural Features for Image Classification. IEEE Transactions on systems, man and cybernetics SMC-3(6), 610–621."
;     Conceptual implementation according to: http://www.fp.ucalgary.ca/mhallbey/the_glcm.htm
;     IDL implementation inspired by comment from 'alx' on https://groups.google.com/forum/#!msg/comp.lang.idl-pvwave/G-lr47A5kVs/HNHHBqJFfq4J
;     
;	:Uses:
;	    HIST_2D_NAN
;
; :Author:
;     Niklas Keck ("niklas_keck'use at instead'gmx.de").replace("'use at instead'","@"))
;-
FUNCTION GLCM_MATRIX,img,dir,NORMALIZE_RS_NEW_MIN_MAX=normalize_rs_new_min_max
    COMPILE_OPT idl2, HIDDEN
    
    img_in = img
    
    ; Input?
    IF N_ELEMENTS(img_in) EQ 0 THEN MESSAGE,"please provide input array"
    IF N_ELEMENTS(dir) EQ 0 THEN MESSAGE,"please provide input directions"
    IF N_ELEMENTS(NORMALIZE_RS_NEW_MIN_MAX) NE 0 THEN img_in = NORMALIZE_RS(img_in,normalize_rs_new_min_max)
    
    ; Ouput:
    res_list = LIST()
    
    ; Check the number of pixels in the two dimensions
    dim = SIZE(img_in,/DIMENSIONS)
    IF N_ELEMENTS(dim) EQ 1 THEN BEGIN
        cas = 1
    ENDIF ELSE BEGIN
        IF dim[0] GT 1 && dim[1] GT 1 THEN cas=2 ; the best case: image with more than one pixel in both directions
        IF dim[0] EQ 1 && dim[1] GT 1 THEN cas=3
        IF dim[0] GT 1 && dim[1] EQ 1 THEN cas=4
    ENDELSE
    
    ; Calculate GLCM in each direction
    ; -> Prevent calculations on one-column image (cas 1 OR 3)
    ; -> Shift image and cut of last row since that one does not have a neightbour
    ; -> generate 2D histogram, 
    ; -> make it symmetrical (add opposite directions)
    ; -> normalize it 
    FOREACH i,dir DO BEGIN
        CASE i OF
            
            ; east <-> west
            '0': BEGIN 
                IF cas EQ 1 || cas EQ 3 THEN BEGIN 
                    res_list.Add,!Values.D_NAN
                ENDIF ELSE BEGIN
                    img_s1 = (shift(img_in,[-1,0]))[0:-2,*]
                    img_c=img_in[0:-2,*]
                    h2d=HIST_2D_NAN(img_s1,img_c) + HIST_2D_NAN(img_c,img_s1) 
                    res_list.Add,(h2d / DOUBLE(TOTAL(h2d)))
                ENDELSE
            END
        
            ; north <-> south
            '90': BEGIN
                IF cas EQ 1 || cas EQ 4 THEN BEGIN
                    res_list.Add,!Values.D_NaN
                ENDIF ELSE BEGIN
                    img_s1 = (shift(img_in,[0,-1]))[*,0:-2]
                    img_c = img_in[*,0:-2]
                    h2d = hist_2D_NAN(img_s1,img_c) + hist_2D_NAN(img_c,img_s1)
                    res_list.Add,(h2d / DOUBLE(TOTAL(h2d)))
                ENDELSE 
            END
       
           ; northeast <-> southwest
           '45': BEGIN
               IF cas NE 2 THEN BEGIN   
                   res_list.Add,!Values.D_NaN
               ENDIF ELSE BEGIN
                   img_s1 = (shift(img_in,[1,-1]))[1:*,0:-2]
                   img_c = img_in[1:*,0:-2]
                   h2d = hist_2D_NAN(img_s1,img_c) + hist_2D_NAN(img_c,img_s1)
                   res_list.Add,(h2d / DOUBLE(TOTAL(h2d)))
               ENDELSE
           END
           
           ; northwest <-> southeast
           '135': BEGIN
               IF cas NE 2 THEN BEGIN
                 res_list.Add,!Values.D_NaN
               ENDIF ELSE BEGIN
                 img_s1 = (shift(img_in,[-1,-1]))[0:-2,0:-2]
                 img_c = img_in[0:-2,0:-2] ; bug corrected. Used to be: img_in[1:*,0:-2] 
                 h2d = hist_2D_NAN(img_s1,img_c) + hist_2D_NAN(img_c,img_s1)
                 res_list.Add,(h2d / DOUBLE(TOTAL(h2d)))
               ENDELSE
           END
        
        ENDCASE
    ENDFOREACH
    
    ; Return results
    IF N_ELEMENTS(dir) EQ 1 THEN BEGIN
        RETURN,res_list[0] 
    ENDIF ELSE BEGIN
        RETURN,HASH(dir,res_list)
    ENDELSE

END