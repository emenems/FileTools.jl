"""
	writecorrpar(corrpar,fileout)

Write correction parameter DataFrame (`prepcorrpar` output) to a formatted file
See ResampleAndFit.correctinterval function for details

**Input**
* corrpar: correction parameter DataFrame (see `correctinterval`)
* fileout: output file name
* headlines: optional header lines (use "\n" for new lines)
* decimal: number of decimal places used for y1 and y2 (integer, max 8)
**Example**
```
corrpar = DataFrame(column=[1,2,3], id = [3,2,1],
					x1 = [DateTime(2010,01,01,04,30,00),
						  DateTime(2010,01,01,08,00,00),
						  DateTime(2010,01,02,04,00,00)],
				  	x2 = [DateTime(2010,01,01,07,30,00),
						  DateTime(2010,01,01,09,30,09),
						  DateTime(2010,01,02,06,30,00)],
					y1 = [NaN,NaN,10.],y2 = [NaN,NaN,0.0],
					comment = ["first", "second", "third"]);
writecorrpar(corrpar,pwd()*"/test/output/writecorrpar_out.txt",decimal = 1)
```
"""
function writecorrpar(corrpar,fileout;
						headlines::String="Created by FileTools.writecorrpar",
						decimal::Int=2)
	open(fileout,"w") do fid
		!isempty(headlines) ? @printf(fid,"%% %s\n",headlines) : nothing
		@printf(fid,"%% ID: 1 = removing steps, 2 = remove anomalous time intervals (set to NaN),");
		@printf(fid," 3 = interpolate intervals linearly, 5 = replace values using given range\n");
		@printf(fid,"%% CN: is the column number or symbol\n");
		@printf(fid,"%% y1: value before step (set to NaN if ID!=1 | ID!=5)\n");
		@printf(fid,"%% y2: value after step (set to NaN if ID!=1 | ID!=5)\n");
		@printf(fid,"%% comment: string without spaces\n%%\n");
		@printf(fid,"%%ID CN\tyyyy mm dd hh mm ss \tyyyy mm dd hh mm ss");
		@printf(fid,"\t%10s\t%10s \tcomment(do_not_leave_empty_space)\n","y1","y2");
		for i in 1:size(corrpar,1)
			@printf(fid,"%i\t",corrpar[:id][i]);
			eltype(corrpar[:column][i])==Symbol ? @printf(fid,"%s",string(corrpar[:column][i])) : @printf(fid,"%i",corrpar[:column][i]);
			@printf(fid,"\t%s \t%s",
					Dates.format(corrpar[:x1][i],"yyyy mm dd HH MM SS"),
					Dates.format(corrpar[:x2][i],"yyyy mm dd HH MM SS"));@printf(fid," ")
			FileTools.writewithprecision(fid,corrpar[:y1][i],decimal);@printf(fid,"\t")
			FileTools.writewithprecision(fid,corrpar[:y2][i],decimal);@printf(fid,"\t")
			haskey(corrpar,:comment) ? @printf(fid,"%-s",corrpar[:comment][i]) : nothing
			@printf(fid,"\n")
		end
	end
end

"""
Function to read correction parameters used in 'correctinterval' function (ResampleAndFit package)
"""
function readcorrpar(corrfile::String)
	temp = readdlm(corrfile,comments=true,comment_char='%');
	corrpar = DataFrame(column = eltype(temp[:,2][1])==Int64 ? trunc.(Int,temp[:,2]) : Symbol.(temp[:,2]),
						id = trunc.(Int,temp[:,1]),
						x1 = DateTime.(temp[:,3],temp[:,4],temp[:,5],temp[:,6],temp[:,7],temp[:,8]),
						x2 = DateTime.(temp[:,9],temp[:,10],temp[:,11],temp[:,12],temp[:,13],temp[:,14]),
						y1 = convert.(Float64,temp[:,15]),
						y2 = convert.(Float64,temp[:,16]),
						comment = temp[:,17]);
end
