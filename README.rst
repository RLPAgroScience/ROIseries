====================
ROIseries
====================

Purpose
---------------
Statement of what it is supposed to do.

Structure
----------------
- **src**: Contains the ROIseries classes + routines they access.
	- **glcm_features**: Calculate the gray level co-occurrence matrix + features
	- **cookie_cutter**: Extract spatiotemporal image-objects from rasters.
	- **spectral_indexer**: Extract/mix raster bands removing the spectral dimension.
	- **spatial_mixer**: Apply a metric over an image-object removing the spatial dimensions.
	- **temporal_filter**: Apply a filter along the temporal dimension.
	- **temporal_blender**: Arithmetically combine different ROIseries objects.
	- **sub_routines**: Contains a collection of usefull routines.
- **tests**:: Contains tests.

Background
------------
Some infos about how it evolved/why.

Contributing
-------------
Describe how to contribute.

License
----------
GNU AFFERO GENERAL PUBLIC LICENSE Version 3, 19 November 2007 (cp. LICENSE)