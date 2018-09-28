# Unit test for Hydrus1D ATMOSPH.IN
function test_writeatmosph()
	data = DataFrame(Prec=[0.01,0.1,0.2,0.3],rSoil=[0.0,0.1,0.2,0.9],
		   datetime=[DateTime(2010,1,1,0),DateTime(2010,1,1,1),
			   DateTime(2010,1,1,2),DateTime(2010,1,1,4)],
			   hCritA=[1,1,1,1]);
	writeatmosph(data,joinpath(dirname(@__DIR__),"test","output","atmosph_data.in"),
				decimal=[1],
				hCritS=1000.);
	# Read header
	open(joinpath(dirname(@__DIR__),"test","output","atmosph_data.in")) do fid
		row = " ";
		for i in 1:4
			row = readline(fid);
		end
		@test Meta.parse(row) == 4
		for i in 1:3
			row = readline(fid);
		end
		hcrits = fid |> readline |> Meta.parse
		@test hcrits == 1000
	end
	data_read = readdlm(joinpath(dirname(@__DIR__),"test","output","atmosph_data.in"),skipstart=9);
	@test size(data_read) == (5,8)
	@test data_read[1:4,1:8] == [1 0   0   0 1 0 0 0;
							     2 0.1 0.1 0 1 0 0 0;
							     3 0.2 0.2 0 1 0 0 0;
							     4 0.3 0.9 0 1 0 0 0];
end

# unit test for Hydrus1D profile info
function test_writeprofile1d()
	# write data
	soilinfo = DataFrame(start=[0.0,4.2],stop=[4.0,6],res=[0.5,0.2],h=[100,200],Mat=[1,2],Lay=[1,1])
	output_file = joinpath(dirname(@__DIR__),"test","output","profile1d_data.dat");
	print_nodes = [5,7,9];
	writeprofile1d(soilinfo,output_file,iObs=print_nodes);
	# check file
	t = readdlm(output_file);
	for i in 5:23
		@test t[i,1] == i-4
		@test t[i,5:9] == [1,0.0,1.0,1.0,1.0]
		if t[i,2]>-soilinfo[:start][2]
			@test t[i,3] == soilinfo[:h][1]
			@test t[i,4] == soilinfo[:Mat][1]
		else
			@test t[i,3] == soilinfo[:h][2]
			@test t[i,4] == soilinfo[:Mat][2]
		end
	end
	@test t[24,1] == length(print_nodes)
	@test t[end,1:3] == print_nodes
end

# unit test for Hydrus1D observation nodes output
function test_readhydrus1d_obsnode()
	input_file = joinpath(dirname(@__DIR__),"test","input","hydrus1d_Obs_Node.out")
	# Theta/soil moisture
	ttest = readhydrus1d_obsnode(input_file,paramout=:theta)
	@test ttest[:time] == collect(1:1:12)
	@test size(ttest) == (12,11)
	@test ttest[:theta1] == [0.1676,0.1759,0.1809,0.1852,0.1882,0.191,0.1935,0.1955,0.1973,0.1991,0.2008,0.2024];
	@test ttest[:theta30] == [0.136,0.136,0.136,0.136,0.136,0.136,0.1361,0.1365,0.1372,0.1386,0.1407,0.1437];
	@test ttest[:theta1000] == [0.136,0.136,0.136,0.136,0.136,0.136,0.136,0.136,0.136,0.136,0.136,0.136];

	# h
	ttest = readhydrus1d_obsnode(input_file,paramout=:h)
	@test ttest[:time] == collect(1:1:12)
	@test size(ttest) == (12,11)
	@test ttest[:h1] == [-16.82,-13.47,-11.87,-10.73,-9.98,-9.37,-8.9,-8.51,-8.16,-7.84,-7.57,-7.35];
	@test ttest[:h30] == [-50,-50,-50,-50,-49.98,-49.9,-49.67,-49.07,-47.7,-45.12,-41.29,-36.7];
	@test ttest[:h1000] == [-50,-50,-50,-50,-50,-50,-50,-50,-50,-50,-50,-50];

	# flux
	ttest = readhydrus1d_obsnode(input_file,paramout=:Flux)
	@test ttest[:time] == collect(1:1:12)
	@test size(ttest) == (12,11)
	@test ttest[:Flux1] == [-1.00E-03,-1.00E-03,-1.00E-03,-1.00E-03,-1.00E-03,-1.00E-03,-1.00E-03,-1.00E-03,-1.00E-03,-1.00E-03,-1.00E-03,-1.00E-03];
	@test ttest[:Flux30] == [-1.51E-07,-1.51E-07,-1.55E-07,-1.80E-07,-2.94E-07,-8.74E-07,-2.47E-06,-7.15E-06,-1.78E-05,-3.82E-05,-6.93E-05,-1.12E-04];
	@test ttest[:Flux1000] == [-1.51E-07,-1.51E-07,-1.51E-07,-1.51E-07,-1.51E-07,-1.51E-07,-1.51E-07,-1.51E-07,-1.51E-07,-1.51E-07,-1.51E-07,-1.51E-07];

end


# unit test for Hydrus1D all nodes output
function test_readhydrus1d_nodinf()
	input_file = joinpath(dirname(@__DIR__),"test","input","hydrus1d_Nod_Inf.out");
	# soil moisture only
	ttest = readhydrus1d_nodinf(input_file,paramout=:theta)
	@test ttest[:time] == collect(0.:1.:3)
	@test size(ttest) == (4,11)
	@test ttest[:node1] == [0.1360,0.1676,0.1759,0.1809]
	@test ttest[:node3] == [0.1360,0.1569,0.1684,0.1751]
	@test ttest[:node10] == [0.1360,0.1362,0.1400,0.1486]

	# all
	moisture,k,h = readhydrus1d_nodinf(input_file)
	@test moisture[:time] == collect(0.:1.:3)
	@test k[:time] == collect(0.:1.:3)
	@test h[:time] == collect(0.:1.:3)
	@test size(moisture) == (4,11)
	@test size(k) == (4,11)
	@test size(h) == (4,11)
	@test moisture[:node1] == [0.1360,0.1676,0.1759,0.1809]
	@test moisture[:node3] == [0.1360,0.1569,0.1684,0.1751]
	@test moisture[:node10] == [0.1360,0.1362,0.1400,0.1486]
	@test k[:node1] == [0.1511E-06,0.4351E-05,0.8321E-05,0.1234E-04]
	@test k[:node3] == [0.1511E-06,0.1621E-05,0.4484E-05,0.8037E-05]
	@test k[:node10] == [0.1511E-06,0.1570E-06,0.2626E-06,0.6815E-06]
	@test h[:node1] == [-50.000,-16.820,-13.468,-11.867]
	@test h[:node3] == [-50.000,-23.178,-16.446,-13.780]
	@test h[:node10] == [-50.000,-49.480,-42.537,-30.490]
end

function test_readatmosph()
	input_file = joinpath(dirname(@__DIR__),"test","input","hydrus1d_atmosph.in");
	ttest = readatmosph(input_file)
	@test ttest[:time] == collect(1.:1.:11)
	@test size(ttest) == (11,9)
	@test ttest[:Prec] == [0.,0.,0.,0.,0.02,0.,0.,0.,0.,0.,0.]
	@test ttest[:rSoil] == [0.,0.,0.,0.001,0.,0.,0.,0.,0.,0.,0.]
	@test ttest[:ht] == zeros(11)
	@test all(isnan.(ttest[:RootDepth]))
end


test_writeatmosph();
test_readatmosph();
test_writeprofile1d();
test_readhydrus1d_obsnode();
test_readhydrus1d_nodinf();
