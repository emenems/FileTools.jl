function test_ET0calc_read()
    et_calc = ET0calc_read(joinpath(dirname(@__DIR__),"test","input","ETcalc.ETo"));
    @test et_calc[:datetime] == collect(DateTime(2016,5,1):Dates.Day(1):DateTime(2016,5,9))
    @test et_calc[:ET0] == [0.0,1.0,0.7,0.4,0.9,0.9,0.6,0.3,0.9]
end

function test_ET0calc_dsc()
    out_file = joinpath(dirname(@__DIR__),"test","output","ET0calc.DSC");
    latitude = -34.873305; # degrees
    longitude = -58.139995; # degrees
    altitude = 27.95; # meters
    utc_time = Dates.Hour(3); # will be SUBTRACTED
    wind_height = 2.; # meters
    ET0calc_dsc(out_file,name = ["LaPlata","Argentina"],
                lat = latitude,lon=longitude,H=altitude,
                from_date=DateTime(2010,1,1),to_date=DateTime(2011,2,3),
                wind_height=wind_height,allow_dev=10,
                miss_wind=3.,miss_rad=0.2,psych=0.009,
                temp_rang=[-10.,40.],humi_range=[1.0,99.],wind_range=[1.5,10.7]);
    t = readdlm(out_file)
    @test t[1,1] == "LaPlata"
    @test t[2,1] == "Argentina"
    @test t[3,1] == round(latitude*100)/100
    @test t[3,3] == "Latitude"
    @test t[4,1] == round(longitude*100)/100
    @test t[5,1] == round(altitude)
    @test t[6,1] == 1
    @test t[6,3] == "daily"
    @test t[7,1:3] == [1,1,2010]
    @test t[8,1:3] == [3,2,2011]
    @test t[9:21] == [0.009,wind_height,0.0,0.2,3.0,0.25,0.5,1,-10,40,1,round(10.7),10]
end

function test_ET0calc_dta()
    out_file = joinpath(dirname(@__DIR__),"test","output","ET0calc.DTA");
    datause = DataFrame(
            datetime=collect(DateTime(2010,1,1):Dates.Day(1):DateTime(2010,1,10)),
            Tmin = zeros(10).-5.0, Tmax = zeros(10).+40.0,
            RHmin = zeros(10).+1.0, RHmax = zeros(10).+99.0,
            ux = zeros(10).+1.0, Rn = ones(10).+30.0)
    ET0calc_dta(datause,out_file,radiation_units="W.m^-2");
    t = readdlm(out_file)
    @test t[1,2:end] == [103,101,203,201,301,432,501];
    @test t[2:end,2] == datause[:Tmin]
    @test t[2:end,3] == datause[:Tmax]
    @test t[2:end,4] == datause[:RHmin]
    @test t[2:end,5] == datause[:RHmax]
    @test t[2:end,6] == datause[:ux]
    @test t[2:end,7] == datause[:Rn]
end

test_ET0calc_read()
test_ET0calc_dsc()
test_ET0calc_dta()
