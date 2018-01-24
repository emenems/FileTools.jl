# Unit test for Hydrus1D ATMOSPH.IN
function test_writeatmosph()
	data = DataFrame(Prec=[0.01,0.1,0.2,0.3],rSoil=@data([0.0,0.1,0.2,0.9]),
		   datetime=[DateTime(2010,1,1,0),DateTime(2010,1,1,1),
			   DateTime(2010,1,1,2),DateTime(2010,1,1,4)],
			   hCritA=[1,1,1,1]);
	writeatmosph(data,pwd()*"/test/output/atmosph_data.in",
				decimal=[1],
				hCritS=1000.);
	# Read header
	open(pwd()*"/test/output/atmosph_data.in") do fid
		row = " ";
		for i in 1:4
			row = readline(fid);
		end
		@test parse(row) == 4
		row = readline(fid);
		hcrits = fid |> readline |> parse
		@test hcrits == 1000
	end
	data_read = readdlm(pwd()*"/test/output/atmosph_data.in",skipstart=7);
	@test size(data_read) == (5,8)
	@test data_read[1:4,1:8] == [1 0   0   0 1 0 0 0;
							     2 0.1 0.1 0 1 0 0 0;
							     3 0.2 0.2 0 1 0 0 0;
							     4 0.3 0.9 0 1 0 0 0];
end

test_writeatmosph();
