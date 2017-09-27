"""
	loadatmacs(locfile,globfile)
(Download &) read Atmcas local and global data

**Input**
* glofiles: vector of either URLs or files (name) with global Atmacs effect.
	If locfile is empty, then global model covering whole Earth is assumed to
	be used thus including local part + pressure). All files will be stacked
	into one output for global DataFrame.
* locfiles: vector of either URLs or files (name) with local Atmacs effect
	(+ pressure)

**Output**
* globaal atmacs, local atmacs DataFrames with DateTime, and all columns of
  input files

**Example**
```
# Download data automatically
lurl = ["http://atmacs.bkg.bund.de/data/results/iconeu/we_iconeu_70km.grav"];
gurl = ["http://atmacs.bkg.bund.de/data/results/icon/we_icon384_20deg.grav"];
glo,loc = loadatmacs(locfiles=lurl,glofiles=gurl);
# Or read data from already downloaded files
glo,loc = loadatmacs(glofiles=["/test/input/atmacs_glo.grav"],
					locfiles=["/test/input/atmacs_loc.grav"]);
# Or stack global files covering global+local part (`loc` will be empty)
glo,loc = loadatmacs(glofiles=["/test/input/atmacs_all_1.grav",
								"/test/input/atmacs_all_2.grav"]);
```
"""
function loadatmacs(;glofiles::Vector{String}=[""],locfiles::Vector{String}=[""])
	# Constant output channel names: http://atmacs.bkg.bund.de/data/read_me
	# Assumption: Global file contains local part only if local file not loaded
	atmacs_loc = DataFrame();
	atmacs_glo = DataFrame();
	if isempty(locfiles[1])
		channelsGlo = [:pressure,:local_newton,:global_newton,:total_loading];
	else
		channelsGlo = [:global_newton,:total_loading];
		channelsLoc = [:pressure,:local_newton,:regional_newton];
		atmacs_loc = loadatmacsparts(locfiles,channelsLoc);
	end
	atmacs_glo = loadatmacsparts(glofiles,channelsGlo);
	return atmacs_glo,atmacs_loc;
end

"""
Auxiliary function for loading either global or local part of Atmacs
"""
function loadatmacsparts(files::Vector{String},channels::Vector{Symbol})
	atmacs = DataFrame();
	for i in files
		downto = FileTools.downfile(i);
		if !isempty(downto)
			dataall = readdlm(downto)
			temp = DataFrame(datetime=pattern2time.(dataall[:,1],"hour"));
			for j in 1:length(channels)
				temp[channels[j]] = dataall[:,j+1];
			end
			# delete downloaded file
			FileTools.delfile(i);
			# Stack data
			atmacs = stackframes(atmacs,temp);
		end
	end
	return atmacs;
end

