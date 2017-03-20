====================
CONTRIBUTING
====================

Coding Conventions
---------------------
- Indentation: 4 spaces (Workbench/Window/Preferences/IDL/Editor/: "Displayed tab width: 4", "Insert spaces for tabs: Yes")
- Case: uppercase for everything except variables. Variables are all lowercase.
- Naming (variables, functions, procedures): 
    - name_additional_infos is prefered over NameAdditionalInfos (CamelCase)
	- the "name" however, can be CamelCase if it is either an established term or a name made up by the author. (e. g. GroundTruth_data)
	- Names containing abbreviations are dealt with as follows:
		- region of interest series => ROIseries not ROISeries
    - RS_*,RS3D_*,RS1D_* have to be used as prefix for routines that are specifically designed to be called by a certain method with the name *
	    - RS3D_plot e. g. is the routine called by ROIseries_3D :: plot()
	- *_RS has to be added to routines names of routines that are developed within ROIseries but are general purpose routines
	    UPDIR_RS is e. g. the name of a routine that is used by ROIseries but can easily be used in other programs as well.
    - an easy way to discern the two:
		RS*_* routines get get ROIseries_* objects as input (often 'self') whereas *_RS routines get standard IDL data