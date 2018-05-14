"""
	writeatmosph(data,fileout;decimal)
Write DataFrame to Hydrus1D Atmospheric data format

**Input**
* data: dataframe containing columns + timevector in DateTime format.
* fileout: full name of the output file
* decimal: optional output precision for either all or individual columns.
> input dataframe should contain :Prec,:rSoil,:rRoot,:hCritA,:rB,:hB,:ht columns,
> if not, will be set to zero. Tested for  Hydrus-1D 4.16.0110

**Example**
```
dataout = DataFrame(Prec=[0.01,0.1,0.2,0.3],
				 rSoil=[0.0,0.1,0.2,0.9],
	   			 hCritA=[1,1,1,1]
	   			 datetime=[DateTime(2010,1,1,0),DateTime(2010,1,1,1),
		   			  DateTime(2010,1,1,2),DateTime(2010,1,1,3)],);
writeatmosph(dataout,pwd()*"/test/output/atmosph_data.in",
			decimal=[1],
			hCritS=1000.,Extinction=-1.0);
```
"""
function writeatmosph(data::DataFrame,fileout::String;decimal=[4],hCritS=0.0,Extinction=-1.0)
	channels,timei = FileTools.findchannels(data);
	# Round data to output precision
	dataout = FileTools.round2output(data,decimal,channels);
	open(fileout,"w") do fid
		# Write header
		writeatmosph_head(fid,size(data,1),Extinction,hCritS);
		# Write data
		for i = 1:size(dataout,1)
			# Write date-index
			@printf(fid,"%11g",i);
			# add data
			for j in [:Prec,:rSoil,:rRoot,:hCritA,:rB,:hB,:ht]
				if haskey(dataout,j)
					@printf(fid,"%12g",dataout[j][i]);
				else # set missing columns to zero
					@printf(fid,"%12g",0);
				end
			end
			@printf(fid,"\n");
		end
		# add footer
		@printf(fid,"end*** END OF INPUT FILE 'ATMOSPH.IN' **********************************\n");
	end
end

"""
auxiliary function to write fixed header
"""
function writeatmosph_head(fid::IOStream,l::Int,extinc::Float64,h::Float64)
	@printf(fid,"Pcp_File_Version=4\n");
	@printf(fid,"*** BLOCK I: ATMOSPHERIC INFORMATION  ");
	for i in 1:34 @printf(fid,"*");end
	@printf(fid,"\n   MaxAL                    (MaxAL = number of atmospheric data-records)\n")
	@printf(fid,"   %i\n",l);
	@printf(fid," DailyVar  SinusVar  lLay  lBCCycles lInterc lDummy  lDummy  lDummy  lDummy  lDummy\n");
	if extinc > -1e-6
		@printf(fid,"       f       f       t       f       f       f       f       f       f       f\n")
		@printf(fid," Extinction\n   %.6g\n",extinc);
	else
		@printf(fid,"       f       f       f       f       f       f       f       f       f       f\n")
	end
	@printf(fid," hCritS                 (max. allowed pressure head at the soil surface)\n");
	@printf(fid,"   %.6g\n",h);
	@printf(fid,"       tAtm        Prec       rSoil       rRoot      hCritA");
	@printf(fid,"          rB          hB          ht      RootDepth\n");
end

"""
	writeprofile1d(nodeinfo,fileout)
Write Hydrus1D profile (nodal) file. Suitable only for pure water flow simulation

**Input**
soilinfo: dataframe containg information on:
* :start = soil layer starting depth
* :stop = soil layer end depth
* :res = vertical resolution (constant sampling)
* :h = Initial value of the pressure head
* :Mat = index of the material
* :Lay = subregion number assigned to nodes within the soil layer

fileout: output file name
iObs: list (vector) of the observation nodes for which values of the pressure head & the water content are printed

> No information about temperature or concentrations is used! Hydrus-1D 4.16.0110

**Example**
```
soilinfo = DataFrame(start=[0],stop=[10],res=[0.01],h=[100],Mat=[5],Lay=[1])
output_file = pwd()*"/test/output/profile1d_data.in"
print_nodes = [1,2,3];
writeprofile1d(soilinfo,output_file,iObs=print_nodes);
```
"""
function writeprofile1d(soilinfo::DataFrame,fileout::String;iObs=[0])
	open(fileout,"w") do fid
		# write header
		@printf(fid,"    2\n");# fixed number for "fixed" nodes
		@printf(fid,"%5g%15g%15g%15g\n",1,soilinfo[:start][1],1,1);
		@printf(fid,"%5g%15g%15g%15g\n",2,-soilinfo[:stop][end],1,1);
		@printf(fid,"%5g%5g%5g%5g",getnumofnodes(soilinfo),0,0,1);
		@printf(fid," x         h       Mat  Lay      Beta           Axz            ");
		@printf(fid,"Bxz            Dxz            Temp          Conc           SConc\n");
		# Write nodes
		c = 1;
		for i in 1:size(soilinfo,1)
			n = soilinfo[:start][i]:soilinfo[:res][i]:soilinfo[:stop][i];
			for j in n
				@printf(fid,"%5g%15g%15g%5g%5g",
						c,-j,soilinfo[:h][i],soilinfo[:Mat][i],soilinfo[:Lay][i]);
				# add constant values
				@printf(fid,"  0.000000e+000  1.000000e+000  1.000000e+000  1.000000e+000              \n");
				c += 1; # count nodes
			end
		end
		# add footer
		if iObs[1] != 0
			@printf(fid,"%5g\n",length(iObs));
			for i in iObs
				@printf(fid,"%5g",i)
			end
			@printf(fid,"\n");
		else
			@printf(fid,"    0\n");
		end
	end
