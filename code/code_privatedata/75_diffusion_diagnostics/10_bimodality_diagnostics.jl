using LightGraphs
using HDF5
cd("/users/nick/github/barrio_networks")

###########
# Loads
###########

# Graph
g = loadgraph("intermediate_files/graphs/anon_voz2_25_months.lg")
# Little easier to read ints
g = SimpleGraph{Int32}(g)

file_stem = "intermediate_files/individual_participants_and_matches/"
event = "sept1"

targets = Dict()
for target in ["matches", "participants"]
    array = h5read(file_stem * "$target\_$event\_voz2_25_months_n5000.h5",
                     "key")
    @assert all(array["index"]+1 == collect(1:length(array["values"])))
    array = array["values"]
    @assert length(array) == nv(g)
    targets[target] = findin(array, 1)
    @assert length(targets[target]) == 5_000
end

#####################
# Get full participants, make set for quick random access
#####################

full_participants = h5read("intermediate_files/full_participants/" *
                           "full_participants_$event\_voz2_n5000.h5",
                           "key")
full_participants = full_participants["values"]
full_participant_indices = findin(full_participants, 1)
if event == "sept1"
    @assert length(full_participant_indices) > 30_000
end
full_participant_indices = Set(full_participant_indices)

#####################
# Count!
#####################


function fill_in_shares(target_indices, full_indices)
    results = Array{Float64}(5_000, 2)

    for (idx, v) in enumerate(target_indices)
        n = Set(neighbors(g, v))

        n2 = copy(n)
        for v2 in n
            union!(n2, Set(neighbors(g, v2)))
        end
        delete!(n2, v) # Don't want self as a second-degree neighbor.

        n_participants = n ∩ full_indices
        n2_participants = n2 ∩ full_indices

        results[idx, 1] = length(n_participants) / length(n)
        results[idx, 2] = length(n2_participants) / length(n2)
        @assert length(n_participants) <= length(n2_participants)
        @assert length(n) <= length(n2)
    end
    return results
end

for t in keys(targets)
    neighborhoods = fill_in_shares(targets[t], full_participant_indices)
    @assert size(neighborhoods, 1) == 5_000
    share_first_zero = sum(neighborhoods[:, 1] .== 0) / size(neighborhoods, 1)
    share_second_zero = sum(neighborhoods[:, 2] .== 0) / size(neighborhoods, 1)
    @assert all(neighborhoods[neighborhoods[:, 2] .== 0, 1] .== 0)
    write("results/share_firstdegree_wo_participants_$event\_$t.tex",
          @sprintf("%.2f", share_first_zero))
    write("results/share_seconddegree_wo_participants_$event\_$t.tex",
          @sprintf("%.2f", share_second_zero))
end

print("done")
