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
df,units = loadtsf("../test/input/tsf_data.tsf");
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
	channels = correct_channels(channels);
	units = correct_channels(units);
	# Read all data (will be sorted afterwards)
	data = readdlm(filein,skipstart=count_header,header=false);
	# Convert time to datetime
	df = DataFrame(datetime=mat2time(data[:,1:6]))
	# Fill columns
	for i = 7:size(data,2)
		channame = i-6 <= length(channels) ? channels[i-6] : "measurement"*string(i-6)
		df[Symbol(channame)] = data[:,i];
		# Remove Undetval
		df[Symbol(channame)][find(x->x==undetval,df[Symbol(channame)])] = NA;
	end
	return df,units
end # loadtsf

"""
	correct_channels(in_string)
Auxiliary function to get channel names/units from input vector of strings
"""
function correct_channels(in_text::Vector{String})
	out = Vector{String}(0);
	for i in in_text
		# Use only last string = name of the channel
		temp = split(i,":");
		# remove empty spaces and other symbols
		push!(out,replace(temp[end],r" |\r",""))
	end
	return out;
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
