using LightGraphs
using GraphIO
using HDF5
using Base.Test

function load_graph(voz, month, start_spread_minutes)

    # Spread out loads to don't hit ram too hard
    # Spread starts over thirty minutes
    sleep(rand() * start_spread_minutes * 60)

    # Load graph
    f_root = "intermediate_files/graphs/"
    f = "anon_voz$voz\_$month\_months.lg"
    g = loadgraph(f_root * f)
    return g
end

function check_ln_normalization(p)

    g = Graph(2)
    add_edge!(g, (1,2))
    @assert ne(g) == 1

    result = 0
    sims = 1_000_000

    for i in 1:sims
       reached = diffusion_rate(g, p, 2, initial_infections=[1], normalize=true)
       result += reached[2] - 1
    end
    @assert abs( result / sims ) - (p / log(2)) < 0.01
    println("Log Normalization checks out!")
end



function load_participants(parameters)
    threshold = parameters["voz"]
    month_share = parameters["month"]
    size = parameters["size"]
    event = parameters["event"]


    # Load protestors and matched
    protest_root = "intermediate_files/individual_participants_and_matches/"
    protestors_path = "participants\_$event\_voz$threshold\_$month_share\_months\_n$size.h5"
    protestors = h5read(protest_root * protestors_path, "key")["values"]
    protestors = convert(Vector{Bool}, protestors)

    matched_path = "matches\_$event\_voz$threshold\_$month_share\_months\_n$size.h5"
    matched = h5read(protest_root * matched_path, "key")["values"]
    matched = convert(Vector{Bool}, matched)

    # Load protestors and matched
    full_participants = "intermediate_files/full_participants/"
    full_participants_path = "full_participants\_$event\_voz$threshold\_n$size.h5"
    full_participants = h5read(full_participants * full_participants_path, "key")["values"]
    full_participants = convert(Vector{Bool}, full_participants)

    participants = Dict("protestors" => protestors,
                        "matched" => matched,
                        "full_participants" => full_participants
                        )
    return participants
end


function run_diffusion(g::Graph, participants;
                       num_steps::Integer=10,
                       p::Real=0.1,
                       normalize::Bool=true)

    protestors = participants["protestors"]::Vector{Bool}
    matched = participants["matched"]::Vector{Bool}
    full_participants = participants["full_participants"]::Vector{Bool}

    seeds = vcat(find(protestors), find(matched))
    sort!(seeds)

    # Run over and over!
    num_reached = Array{Float64}(length(seeds), num_steps)
    num_protest_reached = Array{Float64}(length(seeds), num_steps)

    for (i, s) in enumerate(seeds)
        infections = diffusion(g, p, num_steps,
                                     initial_infections=[s],
                                     normalize=normalize)

        # Neighborhood size
        num_reached[i, :] = diffusion_rate(infections)

        # now get number of protestors reached
        for step in infections
            filter!(x -> full_participants[x], step)
        end

        num_protest_reached[i, :] = diffusion_rate(infections)

    end

    results = Dict("num_reached"  => num_reached,
                   "num_protest_reached" => num_protest_reached,
                   "seeds" => seeds)
    return results
end


function save_diffusion(parameters, results)
    threshold = parameters["voz"]
    months = parameters["month"]
    iter = parameters["iter"]
    size = parameters["size"]
    event = parameters["event"]

    cd("intermediate_files/individual_diffusion_results/$event")

    f_indiv = "reached_ln_$event\_$threshold\_$months\_$iter\_n$size.h5"
    try
        rm(f_indiv)
    end
    h5open(f_indiv, "w") do file
        write(file, "key", results["num_reached"])
    end

    f_protest = "participant_reached_ln_$event\_$threshold\_$months\_$iter\_n$size.h5"
    try
        rm(f_protest)
    end
    h5open(f_protest, "w") do file
        write(file, "key", results["num_protest_reached"])
    end

    f_seeds = "seeds_ln_$event\_$threshold\_$months\_$iter\_n$size.h5"
    try
        rm(f_seeds)
    end
    h5open(f_seeds, "w") do file
        write(file, "key", results["seeds"])
    end

end


function test_suite()

    participants = Dict()
    participants["protestors"] = [false, false, false, true, true, true, true]
    participants["full_participants"] = [false, false, false, true, true, true, true]
    participants["matched"] =    [true, false, false, false, false, false, false]
    g = PathGraph(7)

    parameters = Dict()
    parameters["size"] = 100
    parameters["event"] = "test"

    @inferred(run_diffusion(g, participants, num_steps=7, p=1, normalize=false))

    output = run_diffusion(g, participants, num_steps=7, p=1, normalize=false)

    # Seeds right
    @test output["seeds"] == [1, 4, 5, 6, 7]

    # When start with non-protestor, best have 0 as num protestors reached in
    # first step.
    @test output["num_protest_reached"][1, :] == [0, 0, 0, 1, 2, 3, 4]
    @test output["num_reached"][1, :] == collect(1:7)

    # Start with protestor at end, should increase to 4 protestors and hold
    @test output["num_protest_reached"][5, :] == [1, 2, 3, 4, 4, 4, 4]
    @test output["num_reached"][5, :] == collect(1:7)


    # middle out from person 4:
    @test output["num_reached"][2, :] == [1, 3, 5, 7, 7, 7, 7]
    @test output["num_protest_reached"][2, :] == [1, 2, 3, 4, 4, 4, 4]

    # Ensure that new protestors reached var working.
    participants["full_participants"] = [false, true, true, true, true, true, true]

    output = run_diffusion(g, participants, num_steps=7, p=1, normalize=false)
    @test output["num_reached"][1, :] == collect(1:7)
    @test output["num_protest_reached"][1, :] == collect(0:6)

end
