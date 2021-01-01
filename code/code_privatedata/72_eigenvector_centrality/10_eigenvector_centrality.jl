using LightGraphs
using HDF5
cd("/scratch/eubankn/barrio_networks")
# cd("/users/nick/github/barrio_networks")

g = loadgraph("intermediate_files/graphs/anon_voz2_25_months.lg")

# g = erdos_renyi(1_000, 0.01)


# Run
ec = eigenvector_centrality(g)
@assert length(ec) == nv(g)
@assert length(ec) > 100_000

# Save
eigen_results = "intermediate_files/eigenvector_centrality/eigen_voz2.h5"
h5write(eigen_results, "key", ec)

print("done")
