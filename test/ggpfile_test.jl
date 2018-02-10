# Unit test for GGP file reading
function test_readggp()
	# Simple data loading
	ggp1 = readggp(pwd()*"/test/input/readggp_data.ggp",nanval=9999.999)
	@test ggp1[:datetime][1] == DateTime(2017,08,26)
	@test ggp1[:datetime][end] == DateTime(2017,09,03,4,0,0)
	for i in [9,10,12]
		@test isnan(ggp1[:column2][i])
	end
	@test sum(ggp1[:column1]) ≈ 5.
	@test sum(filter(!isnan,ggp1[:column2])) ≈ 20.

	# Apply offset while loading data
	ggp2 = readggp(pwd()*"/test/input/readggp_data.ggp",
		nanval=9999.999,offset=true)
	@test ggp2[:datetime][1] == DateTime(2017,08,26)
	@test ggp2[:datetime][end] == DateTime(2017,09,03,4,0,0)
	for i in [9,10,12]
		@test isnan(ggp2[:column2][i])
	end
	@test sum(ggp2[:column1]) ≈ 55.
	@test sum(filter(!isnan,ggp2[:column2])) ≈ 100.

	# Read header only
	ggphead = readggp(pwd()*"/test/input/readggp_data.ggp",
		what="header")
	@test size(ggphead) == (2,)

	# Read EOSTloading (Pre)ETERNA file
	ggp3 = readggp(pwd()*"/test/input/eost_data.rot")
	@test names(ggp3) == [:datetime,:column1,:column2,:column3,:column4,:column5]
	ggp3m = readdlm(pwd()*"/test/input/eost_data.rot",skipstart=14)
	ggp3m = ggp3m[1:end-1,:];
	@test ggp3[:datetime] == DateTime.(string.(ggp3m[:,1]),"yyyymmdd")
	for i in 3:size(ggp3m,2)
		@test sum(ggp3[Symbol("column",i-2)]) ≈ sum(ggp3m[:,i])
	end

	# Read blockinfor
	blockinfo = readggp(pwd()*"/test/input/eost_data.rot",what="blocks")
	@test blockinfo[:datetime][1] == DateTime(string(ggp3m[1,1]),"yyyymmdd")
	@test blockinfo[:startline][1] == 15
	@test blockinfo[:stopline][1] == size(ggp3m,1)+15-1 # header - 999999 line
	@test size(blockinfo) == (1,size(ggp3m,2)+1)
end

# write ggp
function test_writeggp()
	dataout = DataFrame(pres=collect(1000.12345:1:1011.123456),
	       				datetime=collect(DateTime(2010,1,1):Dates.Hour(1):DateTime(2010,1,1,11)));
	# try writtin without optional parameters
	writeggp(dataout,pwd()*"/test/output/ggp_data_one.dat");
	# read and test
	d = readdlm(pwd()*"/test/output/ggp_data_one.dat",skipstart=3)
	for i = 1:12
		@test d[i,1] == 20100101
		@test d[i,3] ≈ round(dataout[:pres][i]*100)/100
		@test d[i,2] ≈ (i-1)*1e+4
	end
	@test d[end,1] == 99999999

	# Try full output
	dataout[:grav] =collect(900.123456:-3:(900.123456-11*3));
	# set units using the same keywords as in the dataframe
	units = Dict(:grav=>"V",:pres=>"hPa")
	# Set header. All entries with the excetpion of "freetext" will be formatted
	header = Dict("Filename"=>"file.data",
	              "Station"=>"Wettzell",
	              "Instrument"=>"iGrav",
	              "N. Latitude (deg)"=>49.14354,
	              "E. Longitude (deg)"=>12.87866,
	              "Elevation MSL (m)"=>613.7+1.05,
	              "Author"=>"Name (name@gfz-potsdam.de)",
				  "freetext"=>"Line without formatting\nMaximum 80 characters per line");
	block = Dict("start"=>[DateTime(2010,1,1,09,0,0)],
				"offset"=>[10.1234 20.1234], # one row per block. 2 values per row = number channels
	            "header"=>["iGrav006" 1.0 1.0 0.0 3])
	fileout = pwd()*"/test/output/ggp_data_two.dat";
	writeggp(dataout,fileout,
				units=units,header=header,decimal=[1,3],
				blockinfo=block,channels=[:grav,:pres])
	# test
	open(fileout,"r") do fid
		row = ""
		for i in 1:10
			row = readline(fid);
		end
		@test row == "yyyymmdd hhmmss grav(V) pres(hPa)";
	end
	b = readdlm(fileout,skipstart=12)
	@test b[1,1] == 77777777
	@test b[2,1] == 20100101
	@test b[end-1,1] == 20100101
	@test b[end-1,2] == 110000
	@test b[3,2] == 010000
	@test b[3,3] ≈ round(dataout[:grav][2]*10)/10
	@test b[end-2,4] ≈ round(dataout[:pres][end-1]*1000)/1000
	@test b[end-4,2] ≈ round(block["offset"][1]*10)/10
	@test b[end-4,3] ≈ round(block["offset"][2]*1000)/1000
	@test b[end-5,1] == block["header"][1]
	@test b[end-5,2:end] == block["header"][2:end]
end

function test_ggpdata2blocks()
	datawrite = DataFrame(pres=collect(1000.:1:1011.),
					grav=collect(900.:-3:(900.-11*3)),
					datetime=collect(DateTime(2010,1,1):Dates.Hour(1):DateTime(2010,1,1,11)));
	datawrite[:grav][[3,6]] = NaN;
	datawrite[:pres][7] = NaN;
	dataout,block = ggpdata2blocks(datawrite;channels=[])
	@test filter(!isnan,datawrite[:grav]+datawrite[:pres]) ≈ dataout[:grav]+dataout[:pres]
	@test block["start"] == datawrite[:datetime][[3,6]]
	@test block["offset"] == zeros(Float64,2,2)

	#
	dataout2,block2 = ggpdata2blocks(dataout;channels=[:pres])
	@test dataout2[:datetime] == dataout[:datetime]
	@test dataout2[:pres] == dataout[:pres]
	@test !haskey(dataout2,:grav)
	@test isempty(block2)
end

test_readggp();
test_writeggp();
test_ggpdata2blocks();
