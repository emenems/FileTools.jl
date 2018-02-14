module FileTools

using DataFrames

include("tsffile.jl")
include("asciifile.jl")
include("campbellfile.jl")
include("dygraphsfile.jl")
include("eopfile.jl")
include("atmacsfile.jl")
include("ggpfile.jl")
include("gpcpdfile.jl")
include("hydrusfile.jl")
include("baytapfile.jl")
include("igetsfile.jl")

export readtsf, writetsf, loadascii, writeascii, readcampbell
export readdygraphs, writedygraphs
export loadeop
export stackframes, loadatmacs
export readggp, writeggp, ggpdata2blocks
export readgpcpd, readgpcpd_head, readgpcpd_time, readgpcpd_lonlat, coorShift_lon
export writeatmosph, writeprofile1d, readhydrus1d_obsnode, readhydrus1d_nodinf
export writebaytap, baytap2tsoft
export igetsimport

end #module
