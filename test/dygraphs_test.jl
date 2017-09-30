# Unit test for Dygraphs file reading
function test_load_dygraphs()
	data = readdygraphs(pwd()*"/test/input/dygraphs_data.csv",datestring="yyyymmdd");
	@test size(data) == (10,3)
	@test names(data)==[:datetime,:High,:Low]
	@test data[:datetime][1] == DateTime(2007,01,01,00,00,00)
	@test sum(data[:High]) == 600.
	@test data[:Low][end] == 37.
end

# Test writting
function test_write_dygraphs()
	data = DataFrame(temp=[10.,11.,12.,14.],grav=@data([9.8123,9.9,NaN,9.7]),
	       datetime=[DateTime(2010,1,1,0),DateTime(2010,1,1,1),
	           DateTime(2010,1,1,2),DateTime(2010,1,1,4)]);
	writedygraphs(data,pwd()*"/test/output/dygraphs_data.csv",decimal=[1,3]);
	data_read = readdlm(pwd()*"/test/output/dygraphs_data.csv",',',skipstart=1);
	@test size(data_read) == (4,3)
	@test data_read[1,1] == "2010/01/01 00:00:00"
	@test data_read[2,end] == 9.9
	@test data_read[end,2] == 14
end

test_load_dygraphs();
test_write_dygraphs();
