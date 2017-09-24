# Unit test for loadtsf function
function test_load_tsf()
	data = loadtsf(pwd()*"/test/input/tsf_data.tsf");
	@test size(data) == (10,3)
	@test data[:datetime][1] == DateTime(2016,12,16,00,00,00)
	@test sum(data[2]) == 0.
	@test data[:Measurement1][end] == 0.
	@test data[:Measurement2][4] == 10.
	@test isnan(data[:Measurement2][5])
	units = loadtsf(pwd()*"/test/input/tsf_data.tsf",unitsonly=true);
	@test size(units) == (2,)
	@test units[1] == "units1"
	@test units[2] == "units2"
end

# Test writting
function test_write_tsf()
	data = DataFrame(temp=[10.,11.,12.,14.],grav=@data([9.8123,9.9,NaN,9.7]),
	       datetime=[DateTime(2010,1,1,0),DateTime(2010,1,1,1),
	           DateTime(2010,1,1,2),DateTime(2010,1,1,4)]);
	writetsf(data,pwd()*"/test/output/tsf_data.tsf",units=["degC","nm/s^2"],
				comment=["first line","second line"],decimal=[1,3]);
	data_read = readdlm(pwd()*"/test/output/tsf_data.tsf",skipstart=24);
	@test size(data_read) == (4,8)
	@test data_read[1,end] == 9.812
	@test data_read[2,end] == 9.9
	@test data_read[end,7] == 14.
	@test sum(data_read[3,1:6]) == 2010+1+1+2.
end

test_load_tsf()
test_write_tsf()
