
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
from barrio_directories import get_path
identificados_dir = get_path("datos_identificados")
barrio_networks = get_path("barrio_networks")


target_dates = ["sept1", "aug25"]


for graph_tuple in [(2, 0.25)]:
    
    voz_threshold, month_share = graph_tuple
    sms_threshold = voz_threshold * 3


    # Load graph
    os.chdir(identificados_dir)
    file_stem = 'graphs/vz_graph_voz{}_sms{}_{:.2}_months.graphml'.format(voz_threshold,
                                                                          sms_threshold,
                                                                          month_share)
    g = ig.Graph.Read(f=file_stem, format='graphml')

    for event in target_dates:
        for size in [5000]:


            # Get userid - vertex mappings.
            vertex_user_key = pd.DataFrame({'user':g.vs['name']})
            vertex_user_key['user'] = vertex_user_key.user.astype('int')

            # Get protest statuse
            individuals = dict()

            for person in ['participants', 'matches']:

                os.chdir(identificados_dir)
                
                individuals[person] = pd.read_hdf('usuarios/matches/{}_{}_n{}.h5'.format(person, event, size))
                individuals[person] = pd.DataFrame({'user': individuals[person]})

                individuals[person]['in_set'] = 1

                #############
                # First vertex key for use in Julia. 
                # Set of all vertices with "in set" or "out of set"
                #############
                
                individuals[person + '_vid'] = pd.merge(vertex_user_key, individuals[person], on='user', how='left')
                individuals[person + '_vid']['in_set'] = individuals[person + '_vid'].in_set.fillna(0).astype('bool')
                assert not individuals[person + '_vid'].duplicated().any()

                # Ensure stable order
                for j in [12309, 10, 12398, 8983]:
                    assert individuals[person + '_vid'].user.iloc[j] == individuals[person + '_vid'].user.loc[j]
                    assert g.vs[j]['name'] == str(individuals[person + '_vid'].user.loc[j])
                    assert individuals[person + '_vid'].index.is_monotonic

                assert len(individuals[person+'_vid']) == g.vcount()
                

                # Save
                os.chdir('/users/nick/github/barrio_networks')
                month_as_int = int(month_share * 100)

                in_set = individuals[person + '_vid']['in_set'].astype('int')
                file = 'intermediate_files/individual_participants_and_matches/'\
                              '{}_{}_voz{}_{}_months_n{}.h5'.format(person, event, voz_threshold, month_as_int, size)
                in_set.to_hdf(file , 'key', compression='blosc', level=9, fletcher32=True)


                #############
                # Now exports to keep matched pairs straight. Used in re-import.
                #############
                                
                # Now user id to vertex id key for recovering matches. 
                vertex_user_key_w_starter_seed = vertex_user_key.copy()
                vertex_user_key_w_starter_seed = vertex_user_key_w_starter_seed.reset_index(drop=True).reset_index(drop=False)
                vertex_user_key_w_starter_seed = vertex_user_key_w_starter_seed.rename({'index': 'starter_seed'}, axis='columns')
                vertex_user_key_w_starter_seed['starter_seed'] = vertex_user_key_w_starter_seed['starter_seed'] + 1
                assert vertex_user_key_w_starter_seed['starter_seed'].min() == 1
                assert vertex_user_key_w_starter_seed['starter_seed'].max() == g.vcount()
                
                user_to_id = pd.merge(individuals[person], vertex_user_key_w_starter_seed, 
                                      on='user', how='left',
                                      validate='1:1', indicator=True)
                assert (user_to_id._merge == 'both').all()
                user_to_id = user_to_id.drop('_merge', axis='columns')
                user_to_id = user_to_id.reset_index(drop=True).reset_index(drop=False)
                user_to_id = user_to_id.rename({'index': 'pair_id'}, axis='columns')
                assert user_to_id.pair_id.max() == (size - 1)
                
                
                user_to_id = user_to_id.drop(['in_set'], axis='columns')
                
                os.chdir(identificados_dir)
                file = 'usuarios/matches/'\
                       'vertex_user_key_{}_{}_voz{}_months{}_n{}_wuser.h5'.format(person, event, voz_threshold, month_as_int, size)
                user_to_id.to_hdf(file, 'key', compression='blosc', fletcher32=True)

                user_to_id = user_to_id.drop(['user'], axis='columns')

                os.chdir('/users/nick/github/barrio_networks')
                file = 'intermediate_files/individual_participants_and_matches/'\
                       'vertex_user_key_{}_{}_voz{}_months{}_n{}.h5'.format(person, event, voz_threshold, month_as_int, size)
                user_to_id.to_hdf(file, 'key', compression='blosc', fletcher32=True)

