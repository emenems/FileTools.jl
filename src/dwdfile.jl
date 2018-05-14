"""
	dwdclimateraw(datein,siteid;url)
Read DWD CDC global monthly raw observations

**Input**
* datein: input date in DateTime format (can be a vector for multiple sites)
* siteid: WMO site ID, e.g. 87593 for La Plata, Argentina (one ID only)
* param: parameter to be extracted (one only), e.g. "Rx" (ftp://ftp-cdc.dwd.de/pub/CDC/observations_global/CLIMAT/monthly/raw/readme_RAW_CLIMATs_eng.txt)
* url: URL od local folder link
* downto: download temporary data to this folder (file will be deleted afterwards)

**Ouptut**
See ftp://ftp-cdc.dwd.de/pub/CDC/observations_global/CLIMAT/monthly/raw/readme_RAW_CLIMATs_eng.txt

**Example**
dwd = dwdclimateraw(DateTime(2017,10),87593,"Rx");
# Vector input
timein = collect(DateTime(2017,10):Dates.Month(1):DateTime(2017,12));
dwdvec = dwdclimateraw(timein,87593,"Rx");
"""
function dwdclimateraw(datein,siteid::Int,param::String;
	url::String="ftp://ftp-cdc.dwd.de/pub/CDC/observations_global/CLIMAT/monthly/raw/",
	downto::String="")::DataFrame
	dfo = DataFrame(datetime=datein,paramout=Dates.value.(datein).*0);
	for (i,v) in enumerate(typeof(datein)==DateTime ? [datein] : datein)
		filein = joinpath(url,@sprintf("CLIMAT_RAW_%s.txt",Dates.format(v,"yyyymm")));
		if isdir(url)
			fileout = filein;
		else
			fileout = isdir(downto) ? joinpath(downto,"dwd_month_raw_TEMP.txt") : "dwd_month_raw_TEMP.txt"
			download(filein,fileout);
		end
		d,h = readdlm(fileout,';',header=true)
		r,c = dwdclimateraw_indices(d,h,param,siteid);
		dfo[:paramout][i] = eltype(d[r,c])==Int ? d[r,c] : NA;
		!isdir(url) ? rm(fileout) : nothing
	end
	return rename!(dfo,:paramout=>Symbol(param));
end

"""
Auxiliary function to find indices of the site and parameter
"""
function dwdclimateraw_indices(datain::Array{Any,2},headerin::Array{AbstractString,2},
								paramin::String,sitein::Int)::Tuple{Int,Int}
	r,c = 1,1;
	for i in headerin
		i == paramin ? break : c += 1
	end
	for i in datain[:,3]
		i == sitein ? break : r += 1
	end
	return r,c
end
