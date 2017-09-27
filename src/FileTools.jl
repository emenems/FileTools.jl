module FileTools

using DataFrames

include("tsffile.jl")
include("asciifile.jl")
include("campbellfile.jl")
include("dygraphsfile.jl")
include("eopfile.jl")
include("atmacsfile.jl")

export loadtsf, writetsf, loadascii, writeascii, loadcampbell
export loaddygraphs, writedygraphs
export loadeop
export stackframes, loadatmacs

end #module
