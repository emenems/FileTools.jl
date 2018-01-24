using FileTools
using Base.Test, DataFrames

# List of test files. Run the test from FileTools.jl folder
tests = ["tsffile_test.jl",
		 "asciifile_test.jl",
		 "campbell_test.jl",
		 "dygraphs_test.jl",
		 "eopfile_test.jl",
		 "atmacsfile_test.jl",
		 "ggpfile_test.jl",
		 "gpcpdfile_test.jl",
		 "hydrusfile_test.jl"];
# Run all tests in the list
for i in tests
	include(i)
end
println("End test!")
