FileTools
=========
This repository contains functions for reading/writing files in following formats:
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
* `writeggp`: write GGP/[IGETS](http://gfzpublic.gfz-potsdam.de/pubman/faces/viewItemOverviewPage.jsp?itemId=escidoc:1870888) files
* `ggpdata2blocks`: remove time spans of NaN and return blocks of data as needed for `writeggp` function
* `igetsimport`: load all files within given time interval downloaded from [IGETS](http://isdc.gfz-potsdam.de/igets-data-base/) database
* `igetsexport`: export files within given time interval to  [IGETS](http://isdc.gfz-potsdam.de/igets-data-base/) format
* `readgpcpd*`: read [GPCP](https://precip.gsfc.nasa.gov/gpcp_daily_comb.html) _daily_ binary files
* `writeatmosph`: write atmospheric data to [Hydrus1D](https://www.pc-progress.com/en/Default.aspx?H1D-description#k1) format (water flux only)
* `writeprofile1d`: write vertical profile data in [Hydrus1D](https://www.pc-progress.com/en/Default.aspx?H1D-description#k1) format (water flux mode only)
* `readhydrus1d_obsnode`: read [Hydrus1D](https://www.pc-progress.com/en/Default.aspx?H1D-description#k1) observation nodes output (water flux mode only)
* `readhydrus1d_nodinf`: read [Hydrus1D](https://www.pc-progress.com/en/Default.aspx?H1D-description#k1) all nodes output (water flux mode only)
* `readatmosph`: read [Hydrus1D](https://www.pc-progress.com/en/Default.aspx?H1D-description#k1) atmospheric forcing data
* `writebaytap`: write data to [Baytap08](https://igppweb.ucsd.edu/~agnew/Baytap/baytap.html) data format
* `baytap2tsoft`: convert [Baytap08](https://igppweb.ucsd.edu/~agnew/Baytap/baytap.html) results to format used in TSoft for tidal wave grouping
* `vav2tsoft`: convert [VAV](https://www.sciencedirect.com/science/article/pii/S0098300403000190) results to format used in TSoft for tidal wave grouping
* `eterna2tsoft`: convert [ETERNA34](http://igets.u-strasbg.fr/soft_and_tool.php) results to format used in TSoft for tidal wave grouping
* `dwdclimateraw`: read raw monthly global climate date provided by [DWD](ftp://ftp-cdc.dwd.de/pub/CDC/observations_global/CLIMAT/monthly/raw/)

In addition, following functions are exported:
* `stackframes`: stack (vertical concatenate) two DataFrame with optional overlapping or gap between DataFrames (time)
* `coorShift_lon`: transform longitude coordinate system between _-180 to 180_ <--> _0 to 360_
* `read_layerResponse`: read formatted output of the [GravityEffect](https://github.com/emenems/GravityEffect.jl)/`layerResponse` function

### Usage
* Check the function help for instructions and example usage

### Dependency
* Check the `REQUIRE` file for required packages
