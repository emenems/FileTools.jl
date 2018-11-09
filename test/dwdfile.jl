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

@testset "CDO daily data" begin
	file_in = joinpath(dirname(@__DIR__),"test","input","nndc_climate_cdo.txt");
	df = readgssd(file_in);
	@test names(df) == [:STN,:WBAN,:YEARMODA,:TEMP,:Count_TEMP,:DEWP,:Count_DEWP,
						:SLP,:Count_SLP,:STP,:Count_STP,:VISIB,:Count_VISIB,
						:WDSP,:Count_WDSP,:MXSPD,:GUST,:MAX,:Flag_MAX,:MIN,
						:Flag_MIN,:PRCP,:Flag_PRCP,:SNDP,:FRSHTT];
	x = [875760 99999 20160101 74.3 24 67.9 24 1011.3 6 1009.0 6 5.5 24 4.9 24 12.0 999.9 86.9 " " 66.2 "*" 0.20 "G" 999.9 010010;
	 	 875760 99999 20160102 78.6 24 66.9 24 1013.3 8 1011.0 8 6.2 18 7.9 24 18.1 999.9 87.8 "*" 67.1 " " 0.59 "G" 999.9 000000;
	 	 875760 99999 20160103 78.4 24 68.4 24 1013.0 8 1010.7 8 6.2 18 8.0 24 13.0 999.9 89.4 " " 74.5 " " 0.00 "G" 999.9 000000];
    for i in 1:ncol(df)
		@test df[i] == x[:,i]
	end

	df[:PRCP][2] = 99.99;
	dfc = convertgssd(df);
	@test names(dfc) == [:datetime,:TEMP,:DEWP,:MAX,:MIN,:WDSP,:MXSPD,:PRCP,:STP]
	@test dfc[:datetime] == [DateTime(2016,1,1),DateTime(2016,1,2),DateTime(2016,1,3)]
	s = DataFrame(TEMP = [23.5,25.88889,25.77778], DEWP = (x[:,6].-32)./1.8,
					WDSP = x[:,14]./10.0.*0.514444444444, STP = df[:STP],
					PRCP = x[:,end-3]*2.54*10.0);
	for i in names(s)
		if i != :PRCP
			@test isapprox(dfc[i],s[i], atol=1e-3);
		else
			@test isapprox(dfc[i][1],s[i][1],atol=1e-2)
			@test isapprox(dfc[i][3],s[i][3],atol=1e-2)
			@test isnan(dfc[i][2])
		end
	end
end
