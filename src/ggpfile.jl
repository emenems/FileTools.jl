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

"""
	writeggp(datawrite,fileout,units,decimal,header)
Write DataFrame to ggp format

**Input**
* datawrite: dataframe containing columns + timevector in DateTime format
* fileout: full name of the output file
* units: optional output units for all columns
* decimal: optional output precision for either all or individual columns. Maximum precision are 8 decimal places!
* header: optional output containing header lines
* channels: DataFrame keys to be exported
* file_format: "preterna" (=ggp=default) or "eterna" file format
* blockinfo: info on data blocks (see example below)
* flagval: string used as flag for missing data

**Example**
```
datawrite = DataFrame(pres=collect(1000.:1:1011.),
					grav=collect(900.:-3:(900.-11*3)),
       				datetime=collect(DateTime(2010,1,1):Dates.Hour(1):DateTime(2010,1,1,11)));
# set units using the same keywords as in the dataframe
units = Dict(:grav=>"V",:pres=>"hPa")
# Set header. All entries with the excetpion of "freetext" will be formatted
header = Dict("Filename"=>"file.data",
              "Station"=>"Wettzell",
              "Instrument"=>"iGrav",
              "N. Latitude (deg)"=>49.14354,
              "E. Longitude (deg)"=>12.87866,
              "Elevation MSL (m)"=>613.7+1.05,
              "Author"=>"Name (name@gfz-potsdam.de)",
			  "freetext"=>"This text will be appended without formating\nMaximum 80 characters per line");
fileout = "f:\\mikolaj\\download\\test.ggp";
# Set block info:
#	"start" = starting time of the block
#	"offset" = offset for each block and channel
#   "header" = Insert text between blocks (e.g. for Eterna34-V60)
# 				Warning: the first entry will be inserted at the
#               beginning of the file and the second to the start of the
#               first block! => set length(blocks)+1 headers!
#               Or, setting cell with one row = same block header for
#               all block start. Do not set if needed.
#				Example for ET34-ANA-V60 (same for all blocks):
#               ["instrument",calibation,calibration SD, lag ,Number of Chebychev polynomial bias parameter];
block = Dict("start"=>[DateTime(2010,1,1,09,0,0)],
			"offset"=>[10 20], # one row per block. 2 values per row = number channels
            "header"=>["iGrav006" 1.0 1.0 0.0 3])
writeggp(datawrite,fileout,units=units,
			header=header,decimal=[2,1],
			blockinfo=block,channels=[:grav,:pres]);
```
"""
function writeggp(datawrite::DataFrame,fileout::String;
					units=[],decimal=[2],channels=[],header=[],
					file_format="preterna",blockinfo=[],
					flagval="9999.999")
	# Get channel names if not set
	if isempty(channels)
		channels,timei = findchannels(datawrite);
	else
		temp,timei = findchannels(datawrite);
	end
	# check decimal precision
	if length(decimal) != length(channels)
		decimal = zeros(Int,length(channels)) + decimal[1];
	end
	# find data blocks
	bstart,bstop,bvalue = writeggp_findblocks(datawrite,channels,blockinfo);
	# write to file
	open(fileout,"w") do fid
		writeggp_head(fid,header,channels,units);
		for i in 1:length(bstart)
			# write block header if needed
			if !isempty(blockinfo)
				if haskey(blockinfo,"header")
					# either identical header for each block (temp=1), or each block new header (temp=i)
					temp = size(blockinfo["header"],1) == 1 ? 1 : i
					@printf(fid,"%10s%15.4f%10.4f%10.3f%10i\n",
	                    	blockinfo["header"][temp,1],blockinfo["header"][temp,2],
							blockinfo["header"][temp,3],blockinfo["header"][temp,4],
	                    	blockinfo["header"][temp,5]);
				end
			end
			# write data for each block
			writeggp_writeblock(fid,datawrite,channels,timei,bstart[i],bstop[i],
								decimal,flagval);
		end
	    # Add 88888888 for eterna format only
	    if file_format=="eterna"
	         @printf(fid,"88888888\n");
	    end
	end
end

"""
auxiliary function to write the header
"""
function writeggp_head(fid,header,channels,units)
	if !isempty(header)
		for i in header
			if !contains(i[1],"freetext")
	   			@printf(fid,"%-21s: %s\n",i[1],i[2])
			end
		end
		if haskey(header,"freetext")
			@printf(fid,"%s\n",header["freetext"])
		end
	end
	@printf(fid,"yyyymmdd hhmmss");
	for i in 1:length(channels)
		if isempty(units)
			temp = "?"
		else
			temp = units[channels[i]];
		end
		@printf(fid," %s(%s)",channels[i],temp);
	end
	@printf(fid,"\nC*******************************************************\n");
end

"""
auxiliary function to find data blocks
"""
function writeggp_findblocks(datain,channels,blockinfo)
	# Find blocks in time/data
	bstart = [1];
	bstop = Vector{Int64}();
	bvalue = zeros(1,length(channels));
	if !isempty(blockinfo)
		for i in 1:length(blockinfo["start"])
			temp = find(x -> x >= blockinfo["start"][i],datain[:datetime]);
			if !isempty(temp)
				bstart = vcat(bstart,temp[1]);
				bstop = vcat(bstop,temp[1]-1);
				bvalue = vcat(bvalue,blockinfo["offset"][i,:]');
			end
		end
		bstop = vcat(bstop,size(datain,1));
	else
		bstop = size(datain,1);
	end
	return bstart,bstop,bvalue
end

"""
Auxiliary function to write data blocks
"""
function writeggp_writeblock(fid::IOStream,datawrite::DataFrame,
							channels::Vector{Symbol},timei::Symbol,
							s1::Int,s2::Int,decimal::Vector{Int},
							flagval::String)
	# beginning of the block
	@printf(fid,"77777777        ");
	for (c,j) in enumerate(channels)
		writewithprecision(fid,0.0,decimal[c]);
	end
	@printf(fid,"\n");
	for i in s1:s2
		# write date+time
		@printf(fid,"%04i%02i%02i %02i%02i%02i ",
				Dates.year(datawrite[timei][i]),
				Dates.month(datawrite[timei][i]),
				Dates.day(datawrite[timei][i]),
				Dates.hour(datawrite[timei][i]),
				Dates.minute(datawrite[timei][i]),
				Dates.second(datawrite[timei][i]));
		# write data
		for (c,j) in enumerate(channels)
			if isna(datawrite[j][i]) || isnan(datawrite[j][i])
				@printf(fid," %s",flagval);
			else
				writewithprecision(fid,datawrite[j][i],decimal[c]);
			end
		end
		@printf(fid,"\n");
	end
    # End block
    @printf(fid,"99999999\n");
end

function writewithprecision(fid::IOStream,d::Float64,decimal::Int)
	if decimal == 0
		@printf(fid," %9.0f",d);
	elseif decimal == 1
		@printf(fid," %9.1f",d);
	elseif decimal == 2
		@printf(fid," %9.2f",d);
	elseif decimal == 3
		@printf(fid," %9.3f",d);
	elseif decimal == 4
		@printf(fid," %9.4f",d);
	elseif decimal == 5
		@printf(fid," %9.5f",d);
	elseif decimal == 6
		@printf(fid," %9.6f",d);
	elseif decimal == 7
		@printf(fid," %9.7f",d);
	elseif decimal == 8
		@printf(fid," %9.8f",d);
	end
end
