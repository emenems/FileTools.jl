"""
	readdygraphs(filein)
Load data stored in Dygraphs file format to DataFrame

**Input**
* filein: full name of the input file
* datestring: string defining time format (default: "yyyy/mm/dd HH:MM:SS")

**Output**
* dataframe containing columns + timevector in DateTime format

**Example**
```
data = readdygraphs("../test/input/dygraphs_data.tsf";datestring="yyyymmdd");
```
"""
function readdygraphs(filein::String;datestring::String="yyyy/mm/dd HH:MM:SS")
	# Read header
	channels = Array{SubString{String},1}(0);
	open(filein,"r") do fid
		# Read channel names
		channels = fid |> readline |> x -> replace(x,r" |\r|\"","") |>
						x -> split(x,",") |> x -> x[2:end];
	end
	# read data
	dataall = readdlm(filein,',',skipstart=1,header=false);
	# Convert to DataFrame
	data = DataFrame(datetime=DateTime.(preptimevec.(dataall[:,1]),datestring));
	for (i,v) in enumerate(channels)
		data[Symbol(v)] = convert.(Float64,dataall[:,i+1]);
	end
	return data;
end

"""
	writedygraphs(datain,fileout;decimal)
Write DataFrame to Dygraphs csv format

**Input**
* datain: dataframe containing columns + timevector in DateTime format
* fileout: full name of the output file
* decimal: optional output precision for either all or individual columns. Maximum precision is %.10g!
> output date string is fixed: "yyyy/mm/dd HH:MM:SS"

**Example**
```
datain = DataFrame(temp=[10.,11.,12.,14.],grav=[9.8123,9.9,NaN,9.7],
       datetime=[DateTime(2010,1,1),DateTime(2010,1,2),
           DateTime(2010,1,3),DateTime(2010,1,4)]);
writedygraphs(datain,"../test/output/dygraphs_data.csv",decimal=[1,3]);
```
"""
function writedygraphs(datain::DataFrame,fileout::String;decimal=[4])
	channels,timei = FileTools.findchannels(datain);
	# Round data to output precision
	dataout = round2output(datain,decimal,channels);
	# Write header
	open(fileout,"w") do fid
		@printf(fid,"date");
		for (i,v) in enumerate(channels)
			@printf(fid,",%s",string(v));
		end
		@printf(fid,"\n");
		# Write data
		for i = 1:size(datain,1)
			# Write date + time (do not use Dates.format == very slow)
			@printf(fid,"%04i/%02i/%02i %02i:%02i:%02i",
						Dates.year(datain[timei][i]),
						Dates.month(datain[timei][i]),
						Dates.day(datain[timei][i]),
						Dates.hour(datain[timei][i]),
						Dates.minute(datain[timei][i]),
						Dates.second(datain[timei][i]));
			# add data
			flagval = "NaN";
			for j in channels
				if ismissing(dataout[j][i])
					@printf(fid,",%s",flagval);
				else
					@printf(fid,",%.10g",dataout[j][i]);
				end
			end
			@printf(fid,"\n");
		end
	end
end

"""
	preptimevec(timeval)
Auxilliary function to prepare time vector for DateTime conversion
"""
function preptimevec(timeval)
	if typeof(timeval) == Float64
		return timeval |> x -> round(Int,x) |> string
	elseif typeof(timeval) == Int
		return string(timeval)
	else
		return timeval;
	end
end
