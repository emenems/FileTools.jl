
function test_coorShift_lon()
	# convert from -180to180 to "0to360"
	lon = collect(-179.5:1:179.5);
	datain = repmat(-179.5:1:179.5,1,180);
	lonout,dataout = coorShift_lon(lon,datain,to="0to360")
	@test size(datain) == size(dataout)
	@test lonout == collect(0.5:1:359.5)
	@test dataout[1,1] == 0.5
	@test dataout[end,1] == -0.5
	@test dataout[181,2] == -179.5

	# convert from 0to360 to "-180to180" + 3D
	lon = collect(0.125:0.25:359.875);
	datain = Array{Float64}(720,length(lon),2);
	datain[:,:,1] = transpose(repmat(0.125:0.25:359.875,1,720));
	datain[:,:,2] = transpose(repmat(0.125:0.25:359.875,1,720));
	lonout,dataout = coorShift_lon(lon,datain,to="-180to180")
	@test size(datain) == size(dataout)
	@test lonout == collect(-179.875:0.25:179.875)
	@test dataout[1,1,1] == 180.125
	@test dataout[end,1,2] == 180.125
	@test dataout[2,181,1] == dataout[2,181,2]
	@test dataout[2,end,1] == 179.875
end

test_coorShift_lon()
