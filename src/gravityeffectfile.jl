"""
	read_layerResponse(filein)
Read `layerResponse` results. See GravityEffect.jl package for details

**Input**
* filein: input file
* par: parameter to be read: "results","zones","layers","exclude","nanheight","outfile","def_density"

**Example**
```
fileinput = pwd()*"/test/input/layerResponse.txt";
response = read_layerResponse(fileinput,"results");
layers = read_layerResponse(fileinput,"layers");
```
"""
function read_layerResponse(filein::String,par::String="results")
	if par=="results"
		d = readdlm(filein,comment_char='%');
		out = DataFrame(layer=d[:,1],start=d[:,2],stop=d[:,3],total=d[:,4]);
		for i in 1:size(d,2)-4
			out[Symbol("zone"*string(i))] = d[:,i+4]
		end
		return out
	else
		row = ""
		open(filein,"r") do fid
			while !occursin(lowercase(row),lowercase(par))
				row = eof(fid) ? par : readline(fid)
			end
		end
		return occursin(row,"->") ? eval(Base.parse(split(row,"->")[2])) : []
	end
end

"""
	write_layerResponse(sensor,layers,zones,exclude,nanheight,outfile,def_density,outdata)
Write `layerResponse` results. See GravityEffect.jl package for details

"""
function write_layerResponse(sensor,layers,zones,exclude,nanheight,outfile,def_density,outdata)
	open(outfile,"w") do fid
		@printf(fid,"%% layerResponse.jl SETTINGS:\n");
		# Write settings
		println(fid,"% sensor->$sensor");
		println(fid,"% layers->$layers");
		println(fid,"% zones->$zones");
		println(fid,"% exclude->$exclude");
		println(fid,"% nanheight->$nanheight");
		println(fid,"% outfile->$outfile");
		println(fid,"% def_density->$def_density");
		@printf(fid,"%% Computation date: %s\n",Dates.format(now(),"dd/mm/yyyy HH:MM:SS"))
		@printf(fid,"%% RESULTS (gravity effect in nm/s^2, depth in m): \n");
		@printf(fid,"%%  Nr start  stop    total ");
		for i in 1:length(zones[:radius])
			@printf(fid," %8s%i","zone",i);
		end
		@printf(fid,"\n");
		for i in 1:size(outdata,1)
			@printf(fid,"%4i %6.3f %6.3f %9.5f",i,
					outdata[:start][i],outdata[:stop][i],outdata[:total][i]*1e+9);
			for j in 1:length(zones[:radius])
				@printf(fid," %9.5f",outdata[Symbol("zone"*string(j))][i]*1e+9);
			end
			@printf(fid,"\n");
		end
	end
end
