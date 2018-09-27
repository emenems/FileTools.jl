function writebaytap_test()
	timeout = collect(DateTime(2010,1,1,0):Dates.Hour(1):DateTime(2010,1,1,13));
	gravout = ones(Float64,length(timeout));
	gravout[[3,end]] .= NaN;
	gravout[[4,7]] .= 10.123;
	dataout = DataFrame(datetime=timeout, grav=gravout);
	output_file = pwd()*"/test/output/baytap_dataseries.txt";
	writebaytap(dataout,:grav,(14.123,45.888,100.0,982.024), # position+mean gravity
				output_file,header="writebaytap unit test");

	# check manually
	open(output_file,"r") do fid
		@test readline(fid) == "writebaytap unit test"
		@test readline(fid) == "  14.12300  45.88800    100.00  982.0240"
		@test readline(fid) == " 2010    1    1   0.00000"
		@test readline(fid) == "   14    1   9000.D0"
		@test readline(fid) == "(6F10.2)"
		@test readline(fid) == "      1.00      1.00   9999.99     10.12      1.00      1.00"
		@test readline(fid) == "     10.12      1.00      1.00      1.00      1.00      1.00"
		@test readline(fid) == "      1.00   9999.99"
		@test eof(fid)
	end
end

function baytap2tsoft_test()
	file_results = pwd()*"/test/input/baytap08.out";
	file_output = pwd()*"/test/output/baytap2tsoft.txt"
	isfile(file_output) ? rm(file_output) : nothing
	baytap2tsoft(file_results,file_output,site="Cantlay",name="test");
	@test isfile(file_output)
end

writebaytap_test();
baytap2tsoft_test();
