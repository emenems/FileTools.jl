# Unit test for EOP C04 file reading
@testset "EOP C04 file reading" begin
	data = loadeop(joinpath(dirname(@__DIR__),"test","input","eop_data.c04"));
	@test size(data) == (11,14)
	@test data[:datetime][1] == DateTime(1962,1,1)
	@test data[:datetime][end] == DateTime(1962,1,11)
	@test sum(data[:x]) ≈ -0.297387
	@test data[:dYErr][end] ≈ 0.002000
end
