# Unit test for arc ascii grid file reading
dem = ascii2mat(pwd()*"/test/input/ascii2mat_data.asc");
@test size(dem[:height]) == (6,4)
@test size(dem[:x]) == (4,)
@test size(dem[:y]) == (6,)
@test find(isnan,dem[:height]) == [5,6,12,19]
@test dem[:x][1] == 25.
@test dem[:y][end] == 275.
@test dem[:x][1] - dem[:x][2] ≈ -50.
@test dem[:y][3] - dem[:y][2] ≈ 50.
