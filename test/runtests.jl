using FileTools
using Base.Test, DataFrames

# List of test files. Run the test from FileTools.jl folder
tests = ["loadtsf_test.jl"]
# Run all tests in the list
for i in tests
	include(i)
end
println("End test!")
