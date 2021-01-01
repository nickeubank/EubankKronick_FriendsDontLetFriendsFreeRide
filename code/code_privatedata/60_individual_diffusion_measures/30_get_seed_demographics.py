
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
from barrio_directories import get_path
identificados_dir = get_path("datos_identificados")
barrio_networks = get_path("barrio_networks")


# Events to examine
event_list = ["sept1", "aug4", "aug11", "aug18", "aug25", "sept8", "sept15", "sept22", "sept29", 'petition', 'PSUV', 'MUD']
event_list_cols = ['participant_' + event for event in event_list if event != 'petition' and event != 'sept1']


# Get master demographics file for this population
os.chdir(identificados_dir)
users = pd.read_hdf('usuarios/90_users_with_participation_mobility_in_voz4.h5')
users_thinned = users[['user', 'psuv', 'registration_precinct', 
                       'registration_age', 'registration_female',
                       'registration_municipio', 'registration_estado',
                       'interp_home_municipio', 'interp_home_estado',
                       'participant_petition', 'participant_sept1',
                       'calls_aug_sept'] + event_list_cols ].copy()

users_thinned['registration_age_rounded'] = np.round(users_thinned['registration_age'] / 5) * 5
assert (users_thinned.loc[users_thinned.registration_age == 26, 'registration_age_rounded'] == 25).all()
assert (users_thinned.loc[users_thinned.registration_age == 27, 'registration_age_rounded'] == 25).all()
users_thinned = users_thinned.drop('registration_age', axis='columns')



# Get demographics
size = 5000
for event in event_list:

    
    individuals = dict()
    merged = dict()
    for i in ['participants', 'matches']:

        os.chdir(identificados_dir)
        
        individuals[i] = pd.read_hdf('usuarios/matches/{}_{}_n{}.h5'.format(i, event, size))
        individuals[i] = pd.DataFrame({'user': individuals[i]})

        merged[i] = pd.merge(individuals[i], users_thinned, on='user', how='left', 
                                          indicator=True, validate='1:1')
        assert (merged[i]._merge == 'both').all()
        merged[i] = merged[i].drop('_merge', axis='columns')

        # Make sure merge doesn't screw with order
        assert (merged[i]['user'].reset_index(drop=True) == individuals[i]['user'].reset_index(drop=True)).all()

        if i == 'participants':
            assert (merged[i]['participant_' + event] == 1).all()
            merged[i]['participant'] = 1

        if i == 'matches':
            # Match error. Patched in most recent version. Some people
            # I dropped from "participapnt" for being in caracas
            # for too many days became controls. :/
            assert (merged[i]['participant_' + event] == 1).sum() < 25
            merged[i]['participant'] = 0

        #####
        # Save up!
        #####
        os.chdir('/users/nick/github/barrio_networks')
    
        merged[i] = merged[i].drop('user', axis='columns')
        merged[i] = merged[i].reset_index(drop=True)
        merged[i] = merged[i].reset_index().rename({'index': 'pair_id'}, axis='columns')
        assert merged[i]['pair_id'].max() == len(merged[i]) - 1
    
        for c in merged[i].columns:
            if merged[i][c].dtype == 'float16':
                merged[i][c] = merged[i][c].astype('float32')
    
        file = 'intermediate_files/individual_participants_and_matches/'\
                      'demographics_{}_{}_n{}.dta'.format(i, event, size)
        merged[i].to_stata(file)


