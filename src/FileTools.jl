module FileTools

using DataFrames

include("tsffile.jl")
include("asciifile.jl")

export loadtsf, writetsf, loadascii, writeascii

end #module