end

"""
auxiliary function to get total number of observation points
"""
function getnumofnodes(soilinfo)
	c = 0;
	for i in 1:size(soilinfo,1)
		for j in soilinfo[:start][i]:soilinfo[:res][i]:soilinfo[:stop][i]
			c += 1; # count nodes
		end
	end
	return c
end

"""
	obnode = readhydrus1d_obsnode(filein,paramout)
Read Hydrus1D observation node output

**Input**
* filein: input file name
* paramout: what parameter should be returned (theta,h or Flux)

**Output**
obnode: dataframe containg:
* :time = time index
* :paramoutX = parameter value for node number X

> Designed only for Hydrus1D with water fluxes only! Hydrus-1D 4.16.0110

**Example**
```
input_file = pwd()*"/test/input/hydrus1d_Obs_Node.out"
obnode = readhydrus1d_obsnode(input_file,paramout=:theta)
```
"""
function readhydrus1d_obsnode(filein::String;paramout::Symbol=:theta)
	# read all data
	dataall = readdlm(filein,skipstart=11,comment_char='e');
	obsnodes = getnodenumber(filein,paramout);
	dataout = DataFrame(time=dataall[:,1]);
	if paramout == :h
		col = 2;
	elseif paramout == :Flux
		col = 4;
	else
		col = 3;
	end
	for (i,v) in enumerate(obsnodes)
		dataout[v] = dataall[:,col+(i-1)*3];
	end
	return dataout;
end

"""
	atm = readatmosph(filein)
Read Hydrus1D ATMOSPH.IN file

**Input**
* filein: input file name

**Output**
obnode: dataframe containg:
* :time = time index
* :param = parameter name

> Designed only for Hydrus1D Hydrus-1D 4.16.0110

**Example**
```
input_file = pwd()*"/test/input/hydrus1d_atmosph.in"
atm = readatmosph(input_file)
```
"""
function readatmosph(filein::String)
	nh = headlines(filein,"tAtm");
	temp = readdlm(filein,skipstart=nh-1);
	out = DataFrame(time=temp[2:end-1,1]);
	for (i,v) in enumerate(temp[1,2:end])
		out[Symbol(v)] = eltype(temp[2,i+1])==Char ?
						zeros(Float64,length(temp[2:end-1,1])).*NaN :
						convert(Vector{Float64},temp[2:end-1,i+1])
	end
	return out
end

"""
Aux function to count number of header lines (up to a given string)

**Example**
```
filein = "f:/mikolaj/code/data_processing/sites/aggo/hydro/hydrus/AGGO/ATMOSPH.IN";
nh = headlines(filein,"tAtm")
```
"""
function headlines(filein::String,flag::String)
	c = 0;
	open(filein,"r") do fid
		row = readline(fid);
		while !contains(row,flag)
			row = readline(fid);
			c += 1;
			if eof(fid)
				c = 0; break
			end
		end
	end
	return c+1
end

"""
auxiliary function to read node numbers
"""
function getnodenumber(filein::String,paramout::Symbol)
	obsnodes = Vector{Symbol}();
	# read node numbers
	open(filein,"r") do fid
		row = "";
		for i in 1:9
			row = readline(fid);
		end
		obsnodes = parsenodenumber(row,paramout);
	end
	return obsnodes;
end

"""
auxiliary function to extract numbers from string
"""
function parsenodenumber(row::String,paramout::Symbol)
	temp = split(row,"Node(");
	c = 1000; # max obs node number in the hydrusFile is 999 (above just ***)
	out = Vector{Symbol}();
	for i in temp[2:end] # starts with empty field (see split)
		if !contains(i,"*") # numbers below 1000
			obsnode = parse(split(i,")")[1]) # ends with ')'
		else
			obsnode = c;
			c += 1;
		end
		out = vcat(out,Symbol(string(paramout)*string(obsnode)));
	end
	return out
end


