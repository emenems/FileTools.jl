function test_writecorrpar()
	corrpar = DataFrame(column=[1,2,3], id = [3,2,1],
						x1 = [DateTime(2010,01,01,04,30,00),
							  DateTime(2010,01,01,08,00,00),
							  DateTime(2010,01,02,04,00,00)],
					  	x2 = [DateTime(2010,01,01,07,30,00),
							  DateTime(2010,01,01,09,30,09),
							  DateTime(2010,01,02,06,30,00)],
						y1 = [NaN,NaN,10.],y2 = [NaN,NaN,0.0],
						comment = ["first", "second", "third"]);
	fileout = pwd()*"/test/output/writecorrpar_out.txt";
	FileTools.writecorrpar(corrpar,fileout,decimal=1)
	t = readdlm(fileout,comments=true,comment_char='%');
	@test t[:,1] == [3,2,1]
	@test t[:,2] == [1,2,3]
	@test t[:,3] == repeat([2010],3)
	@test t[:,4] == repeat([1],3)
	@test t[:,5] == [1,1,2];
	@test t[:,6] == [4,8,4];
	@test t[:,7] == [30,0,0];
	@test t[:,8] == [0,0,0];
	@test t[:,9] == repeat([2010],3)
	@test t[:,10] == repeat([1],3)
	@test t[:,11] == [1,1,2];
	@test t[:,12] == [7,9,6];
	@test t[:,13] == [30,30,30];
	@test t[:,14] == [0,9,0];
	for i in 1:2
		for j in 15:16
			@test isnan(t[i,j])
		end
	end
	@test t[3,15] == 10.;
	@test t[3,16] == 0.;
	@test t[:,17] == convert(Vector{String},corrpar[:comment]);
	# Return for next test
	return corrpar,fileout
end

function test_readcorrpar()
	corrpar,fileout = test_writecorrpar();
	corrpar_read = FileTools.readcorrpar(fileout)
	for i in names(corrpar)
		if i != :y1 && i != :y2
			@test corrpar_read[i] == corrpar[i]
		end
	end
	@test all(isnan.(corrpar_read[:y1][1:2]))
	@test all(isnan.(corrpar_read[:y2][1:2]))
	@test corrpar_read[:y1][3] == corrpar[:y1][3]
	@test corrpar_read[:y2][3] == corrpar[:y2][3]
end

test_writecorrpar();
test_readcorrpar();
