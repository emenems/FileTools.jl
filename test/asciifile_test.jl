# Unit test for arc ascii grid file reading
function test_load_asc()
	dem = loadascii(pwd()*"/test/input/ascii_data.asc");
	@test size(dem[:height]) == (6,4)
	@test size(dem[:x]) == (4,)
	@test size(dem[:y]) == (6,)
	@test isnan(dem[:height][5])
	@test isnan(dem[:height][6])
	@test isnan(dem[:height][12])
	@test isnan(dem[:height][19])
	@test !isnan(dem[:height][1])
	@test !isnan(dem[:height][4])
	@test dem[:x][1] == 25.
	@test dem[:y][end] == 275.
	@test dem[:x][1] - dem[:x][2] ≈ -50.
	@test dem[:y][3] - dem[:y][2] ≈ 50.
end

# Unit test for arc ascii grid file writting
function test_write_asc()
	# prepare output data
	dem = Dict(:x => collect(1:1:10.),:y => collect(10:1:20.),
	       	   :height => ones(Float64,10,11));
   	dem[:height][1,2] = NaN;
	dem[:height][2,3] = 0.00049;
	# write
	writeascii(dem,pwd()*"/test/output/ascii_data.asc",flag="8888",decimal=3);
	# independent read
	data = readdlm(pwd()*"/test/output/ascii_data.asc", skipstart=6);
	# check data
	@test size(data) == (10,11)
	@test data[1,1] == 1.
	@test data[end,2] == 8888. # has been fliped upside down and converted to flag value
	@test data[end-1,3] == 0. # has been rounded to 3 dec. places
	# check header
	open(pwd()*"/test/output/ascii_data.asc","r") do fid
		count_header = 0;
		for i = 1:6
			row = readline(fid);
			temp = split(row," ");
			if occursin("ncols",lowercase(row))
				count_header += 1;
				@test temp[end] == "11";
			elseif occursin("nrows",lowercase(row))
				count_header += 1;
				@test temp[end] == "10";
			elseif occursin("xll",lowercase(row))
				count_header += 1;
				@test temp[end] == "0.5"
			elseif occursin("yll",lowercase(row))
				count_header += 1;
				@test temp[end] == "9.5"
			elseif occursin("cellsize",lowercase(row))
				count_header += 1;
				@test temp[end] == "1"
			elseif occursin("nodata",lowercase(row))
				count_header += 1;
				@test temp[end] == "8888"
			end
		end
		if count_header != 6
			error("ascii header not written correctly!");
		end
	end
end
test_load_asc();
test_write_asc();
