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

test_readggp();
