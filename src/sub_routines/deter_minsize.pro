;+
;  DETER_MINSIZE: Determine and use the smallest numeric datatype able to store a given value
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
; Determine and use the smallest numeric datatype able to store a given value
;
; :Params:
;    x
;
; :Keywords:
;     NAME:
;     CHANGE_GROUP:
;
; :Returns:
;     if KEYWORD_SET(NAME): String with datatype, ELSE: conversion of input to datatype
;     if KEWWORD_SET(CHANGE_GROUP): Smallest datatype accross groups, ELSE: Smallest datatype within groups.
;
; :Examples:
;     >> typename(DETER_MINSIZE(42ULL))
;     >> typename(DETER_MINSIZE(-42LL))
;     >> typename(DETER_MINSIZE(42LL))
;     >> typename(DETER_MINSIZE(42LL,/CHANGE_GROUP))
;
; :Description:
;     Determine the smallest numeric datatype able to store a given value.
;     Either:
;         - Convert and return the input value to this datatype.
;         - Return the name of the smalles datatype (/NAME)
;
;	:Uses:
;     SET_TYPE
;
; :Author:
;     Niklas Keck ("niklas_keck'use at instead'gmx.de").replace("'use at instead'","@")
;-
FUNCTION DETER_MINSIZE,x,NAME=name,CHANGE_GROUP=change_group
    COMPILE_OPT idl2, HIDDEN
    
    tnx=TYPENAME(x)
    unsigned_integers = ['BYTE','UINT','ULONG','ULONG64']
    signed_integers = ['INT','LONG','LONG64']
    floating_points = ['FLOAT','DOUBLE']
    all_types = ['BYTE','UINT','INT','ULONG','LONG','FLOAT','ULONG64','LONG64','DOUBLE']
    
    IF unsigned_integers.HasValue(tnx) THEN cas = unsigned_integers
    IF signed_integers.HasValue(tnx) THEN cas = signed_integers
    IF floating_points.HasValue(tnx) THEN cas = floating_points
    IF KEYWORD_SET(CHANGE_GROUP) THEN cas = all_types
    
    FOREACH t,cas DO BEGIN
        IF SET_TYPE(x,t) EQ x THEN BEGIN
            IF KEYWORD_SET(NAME) THEN BEGIN
                RETURN,t
            ENDIF ELSE BEGIN
                RETURN,SET_TYPE(x,t)
            ENDELSE
        ENDIF
    ENDFOREACH  
END