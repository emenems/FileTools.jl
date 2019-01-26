"""
	loadeop(filein)
(Download &) read EOP data (C04)

**Input**
* filein: either URL to EOP C04 or file name with downloaded EOP C04 parameters

**Output**
* DataFrame with DateTime, and all columns of the input file

**Example**
```
# Download data automatically
eop = loadeop("http://hpiers.obspm.fr/iers/eop/eopc04/eopc04_IAU2000.62-now");
# Or read data from already downloaded file
eop = loadeop("/test/input/eop_parameters.c04");
```
"""
function loadeop(filein::String)
	# Download file if necessary
	downto = downfile(filein);
	if !isempty(downto)
		channels = eopchannels(downto);
		dataall = readdlm(downto,skipstart=14)
		eopfile = DataFrame(datetime=FileTools.mat2time(dataall[:,1:3]));
		for (i,v) in enumerate(channels)
			eopfile[v] = dataall[:,i+3];
		end
		# delete downloaded file
		delfile(filein);
		return eopfile;
	else
		return DataFrame(datetime=0);
	end
end

"""
	downfile(filein::String)
Auxiliary function for downloading of files on internet. The downloaded files
will be stored in a temporary file
"""
function downfile(filein::String)
	downto = "tempdownfile.down";
	if occursin("http:",filein) || occursin("ftp:",filein)
		try
			download(filein,downto)
		catch
			downto = "";
		end
		return downto;
	else
		return filein;
	end
end

"""
	delfile(filein)
Delete file IF downloaded
"""
function delfile(filein::String)
	if occursin("http:",filein) || occursin("ftp:",filein)
		if isfile("tempdownfile.down")
			rm("tempdownfile.down")
		end
	end
end

"""
	eopchannels(filein)
Get EOP header=channels
"""
function eopchannels(filein::String)
	channels = Array{Symbol,1}();
	open(filein,"r") do fid
		row = "";
		for i in 1:11
			row = readline(fid);
		end
		temp = split(row,"  ");
		for i in temp
			if (i != "") && (i != "Date")
				push!(channels,Symbol(replace(i," "=>"")));
			end
		end
	end
	return channels;
end
