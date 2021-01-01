
println("starting")
flush(STDOUT)

# Setup and load scrips
cd("/scratch/eubankn/barrio_networks")
home = "/scratch/eubankn/barrio_networks/"
helper_file = "code/60_individual_diffusion_measures/DiffusionByIndividual.jl"
include(home * helper_file)

test_suite()
println("test suite done")
flush(STDOUT)

println("Done!")
flush(STDOUT)
