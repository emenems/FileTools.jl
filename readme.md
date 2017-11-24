FileTools
=========
This repository contains functions for reading files in following formats:
* `readtsf.jl`: read data in [TSoft](http://seismologie.oma.be/en/downloads/tsoft) format
* `writetsf.jl`: write DataFrame to TSoft format
* `loadascii.jl`: read data in [ESRI](https://en.wikipedia.org/wiki/Esri_grid) arc ascii format
* `writeascii.jl`: write data/grid to ESRI arc ascii format
* `readcampbell`: read data in Campbell Scientific logger format
* `readdygraphs`: read data in [Dygraphs](http://dygraphs.com/tutorial.html) csv format
* `writedygraphs`: write DataFrame to [Dygraphs](http://dygraphs.com/tutorial.html) csv format
* `loadeop`: (down)load EOP [C04](http://hpiers.obspm.fr/iers/eop/eopc04/eopc04_IAU2000.62-now) parameters
* `loadatmacs`: (down)load [Atmacs](/http://atmacs.bkg.bund.de) atmospheric model files
* `readggp`: read GGP/[IGETS](http://gfzpublic.gfz-potsdam.de/pubman/faces/viewItemOverviewPage.jsp?itemId=escidoc:1870888) files
* `readgpcpd*`: read [GPCP](https://precip.gsfc.nasa.gov/gpcp_daily_comb.html) _daily_ binary files

In addition, following functions are exported:
* `stackframes`: stack (vertical concatenate) two DataFrame with optional overlapping or gap between DataFrames (time)
* `coorShift_lon`: transform longitude coordinate system between _-180 to 180_ <--> _0 to 360_

## Usage
* Check the function help for instructions and example usage

## Dependency
* Check the `REQUIRE` file for required packages
