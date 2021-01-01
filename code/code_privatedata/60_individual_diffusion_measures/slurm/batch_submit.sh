
for i in petition sept1 aug25 sept8 ; do

    # sbatch --export=VOZ=2,MONTH=25,EVENT="$i",SIZE=5000 fully_arrayed_individual_sim.slurm
    sbatch --export=VOZ=4,MONTH=25,EVENT="$i",SIZE=5000 fully_arrayed_individual_sim.slurm

done
