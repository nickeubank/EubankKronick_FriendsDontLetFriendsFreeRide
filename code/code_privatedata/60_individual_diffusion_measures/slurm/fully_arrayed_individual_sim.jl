
println("starting")
flush(STDOUT)

task_id = parse(Int, ENV["SLURM_ARRAY_TASK_ID"])
chunk_size = parse(Int, ENV["CHUNK_SIZE"])
event = ENV["EVENT"]
voz = parse(Int, ENV["VOZ"])
month = parse(Int, ENV["MONTH"])
size = parse(Int, ENV["SIZE"])

start = (task_id - 1) * chunk_size + 1
finish = task_id * chunk_size


# Setup and load scrips
cd("/scratch/eubankn/barrio_networks")
home = "/scratch/eubankn/barrio_networks/"
helper_file = "code/60_individual_diffusion_measures/DiffusionByIndividual.jl"
include(home * helper_file)

test_suite()
println("test suite done")
flush(STDOUT)

# Run actual simulations!

num_steps = 10

g = load_graph(voz, month, 0)
println("Graph loaded")
flush(STDOUT)

for iteration in start:finish

    println("starting iteration $iteration")
    flush(STDOUT)

    p = 0.1

    check_ln_normalization(p)
    println("Normalization check done")
    flush(STDOUT)

    parameter_dict = Dict("voz" => voz,
                         "month" => month,
                         "iter" => iteration,
                         "size" => size,
                         "event" => event)

    # run!
    cd("/scratch/eubankn/barrio_networks")
    participants = load_participants(parameter_dict)
    
    println("starting diffusion, iteration $iteration")
    diffusion_result = run_diffusion(g, participants,
                                     p=p,
                                     num_steps=num_steps,
                                     normalize=true)
    save_diffusion(parameter_dict, diffusion_result)
end

println("Done!")
flush(STDOUT)
