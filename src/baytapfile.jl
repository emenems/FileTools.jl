"""
	writebaytap(data,columnout,fileout,sensor;header,decimal)
Write hourly data in Baytap08 fixed/free file format

**Input**
* data: hourly data (equally sampled) in a dataframe containing columns + timevector in DateTime format.
* columnout: which column of the input data should be exported
* fileout: full name of the output file
* sensor: location of the sensor (longitude <-180,180>, latitude <-90,90>,height, mean gravity in cm/s^2)
* header: string to be written to header file  (by default first data column)


**Example**
```
timeout = collect(DateTime(2010,1,1,0):Dates.Hour(1):DateTime(2010,1,2,3));
gravout = ones(Float64,length(timeout));
gravout[[3,end]] .= NaN;
gravout[[4,7]] .= 10.123;
dataout = DataFrame(datetime=timeout, grav=gravout);
writebaytap(dataout,:grav,
			(14.123,45.888,100.0,982.024), # position+mean gravity
			pwd()*"/test/output/baytap_dataseries.txt",
			header="writebaytap unit test");
```
"""
function writebaytap(data::DataFrame,columnout::Symbol,sensor::Tuple{Float64,Float64,Float64,Float64},
					fileout::String;header="Earth tide station")
	# fixed output precission
	decimal = 2;
	val_per_line = 6;
	# Round data to output precision
	dataout = FileTools.round2output(data,[decimal],[columnout]);
	# get time resolutin (input must be equally sampled)
	time_step = Dates.value(diff(dataout[:datetime][1:2])[1])/3600000;
	open(fileout,"w") do fid
		# Write header
		@printf(fid,"%s\n",header);
		@printf(fid,"%10.5f%10.5f%10.2f%10.4f\n",
				sensor[1],sensor[2],sensor[3],sensor[4]);
		@printf(fid,"%s\n",yyyymmddhh(dataout[:datetime][1]))
		@printf(fid,"%5i%5.4g   9000.D0\n",size(dataout,1),time_step)
		@printf(fid,"(%iF10.%d)\n",val_per_line,decimal)
		# Write data
		c = 1;
		for i = 1:size(dataout,1)
			if isnan(dataout[columnout][i])
				@printf(fid,"   9999.99");
			else
				@printf(fid,"%10.2f",dataout[columnout][i]);
			end
			if c < val_per_line # six values per line
				c += 1;
			else
				@printf(fid,"\n");
				c = 1;
			end
		end
	end
end

"""
auxiliary function to export time string in required format
"""
function yyyymmddhh(timein::DateTime)
	yyyy,mm,dd,hh,mi,ss = datevec(timein)
	return @sprintf("%5i%5i%5i%10.5f",
					yyyy,mm,dd,hh + mi/60 .+ ss/3600.)
end

"""
auxiliary function to convert datetime to date vector
"""
function datevec(timein::DateTime)
	return Dates.value(Dates.Year(timein)),
		   Dates.value(Dates.Month(timein)),
		   Dates.value(Dates.Day(timein)),
		   Dates.value(Dates.Hour(timein)),
		   Dates.value(Dates.Minute(timein)),
		   Dates.value(Dates.Second(timein))
end


"""
	baytap2tsoft(file_results,file_output;file_groups,sitename)
Convert baytap08 results (Earth tides) to TSoft tidal group info (written
parameters can be used in "LOCAT.TSD")

**Input**
* file_results: file containing baytap08 results of gravity tidal analysis
* file_output: output file with tidal groups in tsoft format. Paste these results to TSoft/Tidal parameter set
* file_groups: file containing tidal waves after Tamura (1987) (see /test/input/ folder of this package)
* site: name of the site (identical to TSoft database)
* name: name of the tidal parameters (unique for given site)
* filemode: write new file ("w", default) or append to existing ("a")

**Example**
```
file_results = pwd()*"/test/input/baytap08.out";
file_output = pwd()*"/test/output/baytap2tsoft.txt"
baytap2tsoft(file_results,file_output,site="Cantlay",name="test");
```
"""
function baytap2tsoft(file_results::String,file_output::String;
					  site::String="Site",name::String="Name",
					  file_groups::String="f:/mikolaj/code/libraries/julia/FileTools.jl/test/input/baytap_tamura_waves.txt",
					  filemode::String="w")
	waves = readdlm(file_groups);
	# open file for writting
	# open file for writting + add header
	fo = FileTools.tide2tsoft(file_output,site,name,filemode);
	# write parameters
	open(file_results,"r") do fid
		row = readline(fid);
		while !eof(fid)
			if occursin(">",row)
				if row[2] != 'R'
					wstart,wstop,wfactor,wphase,wname = get_wave_info(row);
					freqinfo = find_freq_info(wstart,wstop,waves);
					@printf(fo,"COMP: %8.6f  %8.6f  %7.5f  %8.4f %s\n",
							freqinfo[1],freqinfo[2],wfactor,wphase,wname);
				end
			end
			row = readline(fid);
		end
	end
	close(fo);
end

"""
Auxiliary function to extract needed results
"""
function get_wave_info(row::String)
	temp = split(row)
	wstart = temp |> x -> split(x[3],"-") |> x -> Meta.parse.(x[1])
	wstop = temp |> x -> split(x[3],"-") |> x -> Meta.parse.(x[2][1:end-1])
	wfactor = Meta.parse(temp[5])
	wphase = Meta.parse(temp[7])
	wname = temp[4];
	return wstart,wstop,wfactor,wphase,wname
end

"""
Auxiliary function to find frequency giving wave number
"""
function find_freq_info(wstart,wstop,waves)
	r1 = findall(waves[:,1].==wstart)
	r2 = findall(waves[:,1].==wstop)
	return (waves[r1[1],3],waves[r2[1],3])
end
