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

"""
	igetsexport(datain,path_out,name_out,ext_out,exp_interval;
				units,decimal,channels,header,file_format,blockinfo,flagval)
Export data to IGETS format

**Input**
* datain: output DataFrame
* path_out: output path, e.g. "f:/data/igets/ba009/Level1"
* name_out: file prefix, e.g. "IGETS-SG-MIN-ba009-"
* ext_out: file extension, e.g. "00.ggp"
* exp_interval: time interval to be exported, e.g. DateTime(2000,1,1):Dates.Month(1):DateTime(2001,3,1)
* See `?writeggp` for the file settings

**Example**
```
timegrav = collect(DateTime(2016,1,1):Dates.Hour(1):DateTime(2016,3,31,23));
datain = DataFrame(datetime=timegrav,
					grav=rand(Float64,length(timegrav)),
					pres=rand(Float64,length(timegrav)));
path_out = "f:/mikolaj/data/sites/djougon/grav/sg/dj060/igets/Level2";
name_out = "TEST-IGETS-SG-CORMIN-dj060-"
ext_out = "00.ggp";
# Set time with one month longer than the 'timegrav' variable (to include also last month)
exp_interval = DateTime(DateTime(2016,1,1)):Dates.Month(1):DateTime(DateTime(2016,4,1));
unitsout = Dict(:grav=>"V",:pres=>"hPa")
channelsout = [:grav,:pres];
headerout = Dict("Station"=>"Djougon",
              "Instrument"=>"dj060");
igetsexport(datain,path_out,name_out,ext_out,exp_interval,
			units=unitsout,decimal=[2,2],channels=channelsout,
			header=headerout,file_format="preterna",
			flagval="9999.999");
```
"""
function igetsexport(datain::DataFrame,path_out::String,
					name_out::String,ext_out::String,
					exp_interval;
					units=[],decimal=[2],channels=[],header=[],
					file_format="preterna",flagval="9999.999")::Void
	for i in 1:length(exp_interval)-1
		path_yyyy = joinpath(path_out,Dates.format(exp_interval[i],"yyyy"))
		file_out = name_out*Dates.format(exp_interval[i],"yyyymm")*ext_out;
		r = find(x->x<exp_interval[i] || x>=exp_interval[i+1],datain[:datetime])
		dataout = deepcopy(datain);
		!isempty(r) ? deleterows!(dataout,r) : nothing
		if !isempty(dataout)
			!isdir(path_yyyy) ? mkdir(path_yyyy) : nothing
			writeggp(dataout,joinpath(path_yyyy,file_out),units=units,header=header,decimal=decimal,
					channels=channels,flagval=flagval);
		end
	end
end
