"""
	readgpcpd(filein)
Read DAILY GPCP data

**Input**
* filein: daily (GPCP)[https://precip.gsfc.nasa.gov/gpcp_daily_comb.html] binary file

**Output**
* Array{Float63}(lon,lat,time) with unchanged units (mm/day). All negative values (flag=-99999) are set to NaN

**Example**
```
# Load data for whole month and select last day of the month
# should result in approx.: https://climatedataguide.ucar.edu/climate-data/gpcp-daily-global-precipitation-climatology-project
filein = "/test/input/gpcpd_data";
datagpcp = readgpcpd(filein);
data_june30 = datagpcp(:,:,end);
timegpcp = readgpcpd_time(filein);
lon,lat = readgpcpd_lonlat(filein);
head_string = readgpcpd_head(filein);
```
"""
function readgpcpd(filein::String)
	# get header info
	headout = readgpcpd_head(filein);
	lon,lat = readgpcpd_lonlat(headout);
	timeout = readgpcpd_time(headout);
	# declare output
	dataout = Array{Float64}(length(lon)*length(lat)*length(timeout));
	open(filein,"r") do fid
		# remove header lines
		seek(fid,length(headout)-3);
		# read data
		dataout = read(fid,Float32,length(lon)*length(lat)*length(timeout)) |>
						x -> convert(Vector{Float64},x);
	end
	#dataout[dataout.<0.] == NaN;
	return reshape(dataout,length(lon),length(lat),length(timeout))
end

"""
	readgpcpd_head(filein;headersize)
Read DAILY GPCP header line

**Input**
* filein: daily (GPCP)[https://precip.gsfc.nasa.gov/gpcp_daily_comb.html] binary file
* optional header size (1440 for daily data)

**Output**
* whole header string

**Example**
```
filein = "/test/input/gpcpd_data";
head_string = readgpcpd_head(filein);
```
"""
function readgpcpd_head(filein::String;headsize::Int=1440)
	headout = ' ';
	open(filein,"r") do fid
		for i in 1:headsize
			headout = string(headout,read(fid,Char)); # concatenate characters
		end
	end
	return headout[2:end] # first value = ' '
end

"""
	readgpcpd_lonlat(filein)
Read DAILY GPCP longitude and latitude

**Input**
* filein: daily (GPCP)[https://precip.gsfc.nasa.gov/gpcp_daily_comb.html] binary file

**Output**
* longitude (degree east), latitude (degree north to east)

**Example**
```
filein = "/test/input/gpcpd_data";
lon,lat = readgpcpd_lonlat(filein);
```
"""
function readgpcpd_lonlat(headout::String)
	if isfile(headout)
		headout = readgpcpd_head(headout);
	end
	string_size = match(r"[0-9]{3}x[0-9]{3}",headout);
	x,y = split(string_size.match,"x") |> x -> (Base.parse(x[1]),Base.parse(x[2]))
	return collect(0.5:1:(x-0.5)),collect(89.5:-1:(-y/2+0.5))
end

"""
	readgpcpd_time(filein)
Read DAILY GPCP time information

**Input**
* filein: daily (GPCP)[https://precip.gsfc.nasa.gov/gpcp_daily_comb.html] binary file

**Output**
* time vector in DateTime format

**Example**
```
filein = "/test/input/gpcpd_data";
timegpcp = readgpcpd_time(filein);
```
"""
function readgpcpd_time(headout::String)
	if isfile(headout)
		headout = readgpcpd_head(headout);
	end
	string_yyyy = match(r"year=[0-9]{4}",headout);
	string_mm = match(r"month=[0-9]{2}",headout);
	string_dd = match(r"days=.-[0-9]{2}",headout) |> x->split(x.match,"=") |> x->x[2]
	time_start = DateTime(Base.parse(split(string_yyyy.match,"=")[2]),
						Base.parse(split(string_mm.match,"=")[2]),
						Base.parse(split(string_dd,"-")[1]));
	time_stop = DateTime(Base.parse(split(string_yyyy.match,"=")[2]),
						Base.parse(split(string_mm.match,"=")[2]),
						Base.parse(split(string_dd,"-")[2]));
	return collect(time_start:Dates.Day(1):time_stop)
end

"""
	coorShift_lon(lon,datain,to)
Convert 0 to 360 longitude coordinate (e.g. GPCP) system to -180 to 180

**Input**
* lon: longitude vector
* datain: data matrix or 3D Array{T}. If 3D matrix => first 2 dimensions are lon*lat or lat*lon
* to: switch between systems (will be converted to this system): "-180to180" | "0to360"

**Output**
* lonout: new longitude vector
* dataout: transformed data in the same dimensions as input 'datain'

**Example**
```
# convert to 0-360 system
lon = collect(-179.5:1:179.5);
datain = repmat(-179.5:1:179.5,1,180);
lonout,dataout = coorShift_lon(lon,datain,to="0to360")

# convert to -180 to 180 system
lon = collect(0.125:0.25:359.875);
datain = Array{Float64}(720,length(lon),2);
datain[:,:,1] = transpose(repmat(0.125:0.25:359.875,1,720));
datain[:,:,2] = transpose(repmat(0.125:0.25:359.875,1,720));
lonout,dataout = coorShift_lon(lon,datain,to="-180to180");
```
"""
function coorShift_lon(lon,datain;to::String="-180to180")
	lonin = copy(lon);
	# prepare output longitude
	if to == "-180to180"
		lonout = sort(lon-180);
		lonin[lon.>180] = lon[lon.>180]-360.;
	elseif to == "0to360"
		lonout = sort(lon+180);
		lonin[lon.<0] = lon[lon.<0]+360.;
	end
	# find indices
	i_lon = zeros(Int,length(lon))
	for (i,v) in enumerate(lonout)
		i_lon[i] = findall(v.==lonin)[1];
	end
	# Get the correct dimension and transform the data
	if size(datain,1) == length(lon)
		if size(datain,3) == 1
			return lonout,datain[i_lon,:];
		else
			return lonout,datain[i_lon,:,:];
		end
	else
		if size(datain,3) == 1
			return lonout,datain[:,i_lon];
		else
			return lonout,datain[:,i_lon,:];
		end
	end
end
