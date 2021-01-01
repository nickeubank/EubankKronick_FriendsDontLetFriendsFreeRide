
###########
# Read in identified protestors.
#
# Create a matched sample for comparison.
# #########

import os
import pandas as pd
import numpy as np
import re
import time
from barrio_directories import get_path
identificados_dir = get_path("datos_identificados")
barrio_networks = get_path("barrio_networks")

target_dates = ["MUD", "PSUV", "aug11", "aug18", "aug25", "aug4", "petition", "sept15", "sept1", "sept22", "sept29", "sept8"]

#############
# Make matched sample
#############

os.chdir(identificados_dir)

users_in_voz4 = pd.read_hdf('usuarios/90_users_with_participation_mobility_in_voz4.h5')
users_in_voz4['registration_female'] = users_in_voz4['registration_female'].astype('float64')
users_in_voz4['post'] = users_in_voz4['post'].astype('int')

# In Caracas categories
for i in ['weekend', 'weekday']:
    users_in_voz4['any_{}_in_caracas'.format(i)] = np.nan
    users_in_voz4.loc[users_in_voz4['in_caracas_{}'.format(i)] > 0, 'any_{}_in_caracas'.format(i)] = 1
    users_in_voz4.loc[users_in_voz4['in_caracas_{}'.format(i)] == 0, 'any_{}_in_caracas'.format(i)] = 0


# Thin to matchable
users_thinned = users_in_voz4[users_in_voz4.pt==True].copy()

## Call frequency quartiles for matching for date-based
#quartiles, bins = pd.qcut(users_thinned.calls_aug_sept, 4, precision=0, retbins=True)
#users_thinned['call_freq_quartile'] = quartiles.cat.codes
#
#
## Save bins
#os.chdir(barrio_networks)
#x = 'Quartile bins are {:,.0f} to {:,.0f}, {:,.0f} to {:,.0f}, '\
#    '{:,.0f} to {:,.0f}, and over {:,.0f} calls'.format(bins[0], bins[1],
#                                                  bins[1], bins[2],
#                                                  bins[2], bins[3],
#                                                  bins[3])
#with open('results/call_freq_bins.tex', 'w+') as f:
#    f.write(x)

os.chdir(identificados_dir)


# Setup matching

first_match = ['registration_precinct']

# Can put call freq in this base set if want.

match_cols_in_priority_order_base = ['psuv',
                                     'any_weekday_in_caracas',
                                     'any_weekend_in_caracas',
                                     'in_caracas_weekday',
                                     'in_caracas_weekend',
                                     'registration_female',
                                     'post']

special_matches = ['spatial_variance', 'registration_age']

for matching in match_cols_in_priority_order_base + special_matches + first_match:
    users_thinned = users_thinned[pd.notnull(users_thinned[matching])]

users_thinned = users_thinned.set_index('user')
users_thinned['registration_precinct'] = users_thinned['registration_precinct'].astype('int')


stds = dict()
for i in match_cols_in_priority_order_base + special_matches:
    stds[i] = users_thinned[i].std()


# Drop protestors identified as bieng in protest zone for more than 14 weekdays
# or 2 weekend days in august or september
for i in target_dates:
    var_name = 'participant_' + i
    users_thinned.loc[(users_thinned[var_name] == 1) & (users_thinned.in_caracas_weekday >= 14), var_name] = np.nan
    users_thinned.loc[(users_thinned[var_name] == 1) & (users_thinned.in_caracas_weekend >= 4), var_name] = np.nan

#########
# Helper functions
#########

def get_match(participant_record, candidates, attempt, exact_match_cols):
    working_candidates = candidates.copy()

    # Split col types
    num_cols = len(exact_match_cols)
    use_for_exact = exact_match_cols[0: num_cols - attempt]
    use_for_min_sq = exact_match_cols[num_cols - attempt: num_cols]
    assert use_for_exact + use_for_min_sq == exact_match_cols

    # Recursive!
    if attempt < num_cols:
        for m in use_for_exact:
            working_candidates = working_candidates[working_candidates[m] == participant_record[m]]

        # If successful get out
        if len(working_candidates) > 0:
            exact_matches.iloc[attempt:num_cols+1] = exact_matches.iloc[attempt:num_cols+1] + 1
            return min_sq_error_match(participant_record, working_candidates, use_for_min_sq, attempt)

        # else recurse
        else:
            print('into recurstion. starting attempt {}'.format(attempt + 1))
            return get_match(participant_record, candidates, attempt + 1, exact_match_cols)

    # Base case!
    if attempt == num_cols:
        print('RECURSION BASE CASE, PARTICIPANT {}'.format(participant_record.name))
        exact_matches.iloc[attempt: num_cols+1] = exact_matches.iloc[attempt: num_cols+1] + 1
        return min_sq_error_match(participant_record, candidates, exact_match_cols, attempt)



def min_sq_error_match(participant_record, candidates, match_vars, attempt):
    candidates = candidates[ ['user'] + match_vars + special_matches].copy()
    candidates['sum_sq_dif'] = 0

    for c in match_vars + special_matches:
        candidates['sum_sq_dif'] = candidates['sum_sq_dif'] + (
                abs(candidates[c] - participant_record[c]) / stds[c]
                ) ** 2
    assert (candidates.sum_sq_dif >= 0 ).all()
    assert candidates.sum_sq_dif.mean() > 0

    candidates = candidates[abs(candidates.sum_sq_dif - candidates.sum_sq_dif.min()) < 0.000001]
    return candidates.user, attempt




