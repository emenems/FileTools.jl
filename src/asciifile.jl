"""
	loadascii(filein)
Load arc asii formated files (DEMs)

**Input**
* filein: full name of the input file

**Output**
* Dictionary containing: x,y (coordinate vectors) and height (matrix)
* Warning: the the origin of the coordinate system in loaded file is in the upper left corner and y axis points downwards (x to right)!

**Example**
```
dem = loadascii("../test/input/ascii2mat_data.asc");
```
"""
function loadascii(filein::AbstractString)
	# Declare variables
	ncols = 1;nrows = 1;xll = 0;yll = 0;resol = 1;nodata = 9999;
	# Read header (fixed number of header lines)
	head = 6;
	fid = open(filein,"r");
	try
		for i = 1:head
			row = readline(fid);
		 	temp = split(row," ");
			if contains(lowercase(row),"ncols")
	            ncols = parse(Int,temp[end]);
	        elseif contains(lowercase(row),"nrows")
	            nrows = parse(Int,temp[end]);
	        elseif contains(lowercase(row),"xll")
	            xll = parse(Float64,temp[end]);
	        elseif contains(lowercase(row),"yll")
	            yll = parse(Float64,temp[end]);
	        elseif contains(lowercase(row),"cellsize")
	            resol = parse(Float64,temp[end]);
	        elseif contains(lowercase(row),"nodata")
	            nodata = parse(Float64,temp[end]);
	        end
		end
		close(fid);
	finally
		close(fid);
	end
	# Read data using readdlm function
	data = readdlm(filein,skipstart=head,header=false);
	# Transpose/flip upside down the input data to be get correct values with
	# respect to x,y (meshgrid)
	height = flipdim(data,1);
	# Compute x, y grid vectors
	x = collect(xll+resol/2:resol:xll+resol/2+resol*(ncols-1));
	y = collect(yll+resol/2:resol:yll+resol/2+resol*(nrows-1));
	# Set NoData values to NaN
	height[height.==nodata] = NaN;
	return Dict(:x => x,:y => y, :height => height);
end

"""
	writeascii(dem,filout;flag;decimal)
Write arc asii formated files (DEMs)

**Input**
* dem: Dictionary containing: x,y (coordinate vectors) and height (matrix)
* fileout: full name of the output file
* flag: replace NaNs with flag (default = "9999")
* decimal: output precision (default 4 => 4 decimal places). Will be applied only to height. Maximum precision is %.10g!

**Example**
```
dem = Dict(:x => collect(1:1:10.),:y => collect(10:1:20.),
       	   :height => ones(10,11));
writeascii(dem,"../test/output/ascii2mat_data.asc");
```
"""
function writeascii(dem::Dict{Symbol,Any},fileout::String;
							 flag::String="9999",decimal::Int=4)
	# Set to output precision
	h = round.(dem[:height].*10^decimal)./10^decimal;
	# Flipt upside down to get required format (y downards)
	h = flipdim(h,1);
	# get output size
	nrows,ncols = size(h);
	cellsize = abs(dem[:x][1]-dem[:x][2]);
	# compute lower left corner
	xll = minimum(dem[:x])-cellsize/2;
	yll = minimum(dem[:y])-cellsize/2;
	# write
	open(fileout,"w") do fid
		# write header
		@printf(fid,"ncols %i\nnrows %i\n",ncols,nrows);
	    @printf(fid,"xllcorner %.10g\nyllcorner %.10g\n",xll,yll);
	    @printf(fid,"cellsize %.10g\n",cellsize);
	    @printf(fid,"nodata_value %s\n",flag);
		# write data/grid
		for x = 1:nrows
			for y = 1:ncols
				if isnan(h[x,y])
					@printf(fid,"%s ",flag);
				else
					@printf(fid,"%.10g ",h[x,y]);
				end
			end
			@printf(fid,"\n");
		end
	end
end
