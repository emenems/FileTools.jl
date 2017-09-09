# Unit test for loadtsf function
df,units = loadtsf(pwd()*"/test/input/tsf_data.tsf");
@test size(df) == (10,3)
@test size(units) == (2,)
@test sum(df[2]) == 0.
@test df[:Measurement1][end] == 0.
@test df[:Measurement2][4] == 10.
@test isna(df[:Measurement2][5])
@test units[1] == "units1"
@test units[2] == "units2"
