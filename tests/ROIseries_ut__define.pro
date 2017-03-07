;+
;  ROIseries_ut: Unit Testing of ROIseries using mgunit
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
FUNCTION ROIseries_ut :: TEST_DETER_MINSIZE
    COMPILE_OPT idl2, HIDDEN
    
    ; Unsigned integers
    ASSERT,DETER_MINSIZE(ULONG(255),/NAME) EQ 'BYTE','ULONG(255) not converted to BYTE by deter_minsize'
    ASSERT,DETER_MINSIZE(ULONG64(4294967295),/NAME) EQ 'ULONG','LONG64(4294967295) not converted to ULONG by deter_minsize'
    
    ; Signed integers 
    ASSERT,DETER_MINSIZE(LONG64(-32768),/NAME) EQ 'INT','LONG(-32768) not converted to INT by deter_minsize'
    ASSERT,DETER_MINSIZE(LONG64(-2147483648),/NAME) EQ 'LONG','LONG64(21474836647) not converted to LONG by deter_minsize'
    
    ; Floating points
    ASSERT,DETER_MINSIZE(DOUBLE(1.0),/NAME) EQ 'FLOAT','DOUBLE(1.0) not converted to FLOAT by deter_minsize'
    ASSERT,DETER_MINSIZE(DOUBLE(-10.0)^200,/NAME) EQ 'DOUBLE','DOUBLE(-10.0)^200 not kept as FLOAT by deter_minsize'
    
    ; Changing Groups
    ASSERT,DETER_MINSIZE(DOUBLE(42.0),/NAME,/CHANGE_GROUP) EQ 'BYTE','DOUBLE(-42.0) was not converted to BYTE by deter_minsize, even though /CHANGE_GROUP was set'
    RETURN,1
END

PRO ROIseries_ut__define
  COMPILE_OPT idl2, HIDDEN
  define = { ROIseries_ut, INHERITS MGutTestCase }
END