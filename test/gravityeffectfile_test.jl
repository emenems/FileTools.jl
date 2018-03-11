function test_write_layerResponse()
	sensor=Dict(:x => 100., :y => 150., :z => 100., :sensHeight => 1.0)
	layers=Dict(:start => [0.0, 1.0],:stop  => [1.0, 2.0])
	dem_in = "test/input/dem_data.asc";
	zones =Dict(:dem   => [dem_in,dem_in], :radius=> [50.,200.],
				:resolution => [0.1,0.2],:interpAltitude => [true,false]);
	exclude = Dict(:cylinder=>Dict(:radius=>1.,:start=>0.5,:stop=>2.),
			   :prism=>Dict(:x=>[100.,106.],:y=>[155.,156.],
							:dx=>[2.,3.],:dy=>[1.5,1.8],
							:start=>[0.,1.],:stop=>[1.,2.]),
			   :polygon=>Dict(:file=>"/test/input/exclusion_polygon.txt",
							  :start=>0.,:stop=>2.))
	outputfile = pwd()*"/test/output/write_layerResponse.txt";
	#outdata = GravityEffect.layerResponse(sensor,layers,zones,
	#					exclude=exclude,nanheight=true,
	#					outfile=outputfile,def_density=10.);
	outdata = DataFrame(layer=[1,2],start=layers[:start],stop=layers[:stop],
	 		   	   total=[3.82615,3.76013].*1e-9,zone1=[3.76682,3.66139].*1e-9,
				   zone2=[0.05933,0.09874].*1e-9);
    FileTools.write_layerResponse(sensor,layers,zones,exclude,false,
			   		    outputfile,10.,outdata);
	t = readdlm(outputfile,comment_char='%');
	@test size(t) == (2,6)
	@test all(isapprox.(t[:,4],outdata[:total].*1e+9))
	@test all(isapprox.(t[:,5],outdata[:zone1].*1e+9))
	@test all(isapprox.(t[:,6],outdata[:zone2].*1e+9))
	@test t[:,1]==[1.,2.]
	@test t[:,2]==layers[:start]
	@test t[:,3]==layers[:stop]
end

function test_read_layerResponse()
	filein = pwd()*"/test/input/read_layerResponse.txt";
	t = read_layerResponse(filein,"results")
	@test t[:,1]==[1.,2.]
	@test t[:,2]==[0.,1.]
	@test t[:,3]==[1.,2.]
	@test t[:,4]==[4.,3.]
	@test t[:,5]==[3.1,2.2]
	@test t[:,6]==[0.9,0.8]

	t = read_layerResponse(filein,"layers")
	@test t == Dict(:start => [0.0, 1.0],:stop  => [1.0, 2.0])
	t = read_layerResponse(filein,"sensor")
	@test t == Dict(:x => 100., :y => 150., :z => 100., :sensHeight => 1.0)
	t = read_layerResponse(filein,"def_density")
	@test t == 10.
	t = read_layerResponse(filein,"nanheight")
	@test !t

	dem_in = "test/input/dem_data.asc";
	zones =Dict(:dem   => [dem_in,dem_in], :radius=> [50.,200.],
				:resolution => [0.1,0.2],:interpAltitude => [true,false]);
	t = read_layerResponse(filein,"zones")
	@test t == zones

	exclude = Dict(:cylinder=>Dict(:radius=>1.,:start=>0.5,:stop=>2.),
			   :prism=>Dict(:x=>[100.,106.],:y=>[155.,156.],
							:dx=>[2.,3.],:dy=>[1.5,1.8],
							:start=>[0.,1.],:stop=>[1.,2.]),
			   :polygon=>Dict(:file=>"/test/input/exclusion_polygon.txt",
							  :start=>0.,:stop=>2.))
	t = read_layerResponse(filein,"exclude")
	@test t == exclude
end

test_write_layerResponse();
test_read_layerResponse();
