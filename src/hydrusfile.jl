"""
	writeatmosph(data,fileout;decimal)
Write DataFrame to Dygraphs csv format

**Input**
* data: dataframe containing columns + timevector in DateTime format.
* fileout: full name of the output file
* decimal: optional output precision for either all or individual columns.
> input dataframe should contain :Prec,:rSoil,:rRoot,:hCritA,:rB,:hB,:ht columns,
> if not, will be set to zero.

**Example**
```
dataout = DataFrame(Prec=[0.01,0.1,0.2,0.3],
				 rSoil=@data([0.0,0.1,0.2,0.9]),
	   			 hCritA=[1,1,1,1]
	   			 datetime=[DateTime(2010,1,1,0),DateTime(2010,1,1,1),
		   			  DateTime(2010,1,1,2),DateTime(2010,1,1,3)],);
writeatmosph(dataout,pwd()*"/test/output/atmosph_data.in",
			decimal=[1],
			hCritS=1000.);
```
"""
function writeatmosph(data::DataFrame,fileout::String;decimal=[4],hCritS=0.0)
	channels,timei = FileTools.findchannels(data);
	# Round data to output precision
	dataout = FileTools.round2output(data,decimal,channels);
	open(fileout,"w") do fid
		# Write header
		writeatmosph_head(fid,size(data,1),hCritS);
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
function writeatmosph_head(fid::IOStream,l::Int,h::Float64)
	@printf(fid,"Pcp_File_Version=4\n");
	@printf(fid,"*** BLOCK I: ATMOSPHERIC INFORMATION  ");
	for i in 1:34 @printf(fid,"*");end
	@printf(fid,"\n   MaxAL                    (MaxAL = number of atmospheric data-records)\n")
	@printf(fid,"   %i\n",l);
	@printf(fid," hCritS                 (max. allowed pressure head at the soil surface)\n");
	@printf(fid,"   %.6g\n",h);
	@printf(fid,"       tAtm        Prec       rSoil       rRoot      hCritA");
	@printf(fid,"          rB          hB          ht      RootDepth\n");
end
