"""
	readcampbell(filein)
Load data stored in Campbell logger file format to DataFrame

**Input**
* filein: full name of the input file

**Output**
* dataframe containing columns + timevector in DateTime format
* data units

**Example**
```
data,units = readcampbell("../test/input/campbell_data.tsf");
```
"""
function readcampbell(filein::String)
	channels = Array{SubString{String},1}();
	units = Array{SubString{String},1}();
	# Read header
	open(filein,"r") do fid
		readline(fid);# firts line is not important
		# Read channel names
		temp = split(replace(readline(fid),r" |\r|\""=>""),','); # remove funny symbols
		channels = temp[2:end];
		# Read units
		temp = split(replace(readline(fid),r" |\r|\""=>""),','); # remove funny symbols
		units = temp[2:end];
	end
	# read data
	dataall = readdlm(filein,',',skipstart=4,header=false);
	data = DataFrame(datetime=DateTime.(dataall[:,1],"yyyy-mm-dd HH:MM:SS"))
	for (i,v) in enumerate(channels)
		data[Symbol(v)] = dataall[:,i+1];
	end
	return data,units;
end
