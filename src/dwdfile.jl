"""
	dwdclimateraw(datein,siteid;url)
Read DWD CDC global monthly raw observations

**Input**
* datein: input date in DateTime format (can be a vector for multiple sites)
* siteid: WMO site ID, e.g. 87593 for La Plata, Argentina (one ID only)
* param: parameter to be extracted (one only), e.g. "Rx" (ftp://ftp-cdc.dwd.de/pub/CDC/observations_global/CLIMAT/monthly/raw/readme_RAW_CLIMATs_eng.txt)
* url: URL od local folder link
* downto: download temporary data to this folder (file will be deleted afterwards)

**Ouptut**
See ftp://ftp-cdc.dwd.de/pub/CDC/observations_global/CLIMAT/monthly/raw/readme_RAW_CLIMATs_eng.txt

**Example**
dwd = dwdclimateraw(DateTime(2017,10),87593,"Rx");
# Vector input
timein = collect(DateTime(2017,10):Dates.Month(1):DateTime(2017,12));
dwdvec = dwdclimateraw(timein,87593,"Rx");
"""
function dwdclimateraw(datein,siteid::Int,param::String;
	url::String="ftp://ftp-cdc.dwd.de/pub/CDC/observations_global/CLIMAT/monthly/raw/",
	downto::String="")::DataFrame
	dfo = DataFrame(datetime=datein,paramout=Dates.value.(datein).*0);
	for (i,v) in enumerate(typeof(datein)==DateTime ? [datein] : datein)
		filein = joinpath(url,@sprintf("CLIMAT_RAW_%s.txt",Dates.format(v,"yyyymm")));
		if isdir(url)
			fileout = filein;
		else
			fileout = isdir(downto) ? joinpath(downto,"dwd_month_raw_TEMP.txt") : "dwd_month_raw_TEMP.txt"
			download(filein,fileout);
		end
		d,h = readdlm(fileout,';',header=true)
		r,c = dwdclimateraw_indices(d,h,param,siteid);
		dfo[:paramout][i] = eltype(d[r,c])==Int ? d[r,c] : NA;
		!isdir(url) ? rm(fileout) : nothing
	end
	return rename!(dfo,:paramout=>Symbol(param));
end

"""
Auxiliary function to find indices of the site and parameter
"""
function dwdclimateraw_indices(datain::Array{Any,2},headerin::Array{AbstractString,2},
								paramin::String,sitein::Int)::Tuple{Int,Int}
	r,c = 1,1;
	for i in headerin
		i == paramin ? break : c += 1
	end
	for i in datain[:,3]
		i == sitein ? break : r += 1
	end
	return r,c
end

"""
    readgssd(file_in)
Read global surface summary of day data
See https://www1.ncdc.noaa.gov/pub/data/gsod/readme.txt

**Input**
* `file_in`: input file name (full)

**Output**
* DataFrame containin all columns of the input file

**Example**
```
file_in = joinpath(dirname(@__DIR__),"test","input","nndc_climate_cdo.txt");
df = readgssd(file_in);
```
"""
function readgssd(file_in)::DataFrame
    # see https://www1.ncdc.noaa.gov/pub/data/gsod/readme.txt
    par = [:STN,:WBAN,:YEARMODA,:TEMP,:Count_TEMP,:DEWP,:Count_DEWP,:SLP,:Count_SLP,:STP,
        :Count_STP,:VISIB,:Count_VISIB,:WDSP,:Count_WDSP,:MXSPD,:GUST,:MAX,:Flag_MAX,:MIN,
        :Flag_MIN,:PRCP,:Flag_PRCP,:SNDP,:FRSHTT]
    i1 = [1,8,15,25,32,36,43,47,54,58,65,69,75,79,85,89,96,103,109,111,
            117,119,124,126,133];
    i2 = [6,12,22,30,33,41,44,52,55,63,66,73,76,83,86,93,100,108,109,116,
            117,123,124,130,138];
    typei = [Int,Int,Int,Float64,Int,Float64,Int,Float64,Int,Float64,
                Int,Float64,Int,Float64,Int,Float64,Float64,Float64,String,
                Float64,String,Float64,String,Float64,Int];
    function parse_col(s::String,i1,i2,typei)::Vector{Any}
        out_vec = Vector{Any}(undef,0);
        for i in 1:length(i1)
            push!(out_vec,
                typei[i]!=String ? Base.parse(typei[i],s[i1[i]:i2[i]]) : s[i1[i]:i2[i]])
        end
        return out_vec
    end

    data_out = DataFrame([Vector{x}(undef,0) for x in typei],par);
    open(file_in,"r") do fid
        headtxt = readline(fid);
        while !eof(fid)
            push!(data_out,parse_col(readline(fid),i1,i2,typei));
        end
    end
    return data_out;
end

"""
    convertgssd(df)
Convert global surface summary of day data to SI units and set flags to NaN

**Input**
* `df`: readgssd output

**Output**
* dataframe with converted units and only essential columns (for me :-)
* temperature in degrees C, windspeed in m/s, pressure in hPa, precipitation in mm

**Example**
```
file_in = joinpath(dirname(@__DIR__),"test","input","nndc_climate_cdo.txt");
df = readgssd(file_in) |> convertgssd
```
"""
function convertgssd(df::DataFrame)::DataFrame
    data_out = DataFrame(datetime=FileTools.pattern2time.(df[:YEARMODA],"day"));
    d = copy(df);
    # flag => NaN;
    flags = [9999.9,9999.9,9999.9,9999.9,999.9,999.9,99.99,9999.9];
    for (i,v) in enumerate([:TEMP,:DEWP,:MAX,:MIN,:WDSP,:MXSPD,:PRCP,:STP])
        d[v][d[v].==flags[i]] .= NaN;
    end
    # temperature
    for i in [:TEMP,:DEWP,:MAX,:MIN]
        data_out[i] = (d[i].-32).*5/9;
    end
    # wind speed
    for i in [:WDSP,:MXSPD]
        data_out[i] = d[i]./10.0.*0.514444444;
    end
    # precipitation (mm)
    data_out[:PRCP] = d[:PRCP].*25.4
    data_out[:STP] = d[:STP];
    return data_out;
end
