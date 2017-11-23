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

export readtsf, writetsf, loadascii, writeascii, readcampbell
export readdygraphs, writedygraphs
export loadeop
export stackframes, loadatmacs
export readggp
export readgpcpd, readgpcpd_head, readgpcpd_time, readgpcpd_lonlat, coorShift_lon

end #module
