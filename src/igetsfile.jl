"""
	igetsimport(path_input,name_input,ext_input,load_interval)
Import data in ggp/eterna format downloaded from IGETS database

**Input**
* path_input: input path, e.g. "f:/data/igets/ba009/Level1"
* name_input: file prefix, e.g. "IGETS-SG-MIN-ba009-"
* ext_input: file extension, e.g. "00.ggp"
* load_interval: time interval to be loaded, e.g. DateTime(2000,1,1):Dates.Month(1):DateTime(2001,2,1)
* nanval: flag used for NaNs (NaN will be returned)

**Output**
dataframe containing whole loaded time interval

**Example**
Go to [IGETS](http://isdc.gfz-potsdam.de/igets-data-base/) database and download
the whole folder with data, e.g. all years from /cantley/ba009/Level1
```
# set the folder on your local machine with the data (without year)
path_input = "f:/mikolaj/data/sites/cantley/grav/sg/ca012/igets/Level1"
# set the file prefix
name_input = "IGETS-SG-MIN-ca012-"# without "YYYYMMXX.ggp" extension
# file extension
ext_input = "00.ggp"; # 00 is the file code
# Time interval to be loaded
load_interval = DateTime(2011,1,1):Dates.Month(1):DateTime(2012,2,1);
dataloaded = igetsimport(path_input,name_input,ext_input,
				load_interval,nanval=99.000000)
```
"""
function igetsimport(path_input::String,name_input::String,ext_input::String,
					load_interval;nanval::Float64=9999.999)
	dataout = DataFrame();
	for i in load_interval
		file_load = joinpath(path_input,Dates.format(i,"yyyy"),
							name_input*Dates.format(i,"yyyymm")*ext_input)
		if isfile(file_load)
			temp = readggp(file_load,nanval=nanval);
			dataout = vcat(dataout,temp);
		end
	end
	return dataout
end
