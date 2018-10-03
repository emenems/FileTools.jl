"""
    ET0calc_read(fileETo)
Read output ETo output file of EToCalc.exe
See http://www.fao.org/land-water/databases-and-software/eto-calculator/en/

**Input**
* fileETo: full file name (ETo extension)

**Output**
* datafame containing time and reference evaporanspitation

**Example**
```
et_calc = ET0calc_read(joinpath(dirname(@__DIR__),"test","input","ET0calc.ETo"));
```
"""
function ET0calc_read(filein::String)::DataFrame
    # read header
    parsehead(fi) = fi |> readline |> x-> split(x,':') |> x -> Meta.parse(x[1])
    resol,day,month,year = Dates.Day(1),1,1,1901
    open(filein,"r") do fid
        foreach(x->readline(fid),1:1)
        record_type = parsehead(fid)
        if record_type == 2
            resol = Dates.Day(10);
        elseif record_type == 3
            resol = Dates.Month(1);
        end
        day,month,year = parsehead(fid),parsehead(fid),parsehead(fid);
    end
    # read data
    temp = readdlm(filein,skipstart=8);
    return DataFrame(datetime=collect(DateTime(year,month,day):resol:DateTime(year,month,day)+(size(temp,1)-1)*resol),
                    ET0 = temp[:,1])
end


"""
    ET0calc_dsc(fileout;name,lat,lon,H,from_date,to_date,wind_height,psych,
                miss_wind,miss_rad,allow_dev,temp_range,humi_range,wind_range,
                Angstrom)
Write ET0calc input settings (dsc) file
See http://www.fao.org/land-water/databases-and-software/eto-calculator/en/

**Input**
* `fileout`: output file name
* `name`: ["Site", "Country"] vector
* `lat,lon,H`: Latitude, longitude, height (deg,deg,m)
* `from_date,to_date`: starting to end date (DateTime)
* `wind_height`: heigth of wind measurement (m)
* `psych`: coefficient psychrometer (depending on type of ventilation)
* `miss_wind`: default value for missing wind data (m/s)
* `alow_dev`: Allowable deviation (%) from theoretical maximum radiation
* `temp_range`: allowed ragne [minimum, maximum] (deg)
* `humi_range`: allowed humidity range [minimum, maximum] (%)
* `wind_range`: allowed wind speed range [minimum, maximum] (m/s)
* `Angstrom`: Adjustment for station elevation (Angstrom formula)

**Example**
```
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
```
"""
function ET0calc_dsc(fileout; name::Vector{String}=["Site","Country"],
                    lat::Float64=0.0,lon::Float64=0.0,H::Float64=0.0,
                    from_date=DateTime(2010,1,1),to_date=DateTime(2010,1,2),
                    wind_height::Float64=2.0,
                    psych::Float64=0.000800,miss_wind::Float64=2.0,
                    miss_rad::Float64=0.19,allow_dev::Int=5,
                    temp_rang=[-20.,50.],humi_range=[0.0,100.],wind_range=[0.,10],
                    Angstrom=[0.25,0.5,1])::Nothing
    open(fileout,"w") do fid
        @printf(fid,"%s\r\n%s\r\n",name[1],name[2]);
        @printf(fid,"%10.2f                   : Latitude (degrees)\r\n",lat);
        @printf(fid,"%10.2f                   : Longitude (degrees)\r\n",lon);
        @printf(fid,"%7i                      : Altitude (meters above sea level)\r\n",H);
        @printf(fid,"      1                      : daily data\r\n");
        @printf(fid,"%4i%4i%6i               : From Date (Day - Month - Year)\r\n",
                Dates.day(from_date),Dates.month(from_date),Dates.year(from_date));
        @printf(fid,"%4i%4i%6i               : To Date (Day - Month - Year)\r\n",
                Dates.day(to_date),Dates.month(to_date),Dates.year(to_date));
        @printf(fid,"%14.6f               : coefficient psychrometer (depending on type of ventilation)\r\n",psych);
        @printf(fid,"%9.1f                    : height wind speed measurement (meter)\r\n",wind_height);
        @printf(fid,"%9.1f                    : Missing air humidity data: difference between Tdew and Tmin (°C)\r\n",0.0)
        @printf(fid,"%10.2f                   : Missing radiation data: Coefficient of Hargreaves Equation (MJ/m2.day)\r\n",miss_rad);
        @printf(fid,"%9.1f                    : Missing wind speed: estimate for U2 (m/sec)\r\n",miss_wind);
        @printf(fid,"%10.2f                   : Coefficient: a Angstrom formula\r\n",Angstrom[1]);
        @printf(fid,"%10.2f                   : Coefficient: b Angstrom formula\r\n",Angstrom[2]);
        @printf(fid,"%7i                      : Option: Adjustment for station elevation (Angstrom formula)\r\n",Angstrom[3]);
        @printf(fid,"%7i                      : Climatic data range: lower limit for Minimal temperature (°C)\r\n",temp_rang[1]);
        @printf(fid,"%7i                      : Climatic data range: upper limit for Maximal temperature (°C)\r\n",temp_rang[2]);
        @printf(fid,"%7i                      : Climatic data range: lower limit for Minimal Relative Humidity (%%)\r\n",humi_range[1]);
        @printf(fid,"%7i                      : Climatic data range: upper limit for Maximal wind speed (m/sec)\r\n",wind_range[2]);
        @printf(fid,"%7i                      : Climatic data range: Allowable deviation (%%) from theoretical maximum radiation\r\n",allow_dev);
    end
