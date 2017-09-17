"""
	loadtsf(filein)
Load tsf file and store it in DataFrame

**Input**
* filein: full name of the input file

**Output**
* dataframe containing columns + timevector in DateTime format
* data units

**Example**
```
data,units = loadtsf("../test/input/tsf_data.tsf");
```
"""
function loadtsf(filein::String)
	# Set default/intial values
	undetval = 9999.999;
	countinfo::Int64 = 0; # count data lines
	count_header::Int64 = 0;
	channels = Vector{String}(0);
	units = Vector{String}(0);

	# Set aux Function for channel and unit line extraction
	function extract_channels(fid::IOStream,row::String,out::Vector{String})
		row = readline(fid);count_header += 1;
		while !contains(row,"[")
			if length(row) > 0
				push!(out,row);
			end
			row = readline(fid);count_header += 1;
			if eof(fid)
				row = "[";# =>will stop while loop
			end
		end
		return out,row
	end

	# Open and read the file
	open(filein) do fid
		row = readline(fid);count_header += 1;
	    while !eof(fid)
			# Get important header info
			if contains(row,"[UNDETVAL]")
	            undetval = parse(Float64,row[11:end]);
				row = readline(fid);count_header += 1;
			elseif contains(row,"[COUNTINFO]")
				countinfo = parse(Int,row[12:end]);
				row = readline(fid);count_header += 1;
			elseif contains(row,"[CHANNELS]")
				# Now get channel names
				channels,row = extract_channels(fid,row,channels);
			elseif contains(row,"[UNITS]")
				# Now get channel units
				units,row = extract_channels(fid,row,units);
			elseif contains(row,"[DATA]")
				# do not read using readline function (low performance)
				break;
			else
				row = readline(fid);count_header += 1;
			end
	    end
	end # close reading line by line
	# Correct/get channel names and units
	channels = correct_channels(channels,":");
	units = correct_channels(units,":");
	# Read all data (will be sorted afterwards)
	dataall = readdlm(filein,skipstart=count_header,header=false);
	# Convert time to datetime
	data = DataFrame(datetime=mat2time(dataall[:,1:6]))
	# Fill columns
	for i = 7:size(dataall,2)
		channame = i-6 <= length(channels) ? channels[i-6] : "measurement"*string(i-6)
		data[Symbol(channame)] = dataall[:,i];
		# Remove Undetval
		data[Symbol(channame)][find(x->x==undetval,data[Symbol(channame)])] = NA;
	end
	return data,units
end # loadtsf

"""
	writetsf(data,fileout,units,decimal,comment)
Write DataFrame to tsf format

**Input**
* data: dataframe containing columns + timevector in DateTime format
* fileout: full name of the output file
* units: optional output units for all columns
* decimal: optional output precision for either all or individual columns. Maximum precision is %.10g!
* comment: optional output comment

**Example**
```
data = DataFrame(temp=[10.,11.,12.,14.],grav=@data([9.8123,9.9,NA,9.7]),
       datetime=[DateTime(2010,1,1,0),DateTime(2010,1,1,1),
           DateTime(2010,1,1,2),DateTime(2010,1,1,4)]);
writetsf(data,"../test/output/tsf_data.tsf",units=["degC","nm/s^2"],
			comment=["first line","second line"],decimal=[1,3]);
```
"""
function writetsf(data::DataFrame,fileout::String;
					units=[],decimal=[4],comment=[]);
	# find datetime column + use only numberic values for output
	channels,timei = findchannels(data);
    # Write header
	open(fileout,"w") do fid
    	@printf(fid,"[TSF-file] v01.0\n\n");
		flagval = "9999.999";
    	@printf(fid,"[UNDETVAL] %s\n\n",flagval);
	    @printf(fid,"[TIMEFORMAT] DATETIME\n\n");
	    # Compute time resolution and write to header
		increment = round(Dates.value(data[timei][2]-data[timei][1])./1000);
    	@printf(fid,"[INCREMENT] %6.0f\n\n",increment);
     	# Add channel names and units
    	@printf(fid,"[CHANNELS]\n");
	    for i in channels
			@printf(fid,"Location:Instrument:%s\n",i);
        end
        @printf(fid,"\n[UNITS]\n");
		for i = 1:length(channels)
			if !isempty(units)
				@printf(fid,"%s\n",units[i]);
			else
				@printf(fid,"units?\n");
			end
		end
		# Add final comment if on input
		@printf(fid,"\n[COMMENT]\n");
	    if !isempty(comment)
            for i in comment
                @printf(fid,"%s\n",i)
            end
	    end
		# Number of data point + start Data
		nlines = size(data,1);
    	@printf(fid,"\n\n[COUNTINFO] %i\n\n",nlines);
    	@printf(fid,"[DATA]\n");
		# Round data to output precision
		dataout = round2output(data,decimal,channels)
		for i = 1:nlines
			# Write date + time (do not use Dates.format == very slow)
			@printf(fid,"%04i %02i %02i %02i %02i %02i ",
						Dates.year(data[timei][i]),
						Dates.month(data[timei][i]),
						Dates.day(data[timei][i]),
						Dates.hour(data[timei][i]),
						Dates.minute(data[timei][i]),
						Dates.second(data[timei][i]));
			# add data
			for j in channels
				if isna(dataout[j][i])
					@printf(fid," %s",flagval);
				else
					@printf(fid," %.10g",dataout[j][i]);
				end
			end
			@printf(fid,"\n");
		end
	end # open file
end

"""
	mat2time(mat)
Auxiliary function to convert time in matrix to datetime format
"""
function mat2time{T<:Real}(mat::Matrix{T})
	if eltype(mat) != Int
		temp = round.(Int64,mat)
	end
	if size(mat,2) == 3
		return DateTime.(mat[:,1],mat[:,2],mat[:,3])
	else
		return DateTime.(mat[:,1],mat[:,2],mat[:,3],
						 mat[:,4],mat[:,5],mat[:,6])
	end
end

"""
	correct_channels(in_string)
Auxiliary function to get channel names/units from input vector of strings
"""
function correct_channels(in_text::Vector{String},sp::String)
	out = Vector{String}(0);
	for i in in_text
		# Use only last string = name of the channel
		temp = split(i,sp);
		# remove empty spaces and other symbols
		push!(out,replace(temp[end],r" |\r|\"",""))
	end
	return out;
end

"""
	findchannels(data)
Auxiliary funciton to find columns with channel names and datetime
"""
function findchannels(data::DataFrame)
	# find datetime column + use only numberic values for output
	channels = eltype(names(data))==String ? Vector{String}(0) : Vector{Symbol}(0);
	timei = 1;
	for i in names(data)
		if eltype(data[i]) == DateTime
			timei = i;
		elseif eltype(data[i]) == Int || eltype(data[i]) == Float64
			push!(channels,i);
		end
	end
	return channels,timei;
end

"""
	round2output(data,)
Auxiliary function to round data to output precision
"""
function round2output(data::DataFrame,decimal,channels)
	dataout = deepcopy(data);
	for (i,v) in enumerate(channels)
		if length(channels) == length(decimal)
			dataout[v] = round.(data[v].*10^decimal[i])./10^decimal[i];
		elseif length(decimal) == 1
			dataout[v] = round.(data[v].*10^decimal[1])./10^decimal[1];
		end
	end
	return dataout;
end