"""
	obnode = readhydrus1d_nedinf(filein,paramout)
Read Hydrus1D Node Info file (Nod\_inf.out)

**Input**
* filein: input file name
* paramout: what parameter should be returned (all (default), theta, h or k)

**Output**
theta,k,h: dataframe containg:
* :time = time index
* :nodeX = valus for node number X

> Designed only for Hydrus1D with water fluxes only!

**Example**
```
input_file = pwd()*"/test/input/hydrus1d_Nod_Inf.out"
moisture = readhydrus1d_nedinf(input_file,paramout=:theta)
# moisture,k,h = readhydrus1d_nedinf(input_file)
```
"""
function readhydrus1d_nodinf(filein;paramout::Symbol=:all)
	# declare output
	timeout = -1;
	h = Matrix{Float64}(0,0);
	theta = Matrix{Float64}(0,0);
	k = Matrix{Float64}(0,0);
	node = Vector{Int}(0);
	depth = Vector{Float64}(0);
	# read header
	open(filein,"r") do fid
		row = readhydrus1d_nodinf_head(fid);
		while !eof(fid)
			timeblock,datablock = readhydrus1d_nodinf_block(fid,row);
			if typeof(timeout)==Int # initial run
				timeout = timeblock;
				h = datablock[:,3]; # get Heat values (fixed position)
				theta = datablock[:,4];
				k = datablock[:,5]; # get hydraulic conductivity values (fixed position)
				node = round.(Int,datablock[:,1]); # read nodes and depth only once
				depth = datablock[:,2];
			else
				timeout = vcat(timeout,timeblock);
				h = hcat(h,datablock[:,3]);
				theta = hcat(theta,datablock[:,4]);
				k = hcat(k,datablock[:,5]);
			end
			row = readline(fid); # to reach EOF after last node info block
		end
	end
	if paramout == :theta # could not pass "paramout" as input
		return readhydrus1d_nodinf_df(timeout,node,theta)
	elseif paramout == :k
 		return readhydrus1d_nodinf_df(timeout,node,k)
	elseif paramout == :h
 		return readhydrus1d_nodinf_df(timeout,node,h)
	else # return 3 dataframes (default)
		return readhydrus1d_nodinf_df(timeout,node,theta),
				readhydrus1d_nodinf_df(timeout,node,k),
				readhydrus1d_nodinf_df(timeout,node,h)
    end
end

"""
auxiliary function to read time and data for each block
"""
function readhydrus1d_nodinf_block(fid,row)
	# find time stamp
	while !contains(row,"Time:")
		row = readline(fid);
	end
	timeout = parse(split(row,":")[2])
	# ignore header for each time step
	row = readhydrus1d_nodinf_head(fid);
	# read data
	datanode = readhydrus1d_nodinf_data(fid);
	return timeout,datanode
end

"""
auxiliary function to read file header
"""
function readhydrus1d_nodinf_head(fid)
	row = " ";
	for i in 1:5
		row = readline(fid);
	end
	return row;
end

"""
auxiliary function to get data for current block
"""
function readhydrus1d_nodinf_data(fid)
	# stack the data to a matrix
	datanode = Matrix{Float64}(1,11);
	row = readline(fid);
	while !contains(row,"end")
		datanode = vcat(datanode,row |> split |> x -> parse.(Float64,x) |> transpose);
		row = readline(fid);
	end
	return datanode[2:end,:]; # first line is a dummy used for declaration
end

"""
auxiliary function to convert matrix to dataframe
"""
function readhydrus1d_nodinf_df(timeout,nodes,dataout)
	df = DataFrame(time = timeout);
	for (i,v) in enumerate(nodes)
		temp = Symbol("node"*string(v));
		df[temp] = dataout[i,:];
	end
	return df
end

"""
	corr_hydrus1d_obsnode(file_obs_node,file_profile)
Correct Hydrus1D Observation node file if this does not contain all node numbers
in the header. This is motly the case if more then 10 observation nodes are
selected (manually) in the profile settings.

**Input**
* file_obs_node: Observation node file (mostly "Obs_Node.out"). The header of this file will be overwritten
* file_profile: profile settings file (mostly "PROFILE.DAT"). Will be used to get full row of Node IDs

**Example**
```
file_obs_node = "f:/mikolaj/code/data_processing/sites/aggo/hydro/model/hydrus/AGGO/Obs_Node.out"
file_profile = "f:/mikolaj/code/data_processing/sites/aggo/hydro/model/hydrus/AGGO/PROFILE.DAT"
FileTools.corr_hydrus1d_obsnode(file_obs_node,file_profile)
```
"""
function corr_hydrus1d_obsnode(file_obs_node::String,file_profile::String)
	fileout = "temp_Obs_Node.out";

	## Get node numbers
	temp = ""
	fid = open(file_profile,"r");
	node_id = fid |> readlines |> x->x[end] |> split |> x-> parse.(Int,x)
	close(fid)

	## Write with new Node Info
	open(file_obs_node,"r") do fid
		fid_out = open(fileout,"w");
		while !eof(fid)
			row = readline(fid);
			if contains(row,"Node(")
				for i in node_id
					@printf(fid_out,"                      Node(%3i)",i)
				end
			else
				@printf(fid_out,"%s",row);
			end
			@printf(fid_out,"\n");
		end
		close(fid_out)
	end
	cp(fileout,file_obs_node,remove_destination=true);
	rm(fileout);
end
