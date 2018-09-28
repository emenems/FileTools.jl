# Unit test for Campbell Scientific logger file reading
function test_load_campbell()
	data,units = readcampbell("test/input/campbell_data.dat");
	@test size(data) == (5,5)
	@test size(units) == (4,)
	@test data[:datetime][1] == DateTime(2008,07,15,16,15,00)
	@test sum(data[:Val1]) == 0.5
	@test data[:Val3][end] == 0.3
	@test units[1] == "RN"
	@test units[2] == "unit1"
	@test units[end] == "unit3"
end

test_load_campbell();
