using FileTools
using Test, DataFrames
using Dates
using DelimitedFiles

# List of test files. Run the test from FileTools.jl folder
tests = ["tsffile_test.jl",
		 "asciifile_test.jl",
		 "campbell_test.jl",
		 "dygraphs_test.jl",
		 "eopfile_test.jl",
		 "atmacsfile_test.jl",
		 "ggpfile_test.jl",
		 "gpcpdfile_test.jl",
		 "hydrusfile_test.jl",
		 "baytapfile_test.jl",
		 "otherfile_test.jl",
		 "dwdfile_test.jl",
		 "tidefile_test.jl",
		 "gravityeffectfile_test.jl",
		 "et0calc_test.jl"];
# Run all tests in the list
for i in tests
	include(i)
end
