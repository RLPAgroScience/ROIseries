;+
;  RS3D_REFORM_FOR_PLOTS: Reform a 3D array to 2D for multiline plots: COLUMN and ROWS = DIM1, TIME = DIM2
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
; Reform a 3D array to 2D for multiline plots: COLUMN and ROWS = DIM1, TIME = DIM2
;
; :Params:
;    data
;
; :Keywords:
;    IDS
;
; :Returns:
;
; :Examples:
;
; :Description:
;
;	:Uses:
;
; :Author:
;     Niklas Keck ("niklas_keck'use at instead'gmx.de").replace("'use at instead'","@")
;-
FUNCTION RS3D_REFORM_FOR_PLOTS,data,IDS=ids

    IF N_ELEMENTS(ids) EQ 0 THEN ids = data.keys()
    plot_data=ORDEREDHASH()
    
    FOREACH id,ids DO BEGIN &$
        ; Get objects and reform it to two dimensions (COLUMN + ROWS = DIM1, TIME = DIM2)
        val=data[id] &$
        s=SIZE(val) &$
        valRe=REFORM(val,[(s[1]*s[2]),s[3]]) &$

        ; identify rows with at least one nan value and remove them
        valSumCol=TOTAL(valRe,2) &$
        Fini=WHERE(FINITE(valSumCol)) &$
        plot_data[id]=ValRe[Fini,*] &$
    ENDFOREACH

    RETURN,plot_data
END