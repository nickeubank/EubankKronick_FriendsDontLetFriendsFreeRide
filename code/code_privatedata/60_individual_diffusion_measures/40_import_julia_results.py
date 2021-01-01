
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
import numpy as np
import h5py
import glob
import re
from barrio_directories import get_path
barrio_networks = get_path("barrio_networks") 

# ########
# Helper Function
# ########

event_list = ["sept8"]

def gather_results(network_tuple):
    stem, num_steps, p, normalize, size, event = network_tuple

    os.chdir(barrio_networks + 'intermediate_files/individual_diffusion_results/{}'.format(event))

    # Seeds
    seed = h5py.File('seeds_{}_{}_n{}.h5'.format(normalize, stem, size), 'r')['key']
    seed = np.array(seed)

    # Total reach
    os.chdir(barrio_networks + 'intermediate_files/individual_diffusion_results/{}'.format(event))
    all_reached = h5py.File('reached_{}_{}_n{}.h5'.format(normalize, stem, size), 'r')['key']
    all_reached = np.array(np.transpose(all_reached))
    all_reached = pd.DataFrame(all_reached, columns=range(1, all_reached.shape[1]+1))
    all_reached['reach_type'] = 'all'
    all_reached['starter_seed'] = seed.copy()

    for i in range(1, num_steps+1):
        all_reached[i] = pd.to_numeric(all_reached[i], downcast='unsigned')

    # Protestors reached
    participant_reached = h5py.File('participant_reached_{}_{}_n{}.h5'.format(normalize, stem, size), 'r')['key']
    participant_reached = np.array(np.transpose(participant_reached))
    participant_reached = pd.DataFrame(participant_reached, columns=range(1, participant_reached.shape[1]+1))
    participant_reached['reach_type'] = 'participant'
    participant_reached['starter_seed'] = seed.copy()

    for i in range(1, num_steps+1):
        participant_reached[i] = pd.to_numeric(participant_reached[i], downcast='unsigned')

    # Combine
    sims = pd.concat([all_reached, participant_reached])
    for i in range(1, num_steps+1):
        sims[i] = pd.to_numeric(sims[i], downcast='unsigned')

    # Protestor count hsould always be <= all count
    import random
    for i in random.sample(list(range(1, num_steps+1)), 5):
        dif = all_reached[i] - participant_reached[i]
        assert (dif >= 0).all()

        for s in np.random.choice(sims.starter_seed.unique(), 20):
            protest = sims.loc[(sims.starter_seed == s) & (sims.reach_type == 'participant'), i]
            all = sims.loc[(sims.starter_seed == s) & (sims.reach_type == 'all'), i]
            assert (all >= protest).all()

    # Clear mem
    del seed
    del all_reached
    del participant_reached

    # Add meta-data
    components = stem.split('_')
    sims['voz_threshold'] = int(components[1])
    sims['month_share'] = int(components[2]) / 100
    sims['iter'] = int(components[3])
    sims['size'] = size
    sims['p'] = p
    sims['num_simulations'] = 1

    assert (num_steps in sims.columns)
    assert (num_steps + 1 not in sims.columns)

    ###############
    #
    # get ids for matched pairs
    #
    ###############

    for person in ['participants', 'matches']:

        # vertex pair_id key
        df = pd.read_hdf('../../individual_participants_and_matches/'\
                                   'vertex_user_key_{}_{}_voz{}_months{}_n{}.h5'.format(person, event,
                                                                                        int(components[1]),
                                                                                        int(components[2]),
                                                                                        size))

        df[person] = 1
        df = df.rename({'pair_id': 'pair_id_{}'.format(person)}, axis='columns')

        sims = pd.merge(sims, df, on='starter_seed',
                        how='outer', indicator=True, validate='m:1')
        assert (sims._merge != 'right_only').all()
        assert abs(sims._merge.value_counts(normalize=True).both == 0.5)
        sims = sims.drop('_merge', axis='columns')
        sims[person] = sims[person].fillna(0).astype('int')

    del df

    assert (pd.notnull(sims.pair_id_participants) | pd.notnull(sims.pair_id_matches)).all()
    assert (pd.isnull(sims.pair_id_participants) | pd.isnull(sims.pair_id_matches)).all()
    sims['pair_id'] = -1

    for i in ['matches', 'participants']:
        sims.loc[sims[i] == 1, 'pair_id'] = sims.loc[sims[i] == 1, 'pair_id_{}'.format(i)]

    assert (sims['pair_id'] != -1).all()
    sims = sims.drop(['pair_id_matches', 'pair_id_participants'], axis='columns')

    # Compress!

    for i in ['matches', 'participants', 'voz_threshold', 'iter', 'size',
              'starter_seed', 'pair_id', 'num_simulations']:
        sims[i] = pd.to_numeric(sims[i], downcast='unsigned')

    for i in ['month_share', 'p']:
        sims[i] = sims[i].astype('float16')

    sims['reach_type'] = pd.Categorical(sims['reach_type'],
                  categories=['all', 'participant'])

    sims = sims.drop(['matches'], axis='columns')

    # remove mechanical difference in protestor results caused by fact
    # that protestors always start with 1 protestor!
    tweaks = (sims.participants == 1) | (sims.reach_type == "all")
    assert (sims.loc[tweaks, 1] > 0).all()
    for i in range(1, num_steps + 1):
        # Best all be positive, or substracting one from an unsigned
        # will overflow to 255!
        sims.loc[tweaks, i] = (
            sims.loc[tweaks, i] - 1
            )

    print('done with {}'.format(network_tuple))
    return sims

