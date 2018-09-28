function vav2tsoft_test()
	file_vav = "test/input/vav_analysis.dat";
	file_tsoft = pwd()*"/test/output/vav2tsoft.txt"
	isfile(file_tsoft) ? rm(file_tsoft) : nothing
	vav2tsoft(file_vav,file_tsoft,site="Cantlay",name="test");
	@test isfile(file_tsoft)
end

function eterna2tsoft_test()
	file_eterna = "test/input/eterna_analysis.prn";
	file_tsoft = pwd()*"/test/output/eterna2tsoft.txt"
	isfile(file_tsoft) ? rm(file_tsoft) : nothing
	eterna2tsoft(file_eterna,file_tsoft,site="Cantlay",name="test");
	@test isfile(file_tsoft)
end

vav2tsoft_test();
eterna2tsoft_test();