end

"""
    ET0calc_dta(datawrite,filewrite;radiation_units)
Write ET0calc input data (dta) file
See http://www.fao.org/land-water/databases-and-software/eto-calculator/en/
See `test/input/ET0calc_codes.txt` for output parameter codes

**Input**
* `datawrite`: dataframe containing datetime,Tmin,Tmax(|Tmean),RHmin,RHmax(|RHmean),ux,Rn|Rs (net/solar or shortwave radiation) columns
* `filewrite`: output file name
* `radiation_units`: radiation units ("W.m^-2" or "MJ.m^-2/day")

**Example**
```
out_file = joinpath(dirname(@__DIR__),"test","output","ET0calc_out.DTA");
datause = DataFrame(
        datetime=collect(DateTime(2010,1,1):Dates.Day(1):DateTime(2010,1,10)),
        Tmin = zeros(10).-5.0, Tmax = zeros(10).+40.0,
        RHmin = zeros(10).+1.0, RHmax = zeros(10).+99.0,
        ux = zeros(10).+1.0, Rn = ones(10).+30.0)
# Optional: get minim/max values from hourly samples using ResampleAndFit Pkg
# min_data = ResampleAndFit.aggregate2(datause,resol=Dates.Day(1),fce=minimum);
# max_data = ResampleAndFit.aggregate2(datause,resol=Dates.Day(1),fce=maximum);
# mean_data = ResampleAndFit.aggregate2(datause,resol=Dates.Day(1),fce=mean);
ET0calc_dta(datause,out_file,radiation_units="W.m^-2");
```
"""
function ET0calc_dta(datawrite,filewrite;radiation_units="W.m^-2")::Nothing
    open(filewrite,"w") do fid
        ET0calc_dta_head(fid,names(datawrite),radiation_units);
        for i in 1:size(datawrite,1)
            @printf(fid,"%10i",i)
            for j in names(datawrite)
                if j != :datetime
                    @printf(fid,"%10.2f",
                        (ismissing(datawrite[j][i]) || isnan(datawrite[j][i])) ?
                        -999. : datawrite[j][i])
                end
            end
            @printf(fid,"    -999.0\r\n");
        end
    end
end

"""
Auxiliary function to write header for ET0calc DTA file
"""
function ET0calc_dta_head(fid::IOStream,col_names,radiation_units)::Nothing
    @printf(fid,"        Nr");
    for j in col_names
        if j == :Tmin
            @printf(fid,"       103")
        elseif j == :Tmax
            @printf(fid,"       101")
        elseif j == :Tmean
            @printf(fid,"       102")
        elseif j == :RHmax
            @printf(fid,"       201")
        elseif j == :RHmin
            @printf(fid,"       203")
        elseif j == :RHmean
            @printf(fid,"       202")
        elseif j == :ux
            @printf(fid,"       301")
        elseif j == :Rn
            if radiation_units == "W.m^-2"
                @printf(fid,"       432")
            else
                @printf(fid,"       431")
            end
        elseif j == :Rs
            if radiation_units == "W.m^-2"
                @printf(fid,"       422")
            else
                @printf(fid,"       421")
            end
        end
    end
    @printf(fid,"       501\r\n")
end
