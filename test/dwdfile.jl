@testset "DWD climate raw" begin
	temp_out = joinpath(dirname(@__DIR__),"test","output","temp_dwdclimateraw.txt");
	temp_in = joinpath(dirname(@__DIR__),"test","input")
	dwd = dwdclimateraw(DateTime(2012,04),67890,"P",downto=temp_out,
						url=temp_in);
	@test dwd[:datetime][end] == DateTime(2012,04)
	@test dwd[:P][1] == 63
	@test size(dwd) == (1,2)

	timein = collect(DateTime(2012,04):Dates.Month(1):DateTime(2012,05));
	dwdvec = dwdclimateraw(timein,12345,"Po",downto=temp_out,
						url=temp_in);
	@test dwdvec[:datetime] == timein
	@test dwdvec[:Po] == [0,22222]
end