"""
	stackframes(frameall,frameapp;maxtime,maxval)
Stack dataframas assuming identical number of columns but with unknown
overlapping or gap between DataFrame datetime vectors

**Input**
* frameall: main DataFrame that should be extended (must contain datetime column)
* frameapp: DataFrame to be appended at the end of `frameall`
* maxtime: maximum time difference allowed for stacking (if > than not stacked)
* corroffset: correct offset between individual columns of input DataFrame (see `maxval`)
* maxval: maximum allowed offset between values in columns for stacking (if > || `corroffset=false` than not stacked)
> can be either one absolute value (Float64) applied to all columns or vector with same number
of columns (-datetime) as input DataFrames. Will be only applied if overlapping
exists. Set to NaN for stacking without offset check.

**Output**
* stacked DataFrame with identical number of columns as `frameall`

**Example**
```
f1 = DataFrame(datetime=[DateTime(2010,1,1,0),DateTime(2010,1,1,1),
           DateTime(2010,1,1,2),DateTime(2010,1,1,3)],
		   grav=@data([10.,11.,12.,13.]));
f2 = DataFrame(datetime=[DateTime(2010,1,1,2),DateTime(2010,1,1,3),
           DateTime(2010,1,1,4),DateTime(2010,1,1,5)],
		   grav=@data([22.,23.,24.,25.]));
fall = stackframes(f1,f2,maxtime=Dates.Hour(1),maxval=NaN,corroffset=true);
# Following call will not be stacked as maximum offset is exceeded
fnot = stackframes(f1,f2,maxval=1.0)
```
"""
function stackframes(frameall::DataFrame,frameapp::DataFrame;
						maxtime=Dates.Year(9999),maxval=NaN,corroffset::Bool=true)
	# return current file if the total file is still empty (first run)
	if isempty(frameall)
		return frameapp;
	else
		# Check date (for overlapping or missing data)
    	r = find(frameall[:datetime][end] .== frameapp[:datetime]);
	    if isempty(r) # No such time exist (no overlapping) => check how big is the gap
			# get temporal resolution (res) and gap between files (diff)
        	time_diff = frameapp[:datetime][1] - frameall[:datetime][end];
        	time_res = frameall[:datetime][end] - frameall[:datetime][end-1];
			# If time step is < then `maxtime` insert NaN (for further interpolation)
			if time_diff <= maxtime
				temp = DataFrame(datetime = frameall[:datetime][end]+time_res)
				for i in names(frameapp)
					if i != :datetime
						temp[i] = NaN;
					end
				end
	        	return vcat(frameall,temp,frameapp);
			else
				return frameall;
			end
    	else # Overlapping exists
			# First, prepare temporary variable with `frameapp` values
			temp = DataFrame(datetime = frameapp[:datetime][r[1]+1:end])
			stackornot = true;
			# Prepare maximum allowed offset: convert to vector
			if typeof(maxval) == Float64
				maxoffset = zeros(size(frameall,2)-1) .+ maxval;
			end
			# and set to infinity if NaN on input
			maxoffset[isnan.(maxoffset)] = Inf;
			# Apply offset (if set so)
			for (j,i) in enumerate(names(frameapp))
				if i != :datetime
					offset = frameall[i][end] - frameapp[i][r[1]];
					if abs(offset) > maxoffset[j-1]
						stackornot = false;
					elseif corroffset
						temp[i] = frameapp[i][r[1]+1:end] .+ offset;
					else
						temp[i] = frameapp[i][r[1]+1:end];
					end
				end
			end
			if stackornot
				return vcat(frameall,temp);
			else
				return frameall;
			end
		end
    end
end

"""
Auxiliary Function to convert time pattern (e.g., yyyymmdd) to datetime value
"""
function pattern2time(time::Float64,resolution::String)
	# Declare output
	year,month,day,hour,minute,second = (0,0,0,0,0,0)
	if resolution == "day"
		year = floor(Int,time/1e+2);
		month = floor(Int,time-year*1e+2);
		day = 1;
	elseif resolution == "month"
	    year = floor(Int,time/1e+4);
	    month= floor(Int,(time - year*1e+4)/1e+2);
	    day  = floor(Int,(time - year*1e+4 - month*1e+2));
	elseif resolution == "hour"
	    year = floor(Int,time/1e+6);
	    month= floor(Int,(time - year*1e+6)/1e+4);
	    day  = floor(Int,(time - year*1e+6 - month*1e+4)/1e+2);
	    hour = floor(Int,(time - year*1e+6 - month*1e+4 - day*1e+2));
	elseif resolution == "minute"
	    year = floor(Int,time/1e+8);
	    month= floor(Int,(time - year*1e+8)/1e+6);
	    day  = floor(Int,(time - year*1e+8 - month*1e+6)/1e+4);
	    hour = floor(Int,(time - year*1e+8 - month*1e+6 - day*1e+4)/1e+2);
	    minute=floor(Int,(time - year*1e+8 - month*1e+6 - day*1e+4 - hour*1e+2));
	elseif resolution == "second"
	    year = floor(Int,time/1e+10);
	    month= floor(Int,(time - year*1e+10)/1e+8);
	    day  = floor(Int,(time - year*1e+10 - month*1e+8)/1e+6);
	    hour = floor(Int,(time - year*1e+10 - month*1e+8 - day*1e+6)/1e+4);
	    minute=floor(Int,(time - year*1e+10 - month*1e+8 - day*1e+6 - hour*1e+4)/1e+2);
	    second=round(Int,time - year*1e+10 - month*1e+8 - day*1e+6 - hour*1e+4 - minute*1e+2);
	end
	return DateTime(year,month,day,hour,minute,second);
end