##########
# Generate matches
##########
sizes = dict()


for event in target_dates:
    for size in [5000]:

        #        # Only use call frequency to match on location-inferred events.
        #        if re.match('(aug|sept)[0-9]*', event):
        #            match_cols_in_priority_order = match_cols_in_priority_order_base.copy()
        #        else:
        #            match_cols_in_priority_order = match_cols_in_priority_order_base.copy()
        #            match_cols_in_priority_order.remove('call_freq_quartile')
        #
        #        if event == 'petition' or event == "PSUV":
        #            assert 'call_freq_quartile' not in match_cols_in_priority_order
        match_cols_in_priority_order = match_cols_in_priority_order_base.copy()


        exact_matches = pd.Series(0, index=list(reversed(match_cols_in_priority_order)) + ['total matches'],
                                    name="Num exact matched by var")

        os.chdir(identificados_dir)

        # Seed random. Must be unique for all specifications!
        seed = 14343340 * 100 + size + int( bytearray(event, 'utf-8')[0])

        import numpy.random as npr
        npr.seed(seed)


        users_thinned_viable = users_thinned.copy()
        if re.match('(aug|sept)[0-9]*', event):
            users_thinned_viable = users_thinned.query('participant_{}==0 | participant_{}==1'.format(event, event)).copy()


        # No one from precincts that CANT match
        a = users_thinned_viable [['registration_precinct', 'participant_{}'.format(event)]].groupby('registration_precinct')
        a = a.transform(np.mean)
        users_thinned_viable['precinct_heterogeneity_{}'.format(event)] = a

        # Get participants
        participants = users_thinned_viable.query("participant_{}==1".format(event)).copy()
        pre_len = len(participants)
        participants = participants.query("precinct_heterogeneity_{} != 1".format(event))
        assert pre_len - len(participants) < 1000

        # Get sizes
        sizes[event] = dict()
        sizes[event].update({'Participant Population': len(users_in_voz4[users_in_voz4['participant_{}'.format(event)] == 1])})
        sizes[event].update({'Participant Population with Matching Vars': len(participants)})

        participants = participants.sample(n=size)
        participants.reset_index(drop=False).user.to_hdf('usuarios/matches/participants_{}_n{}.h5'.format(event, size),
                                key='key', fletcher32=True)

        # Get Matches

        match_candidates = users_thinned_viable.copy()

        # Only match for people who made call NOT at protest for locations.

        if re.match('(aug|sept)[0-9]*', event):
            match_candidates = match_candidates.query('participant_{}==0'.format(event)).copy()

        match_candidates = match_candidates.query('participant_{} == 0'.format(event)).copy()
        match_candidates = match_candidates.reset_index(drop=False).set_index('registration_precinct')
        match_candidates['matched_sample'] = False
        match_candidates['matched_exact_match_attempt'] = -1

        # Ordered vector for matching ids between match and non-match
        matched_sample_ids = pd.Series(-1, index=range(len(participants)))

        participant_sample_ids = participants.reset_index(drop=False).user.copy()
        num_to_do = len(participants)
        problems = list()

        # Draw actual matches
        for i in range(0, len(participant_sample_ids)):
            if i % 100 == 0:
                print('{} of {}, event {}, size {} '.format(i, num_to_do, event, size))

            # Get protestor's info for matching
            participant_id = participant_sample_ids.iloc[i]


            participant_record = participants.loc[participant_id]

            # For party regressions, watch match of OPPOSITE party
            if event in ['PSUV', 'MUD']:
                participant_record.loc['psuv'] = np.abs( np.abs(-(participant_record.loc['psuv'] - 1)) )


            # First, indexed draw on precinct. Should be fast and
            # really reduce sample for speed. Then
            # power through brute force on others
            candidates = match_candidates.loc[[participant_record.registration_precinct]]
            candidates = candidates[~candidates['matched_sample']]
            assert len(candidates) != 0

            # Do recursive matching!
            candidates, attempt = get_match(participant_record, candidates, 0, match_cols_in_priority_order)

            keeper = candidates.sample()
            match_candidates.loc[match_candidates.user == keeper.iloc[0], 'matched_sample'] = True
            match_candidates.loc[match_candidates.user == keeper.iloc[0], 'matched_exact_match_attempt'] = attempt
            matched_sample_ids.iloc[i] = keeper.iloc[0]


        matched_sample_ids.to_hdf('usuarios/matches/matches_{}_n{}.h5'.format(event, size), key='key', fletcher32=True)

        assert len(participants) == len(matched_sample_ids)
        assert (matched_sample_ids != -1).all()

        os.chdir(barrio_networks)
        exact_matches.to_latex('results/matching_diagnostics/exactmatchcounts_{}_n{}.tex'.format(event, size))
        exact_matches.to_hdf('results/matching_diagnostics/exactmatchcounts_{}_n{}.h5'.format(event, size), key='key')
        print('end of {}'.format(event))
        print(exact_matches)

    pd.DataFrame(sizes[event], index=[0]).iloc[0].to_latex('results/matching_diagnostics/participant_{}_samplesizes.tex'.format(event))


# RECURSION BASE CASE, PARTICIPANT 4248174811 sept1