##################
#
# Real run
#
####################


num_steps = 10
p = 0.1
normalize = 'ln'
size = 5000

for event in event_list:

    os.chdir(barrio_networks + 'intermediate_files/individual_diffusion_results/{}'.format(event))
    files = glob.glob(r'participant_reached_{}_{}_*_n{}.h5'.format(normalize, event, size))
    stems = list(map(lambda x: re.match(r"(participant_reached_{}_)(.*)_n{}.h5".format(normalize, size), x).groups()[1], files))

    to_do = [(s, num_steps, p, normalize, size, event) for s in stems]

    import time
    date_suffix = time.strftime("%Y_%m_%d")
    output_path = '../aggregated_{}_{}steps_indiv_{}_n{}_{}.dta'.format(event, num_steps, normalize, size, date_suffix)

    # Actual run
    #processes = 1
    #from joblib import Parallel, delayed
    #new_results = Parallel(n_jobs=processes, verbose=40)(delayed(gather_results)(network_tuple) for network_tuple in to_do)
    new_results = [gather_results(network_tuple) for network_tuple in to_do]

    #########
    # Gather results from parallel runs
    #########
    simulation_results = pd.concat(new_results)
    del new_results

    # Check a few
    for i in range(2, num_steps):
        assert (simulation_results[i] - simulation_results[i-1] >= 0).all()

    def prefix(col):
        if isinstance(col, int):
            return 'step_{}'.format(col)
        else: return col

    simulation_results = simulation_results.rename(columns=prefix)

    ############
    # Collapse to one obs per muni
    ############

    groupers = ['starter_seed', 'voz_threshold', 'month_share', 'reach_type']

    simulation_results['total_simulation_runs'] = simulation_results[groupers + ['num_simulations']].groupby(groupers, as_index=False).transform(sum)
    simulation_results = simulation_results.drop('num_simulations', axis='columns')


    collapsed = simulation_results.groupby(groupers, as_index=False).mean()
    del simulation_results

    # random samples are different for 4 and 2, and get all missing for the other.
    # So just keep if not missing, but make sure counts add up!
    assert pd.notnull(collapsed.participants).sum() == size * 2 * 2 * 2
    assert pd.isnull(collapsed.loc[pd.isnull(collapsed.participants), 'step_5']).all()

    collapsed = collapsed[pd.notnull(collapsed.participants)].copy()

    collapsed['participants'] = collapsed['participants'].astype('int')
    collapsed['event'] = event
    collapsed['normalize'] = normalize

    for c in collapsed.columns:
        if collapsed[c].dtype == 'uint64' or collapsed[c].dtype == 'uint32':
            collapsed[c] = collapsed[c].astype('int')
        if collapsed[c].dtype == 'float16':
            collapsed[c] = collapsed[c].astype('float32')

    assert (collapsed.total_simulation_runs == 1000).all()
    collapsed.to_stata(output_path)
    del collapsed
