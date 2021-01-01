
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


target_dates = ['PSUV', 'MUD', "sept1", "aug4", "aug11", "aug18", "aug25", "sept8", "sept15", "sept22", "sept29"]


for graph_tuple in [(4, 0.25)]:
    
    voz_threshold, month_share = graph_tuple
    sms_threshold = voz_threshold * 3


    # Load graph
    os.chdir(identificados_dir)
    file_stem = 'graphs/vz_graph_voz{}_sms{}_{:.2}_months.graphml'.format(voz_threshold,
                                                                          sms_threshold,
                                                                          month_share)
    g = ig.Graph.Read(f=file_stem, format='graphml')


    # Get full list of participants
    users_in_voz4 = pd.read_hdf('usuarios/90_users_with_participation_mobility_in_voz4.h5')
    users_in_voz4['registration_female'] = users_in_voz4['registration_female'].astype('float64')
    users_in_voz4['post'] = users_in_voz4['post'].astype('int')

    for i in target_dates:
        var_name = 'participant_' + i
        users_in_voz4.loc[(users_in_voz4[var_name] == 1) & (users_in_voz4.in_caracas_weekday >= 14), var_name] = np.nan
        users_in_voz4.loc[(users_in_voz4[var_name] == 1) & (users_in_voz4.in_caracas_weekend >= 4), var_name] = np.nan


    for event in target_dates:
        for size in [5000]:
            var_name = 'participant_' + event
            full_participants = users_in_voz4.loc[users_in_voz4[var_name] == 1, ['user']].copy()

            # Get userid - vertex mappings.
            vertex_user_key = pd.DataFrame({'user':g.vs['name']})
            vertex_user_key['user'] = vertex_user_key.user.astype('int')

            # Get protest statuse
            full_participants['in_set'] = 1

            #############
            # First vertex key for use in Julia. 
            # Set of all vertices with "in set" or "out of set"
            #############
            
            full_participants_vid = pd.merge(vertex_user_key, full_participants, on='user', how='left')
            full_participants_vid['in_set'] = full_participants_vid.in_set.fillna(0).astype('bool')
            assert not full_participants_vid.duplicated().any()

            # Ensure stable order
            for j in [12309, 10, 12398, 8983]:
                assert full_participants_vid.user.iloc[j] == full_participants_vid.user.loc[j]
                assert g.vs[j]['name'] == str(full_participants_vid.user.loc[j])
                assert full_participants_vid.index.is_monotonic

            assert len(full_participants_vid) == g.vcount()
            

            # Save
            os.chdir('/users/nick/github/barrio_networks')
            month_as_int = int(month_share * 100)

            in_set = full_participants_vid['in_set'].astype('int')

            os.chdir('/users/nick/github/barrio_networks')
            file = 'intermediate_files/full_participants/'\
                   'full_participants_{}_voz{}_n{}.h5'.format(event, voz_threshold, size)
            in_set.to_hdf(file, 'key', compression='blosc', fletcher32=True)


            # Back merge check
            os.chdir('/users/nick/github/barrio_networks')
            file = 'intermediate_files/individual_participants_and_matches/'\
                   'participants_{}_voz{}_25_months_n{}.h5'.format(event, voz_threshold, size)
            sampled_participants = pd.read_hdf(file).astype('Bool')

            file = 'intermediate_files/individual_participants_and_matches/'\
                   'matches_{}_voz{}_25_months_n{}.h5'.format(event, voz_threshold, size)
            sampled_matches = pd.read_hdf(file).astype('Bool')
            
            assert len(in_set) == len(sampled_matches)
            assert len(in_set) == len(sampled_participants)
                        

            assert (in_set[sampled_participants] == 1).all()
            assert (in_set[sampled_matches] == 0).all()


