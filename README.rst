====================
ROIseries
====================

Purpose
---------------
ROIseries helps to discover usefull features in multitemporal remote sensing data for machine learning applications.

Installation
---------------

Tutorials
---------------
Have a look at the docs/examples folder.

Structure
----------------
- **data**: Contains data used in the examples and for testing
- **docs**: Contains examples and other documentation
- **src**: Contains the ROIseries classes + routines they access.
	- **book_keeper**: Tabular input/ouput
	- **cookie_cutter**: Extract spatiotemporal image-objects from a series of rasters
	- **features_sommelier**: Cross-validation using machine learning to assess feature usefulness
	- **glcm_features**: Calculate the gray level co-occurrence matrix + features
	- **spatial_mixer**: Quantify the numeric distribution in the spatial dimension while removing it (ROIseries_3D->ROIseries_1D)
	- **spectral_indexer**: Extract or mix raster bands from a mulitspectral raster to remove the spectral dimension.
	- **temporal_blender**: Arithmetically combine different ROIseries objects.
	- **temporal_filter**: Apply filter along the temporal dimension.
	- **sub_routines**: Collection of usefull routines used throughout ROIseries.
	- **visual_tukey_**: Visualization of ROIseries_3D and ROIseries_1D objects.
- **tests**: Contains tests.

Background
------------
ROIseries is developed at RLP AgroScience GmbH (http://www.agroscience.de/) to serve the requirements of various projects in the field of land cover classification. It is applied for example in the NATFLO project (http://www.natflo.de/). It is also the topic of a master thesis written within the UNIGIS distance learning program (http://salzburg.unigis.net/).

Requirements
------------
ROIseries is mainly written in the Interactive Data Language (IDL) and requires an IDL development license. 
The machine learning feature cross validation is written in Python + additional Python packages.

Contributing
-------------
Everybody with any level of expertise in IDL and Python is most cordially welcome to contribute to the library with questions, constructive criticism and code contributions. For more information about how to contribute please read CONTRIBUTING.

License
----------
GNU AFFERO GENERAL PUBLIC LICENSE Version 3, 19 November 2007 (cp. LICENSE)
