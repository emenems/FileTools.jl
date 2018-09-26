"""
	vav2tsoft(file_results,file_output;sitename)
Convert VAV06 results (Earth tides) to TSoft tidal group info (written
parameters can be used in "LOCAT.TSD")

**Input**
* file_results: file containing VAV results (="analysisXX.dat") of gravity tidal analysis
* file_output: output file with tidal groups in tsoft format. Paste these results to TSoft/Tidal parameter set
* site: name of the site (identical to TSoft database)
* name: name of the tidal parameters (unique for given site)
* filemode: write new file ("w", default) or append to existing ("a")

file_vav = pwd()*"/test/input/vav_analysis.dat";
file_tsoft = pwd()*"/test/output/vav2tsoft.txt"
vav2tsoft(file_vav,file_tsoft,site="Cantlay",name="test");
"""
function vav2tsoft(file_results::String,file_output::String;
					site::String="Site",name::String="Name",
					filemode::String="w")::Void
	# Get number of header lines
	hl = FileTools.headlines(file_results,"results at filter frequency")
	# open file for writting + add header
	fo = tide2tsoft(file_output,site,name,filemode);
	# write parameters
	if hl != 0
		open(file_results,"r") do fid
			for i in 1:hl+1;readline(fid); end
			row = readline(fid);
			while !occursin(row,">")
				if !occursin(row,"---") && !occursin(row,"results")
					vav2tsoft_write(fo,row);
				end
				row = readline(fid);
				eof(fid) ? break : nothing;
			end
		end
	end
	close(fo);
end
"""
Auxiliary function to write the output file of vav2tsoft function
"""
function vav2tsoft_write(f::IOStream,s::String)::Void
	@printf(f,"COMP: %s  %s  %s  %s  %s\n",
			s[1:10],s[13:20],s[50:57],s[65:73],replace(s[27:31]," ",""));
end

"""
	eterna2tsoft(file_results,file_output;file_groups,sitename)
Convert ETERNA34 "PRN" results (Earth tides) to TSoft tidal group info (written
parameters can be used in "LOCAT.TSD")
> Make sense only when the analyze parameter TIDALPOTEN= 4

**Input**
* file_results: file containing tidal analysis results (="projectname.prn")
* file_output: output file with tidal groups in tsoft format. Paste these results to TSoft/Tidal parameter set
* site: name of the site (identical to TSoft database)
* name: name of the tidal parameters (unique for given site)
* filemode: write new file ("w", default) or append to existing ("a")

file_eterna = pwd()*"/test/input/eterna_analysis.prn";
file_tsoft = pwd()*"/test/output/eterna2tsoft.txt"
eterna2tsoft(file_eterna,file_tsoft,site="Cantlay",name="test");
"""
function eterna2tsoft(file_results::String,file_output::String;
					site::String="Site",name::String="Name",
					filemode::String="w")::Void
	# Get number of header lines
	hl = FileTools.headlines(file_results,"Adjusted tidal parameters :")
	# open file for writting + add header
	fo = tide2tsoft(file_output,site,name,filemode);
	# write parameters
	if hl != 0
		open(file_results,"r") do fid
			for i in 1:hl+5;readline(fid); end
			row = readline(fid);
			while !occursin(row,"Adjusted")
				length(row)>73 ? eterna2tsoft_write(fo,row) : nothing
				row = readline(fid);
				eof(fid) ? break : nothing;
			end
		end
	end
	close(fo);
end
"""
Auxiliary function to write the output file of eterna2tsoft function
"""
function eterna2tsoft_write(f::IOStream,s::String)::Void
	@printf(f,"COMP: %s %s %s %s %s\n",
			s[7:15],s[16:24],s[39:48],s[57:66],replace(s[25:29]," ",""));
end
"""
Auxiliary function to write TSD header
"""
function tide2tsoft(filein::String,site::String,name::String,filemode::String)::IOStream
	f = open(filein,filemode);
	@printf(f,"[TIDECOMP] %s\n",site)
	@printf(f,"NAME: %s\nTYPE: 1\nAZIM: 0.0000000\nGRAV: 0.0000000\n",name);
	return f
end
