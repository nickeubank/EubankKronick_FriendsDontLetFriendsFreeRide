#!/bin/bash

#SBATCH --mail-user=nick@nickeubank.com  # email address
#SBATCH --mail-type=ALL  # Alerts sent when job begins, ends, or aborts
#SBATCH --ntasks=1
#SBATCH --mem-per-cpu=100G
#SBATCH --job-name=eigen
#SBATCH --time=03-00:00:00  # Wall Clock time (dd-hh:mm:ss) [max of 14 days]
#SBATCH --output=outputs/eigen.output  # output and error messages go to this file

julia 10_eigenvector_centrality.jl
