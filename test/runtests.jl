using FileTools
using Test
using DataFrames
using Dates
using DelimitedFiles: readdlm

# List of test files. Run the test from FileTools.jl folder
tests = ["asciifile","atmacsfile","baytapfile","campbell","dwdfile","dygraphs",
		 "eopfile","et0calc","ggpfile","gpcpdfile","gravityeffectfile",
		 "hydrusfile","otherfile","tidefile","tsffile"];
# Run all tests in the list
for i in tests
	include("$(i).jl")
end
