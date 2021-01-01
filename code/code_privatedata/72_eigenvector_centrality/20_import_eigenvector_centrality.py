
###########
# Read in graphml objects,
# strip identifiers to identify,
# export anonymized graph
# and vector of fundacomun assignments
# for analysis in Julia
#
# #########

import os
import pandas as pd
import igraph as ig
import numpy as np
import h5py
import glob
import re
from barrio_directories import get_path
barrio_networks = get_path("barrio_networks")


# ########
# Helper Function
# ########

event_list = ["sept1"]

num_steps = 15
p = 0.1
normalize = 'ln'
size = 5000

for event in event_list:
    stem = 'eigen_voz2'

    # get centralities
    os.chdir(barrio_networks + 'intermediate_files/eigenvector_centrality/')
    centralities = h5py.File('{}.h5'.format(stem), 'r')["key"]
    eigens = pd.DataFrame({'eigen':centralities})
    eigens = eigens.reset_index()
    eigens['index'] = eigens['index'] + 1
    eigens = eigens.rename({'index':'vertex_id'}, axis='columns')
    

    for person in ['participants', 'matches']:

        # vertex pair_id key. note seed codes are 1-indexed. 
        # See 20_export_participants_and_matches_for_julia.py lines 88-92
        df = pd.read_hdf('../individual_participants_and_matches/'\
                                   'vertex_user_key_{}_{}_voz2_months25_n{}.h5'.format(person, event, 
                                                                                        size))

        df[person] = 1
        df = df.rename({'pair_id': 'pair_id_{}'.format(person)}, axis='columns')
        
        eigens = pd.merge(eigens, df, left_on='vertex_id', right_on='starter_seed',
                          how='outer', indicator=True, validate='1:1')
        assert (eigens._merge != 'right_only').all()
        # assert abs(eigens._merge.value_counts(normalize=True).both == 0.5)
        eigens = eigens.drop('_merge', axis='columns')
        eigens[person] = eigens[person].fillna(0).astype('int')

    del df

    # Fill in pair_ids
    eigens['pair_id'] = -1

    for i in ['matches', 'participants']:
        eigens.loc[eigens[i] == 1, 'pair_id'] = eigens.loc[eigens[i] == 1, 'pair_id_{}'.format(i)]

    eigens = eigens.drop(['pair_id_matches', 'pair_id_participants'], axis='columns')


    # Only need matches
    eigens = eigens[eigens.pair_id != -1]
    assert len(eigens) == 10000
    assert (pd.notnull(eigens.starter_seed_x) | pd.notnull(eigens.starter_seed_y)).all()
    assert not (pd.notnull(eigens.starter_seed_x) & pd.notnull(eigens.starter_seed_y)).any()
    
    eigens = eigens.drop(['starter_seed_x', 'starter_seed_y', 'vertex_id'], axis='columns')

    # Output
    output_path = 'eigen_w_pairid_voz2_{}.dta'.format(event)
    eigens['pair_id'] = eigens['pair_id'].astype('int')
    eigens.to_stata(output_path)
    print('done with {}'.format(event))
