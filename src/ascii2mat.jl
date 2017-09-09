"""
	loadtsf(filein)
Load arc asii formated files (DEMs)

**Input**
* filein: full name of the input file

**Output**
* Dictionary containing: x,y (coordinate vectors) and height (matrix)
* Warning: the the origin of the coordinate system in loaded file is in the upper left corner and y axis points downwards (x to right)!

**Example**
```
dem = ascii2mat("../test/input/ascii2mat_data.asc");
```
"""
function ascii2mat(filein::AbstractString)
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
