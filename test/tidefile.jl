@testset "Tide files (vav & eterna)" begin
	file_vav = joinpath(dirname(@__DIR__),"test","input","vav_analysis.dat");
	file_tsoft = joinpath(dirname(@__DIR__),"test","output","vav2tsoft.txt");
	isfile(file_tsoft) ? rm(file_tsoft) : nothing
	vav2tsoft(file_vav,file_tsoft,site="Cantlay",name="test");
	@test isfile(file_tsoft)
	file_eterna = joinpath(dirname(@__DIR__),"test","input","eterna_analysis.prn");
	file_tsoft = joinpath(dirname(@__DIR__),"test","output","eterna2tsoft.txt")
	isfile(file_tsoft) ? rm(file_tsoft) : nothing
	eterna2tsoft(file_eterna,file_tsoft,site="Cantlay",name="test");
	@test isfile(file_tsoft)
end
