# Unit test for Atmacs file reading
function test_stackframes()
	# First set (with overlapping)
	f1 = DataFrame(datetime=[DateTime(2010,1,1,0),DateTime(2010,1,1,1),
	           DateTime(2010,1,1,2),DateTime(2010,1,1,3)],
			   grav=[10.,11.,12.,13.]);
	f2 = DataFrame(datetime=[DateTime(2010,1,1,2),DateTime(2010,1,1,3),
	           DateTime(2010,1,1,4),DateTime(2010,1,1,5)],
			   grav=[22.,23.,24.,25.]);
	data = stackframes(f1,f2,maxtime=Dates.Hour(1),maxval=NaN,corroffset=true);
	@test size(data) == (6,2)
	@test names(data)==[:datetime,:grav]
	@test data[:datetime][3] == f1[:datetime][3]
	@test data[:datetime][4] == f2[:datetime][2]
	@test data[:datetime][end] == f2[:datetime][end]
	@test data[:grav] == [10.,11.,12.,13.,14.,15];

	# Same as above but without offset correction
	data = stackframes(f1,f2,maxtime=Dates.Hour(1),maxval=NaN,corroffset=false);
	@test size(data) == (6,2)
	@test names(data)==[:datetime,:grav]
	@test data[:datetime][3] == f1[:datetime][3]
	@test data[:datetime][4] == f2[:datetime][2]
	@test data[:datetime][end] == f2[:datetime][end]
	@test data[:grav] == [10.,11.,12.,13.,24.,25];

	# Same as above but without offset > as allowed threshold => not stacked
	data = stackframes(f1,f2,maxtime=Dates.Hour(1),maxval=1.,corroffset=true);
	@test size(data) == (4,2)
	@test names(data)==[:datetime,:grav]
	@test data[:datetime] == f1[:datetime]
	@test data[:grav] == data[:grav];

	# No overlapping but within maximum time stap
	f2 = DataFrame(datetime=[DateTime(2010,1,1,6),DateTime(2010,1,1,7),
		DateTime(2010,1,1,8),DateTime(2010,1,1,9)],
		grav=[22.,23.,24.,25.]);
	data = stackframes(f1,f2,maxtime=Dates.Hour(3),maxval=NaN,corroffset=false);
	@test size(data) == (size(f2,1)+size(f1,1)+1,2)
	@test names(data)==[:datetime,:grav]
	@test data[:datetime][4] == f1[:datetime][end]
	@test data[:datetime][5] == f1[:datetime][end]+(f1[:datetime][end]-f1[:datetime][end-1])
	@test data[:datetime][end] == f2[:datetime][end]
	@test data[:grav][1:4] == [10.,11.,12.,13.]
	@test isnan(data[:grav][5])
	@test data[:grav][6:end] == [22.,23.,24.,25.]

	# Same as above but with maximum time step exceeded
	data = stackframes(f1,f2,maxtime=Dates.Hour(1),maxval=NaN,corroffset=true);
	@test size(data) == (4,2)
	@test names(data)==[:datetime,:grav]
	@test data[:datetime] == f1[:datetime]
	@test data[:grav] == data[:grav];
end

function test_loadatmacs()
	# Load global and local part
	glo,loc = loadatmacs(glofiles=["test/input/atmacs_glo.grav"],
						locfiles=["test/input/atmacs_loc.grav"]);
	# Independent loading
	glo_m = readdlm("test/input/atmacs_glo.grav")
	loc_m = readdlm("test/input/atmacs_loc.grav")
	@test glo[:global_newton] == glo_m[:,2]
	@test glo[:total_loading] == glo_m[:,3]
	@test loc[:pressure] == loc_m[:,2]
	@test loc[:local_newton] == loc_m[:,3]
	@test loc[:regional_newton] == loc_m[:,4]
	@test glo[:datetime] == DateTime.(string.(round.(Int,glo_m[:,1])),"yyyymmddHH")
	@test loc[:datetime] == DateTime.(string.(round.(Int,loc_m[:,1])),"yyyymmddHH")

	# Stack multiple global files covering global+local part (`loc` will be empty)
	gfiles=["test/input/atmacs_all_1.grav",
			"test/input/atmacs_all_2.grav",
			"test/input/atmacs_all_3.grav"];
	glo,loc = loadatmacs(glofiles=gfiles);
	total_m = Matrix{Float64}(undef,0,5);
	for i in gfiles
		temp = readdlm(i)
		total_m = vcat(total_m,temp);
	end
	total_time = DateTime.(string.(round.(Int,total_m[:,1])),"yyyymmddHH")
	@test glo[:datetime] == DateTime.(string.(round.(Int,total_m[:,1])),"yyyymmddHH")
	for i in 2:size(glo,2)
		@test glo[i] == total_m[:,i]
	end
end

test_stackframes();
test_loadatmacs();
