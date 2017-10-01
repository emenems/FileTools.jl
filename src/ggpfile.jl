"""
	readggp(filein;what,offset,nanval)
Load ggp file and store it in DataFrame

**Input**
* filein: full name of the input file
* what: what should be loaded. By default "data", Other options="header" | "blocks"
* offset: Should the offset in block info by applied? Default = false. Use only in combination with `what="data"`
* nanval: flag used for NaNs (NaN will be returned)

**Output**
Depends on `what` switch
* "data": dataframe containing columns + timevector in DateTime format (of what="data")
* "header": string header
* "blocks": DataFrame with starting time and offset for each column

**Example**
```
data = readggp("../test/input/ggp_data.ggp",nanval=99999.999);
blockinfo = readggp("../test/input/ggp_data.tsf",what="blocks");
headerinfo = readggp("../test/input/ggp_data.tsf",what="header");
```
"""
function readggp(filein::String;what::String="data",offset::Bool=false,
					nanval::Float64=9999.999)
	# get block info
	blockinfo = readggpblocks(filein);
	# Return either header or block info if requested
	if what == "header"
		return readggphead(filein);
	elseif what == "blocks"
		return blockinfo;
	else # Otherwise read data
		return readggpdata(filein,blockinfo,nanval,offset=offset)
	end
end

"""
Auxiliary function to read data in ggp file
"""
function readggpdata(filein::String,blockinfo::DataFrame,nanval;offset::Bool=false)
	# Declare output variable size
	columns = size(blockinfo,2)-1;
	lines = sum((blockinfo[:stopline].+1)-blockinfo[:startline]);
	outmat = Matrix{Float64}(lines,columns);
	# Read file
	open(filein,"r") do fid
		readdummy(fid,blockinfo[:startline][1]-1); # read header
		c = 1; # count outmat/outtime lines
		# Read blocks
		for i in 1:size(blockinfo,1)
			for j in 1:1:(blockinfo[:stopline][i]-blockinfo[:startline][i])+1
				outmat[c,1:columns] = readdataline(fid);
				c += 1;
			end
			if i != size(blockinfo,1) # read lines between blocks (except for last block)
				readdummy(fid,blockinfo[:startline][i+1]-blockinfo[:stopline][i]-1);
			end
	    end
	end
	# replace flagged values
	outmat[outmat.==nanval] .= NaN;
	outframe = DataFrame(datetime=sumtime.(outmat[:,1],outmat[:,2]));
	# Correct offsets if needed
	if offset
		for i in 1:size(blockinfo,1),  j in 3:columns
			if blockinfo[j+1][i] != 0.0
				outmat[outframe[:datetime].>=blockinfo[:datetime][i],j] += blockinfo[j+1][i];
			end
		end
	end
	return append2df(outframe,outmat[:,3:end],"column");
end


"""
Auxiliary function to read block headers
"""
function readggpblocks(filein::String)
	blockoffset,blockdate = Vector{String}(0),Vector{String}(0);
	blockstart,blockstop = Vector{Int}(0),Vector{Int}(0);
	open(filein,"r") do fid
		i = 0; # count lines to get block start and stop
		while !eof(fid)
			row = readline(fid); i += 1;
			if contains(row,"77777777")
				push!(blockoffset,row);
				row = readline(fid);i += 1; # read next line containing date
				push!(blockdate,row);
				push!(blockstart,i);
			elseif contains(row,"99999999") # end of block
				push!(blockstop,i-1);
			end
		end
	end
	return block2output(blockoffset,blockdate,blockstart,blockstop)
end

"""
Auxiliary function to read just the GGP file header
"""
function readggphead(filein::String)
	head = Vector{String}(0);
	open(filein,"r") do fid
		row = readline(fid);
		while !contains(row,"C**")
			push!(head,row);
			row = readline(fid);
		end
	end
	return head
end

"""
Auxiliary function to convert string vectors containing info on offset to dataframe
"""
function block2output(offset::Vector{String},timestr::Vector{String},
					blockstart::Vector{Int},blockstop::Vector{Int})
	# get number of columns
	numchan = splitline(timestr[1]) |> length |> x-> x-2;
	# Declare output variable (or rather variables used for output)
	outtime = Vector{DateTime}(0);
	outoffset = Matrix{Float64}(0,numchan);
	for (i,v) in enumerate(timestr)
		push!(outtime,sumtime(splitline(v)[1],splitline(v)[2]));
		if length(split(offset[i])) > 1 # this means the line contains also offset info
			temp = splitline(offset[i]);
		else # line without offset => add 0.0 offset for consistancy
			temp = vcat(77777777,zeros(numchan)) # append zeros
		end
		outoffset = vcat(outoffset,transpose(temp[2:end]));
	end
	out = DataFrame(datetime=outtime,startline=blockstart,stopline=blockstop);
	return append2df(out,outoffset,"offset_column");
end

"""
Auxiliary function to convert time pattern (HHMMSS) to DateTime
"""
function append2df{T<:Real}(indf::DataFrame,appmat::Matrix{T},appstring::String)
	for i in 1:size(appmat,2)
		indf[Symbol(appstring,i)] = appmat[:,i];
	end
	return indf
end

#### Functions related to DateTime
"""
Time in ggp files is splitted in to rows, one with YYYYMMDD second with HHMMSS
These need to be converted to DateTime
"""
function sumtime(indate::Float64,intime::Float64)
	function splittime(time)
		time1::Int = floor(time/10000.);
		time2::Int = floor((time - time1*10000.)/100.);
		time3::Int = floor(time - time1*10000. - time2*100.);
		return time1,time2,time3
	end
	year,month,day = splittime(indate);
	hour,minute,second = splittime(intime);
	return DateTime(year,month,day,hour,minute,second);
end

#### Auxiliary functions for string reading and manupulation
"""
Auxiliary function to read data lines in input file (stream)
"""
function readdataline(fid::IOStream)
	return fid |> readline |> splitline
end
"""
Auxiliary function to prepare string for data extraction
"""
function splitline(str::String)
	return replace(str,r"\s\s+"," ") |> split |> float
end
"""
Auxiliary function to read dummy lines in input file (stream)
"""
function readdummy(fid::IOStream,ntime::Int)
	for i in 1:ntime
		readline(fid);
	end
end
