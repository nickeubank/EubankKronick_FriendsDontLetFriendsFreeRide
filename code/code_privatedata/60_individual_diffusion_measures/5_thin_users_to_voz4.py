
###########
# Read in identified protestors.
# 
# Create a matched sample for comparison.
# #########

import os
import pandas as pd
import igraph as ig
import numpy as np

from barrio_directories import get_path
identificados_dir = get_path("datos_identificados")
barrio_networks = get_path("barrio_networks")


#############
# Make matched sample
#############

os.chdir(identificados_dir)
users_wo_mobility = pd.read_hdf('usuarios/80_users_with_protest_recall.h5')

# Get mobility
mobility = pd.read_hdf('usuarios/15_user_spatial_variance.h5')
users = pd.merge(users_wo_mobility, mobility, on='user', validate='1:1', how='left')
del users_wo_mobility

# Get caracas counts
caracas = pd.read_hdf('usuarios/65_users_in_caracas.h5')
users = pd.merge(users, caracas, on='user', validate='1:1', how='outer', indicator=True )
assert (users._merge != 2).all()
users = users.drop('_merge', axis='columns')
del caracas

# Get call coutn from august and september
users_temp = users.copy()
call_freq = pd.read_hdf('usuarios/17_user_total_calls_in_aug_sept.h5')
users = pd.merge(users, call_freq, left_on='user', right_index=True,
                 validate='1:1', how='outer', indicator=True)
assert (users._merge != 2).all()

assert users.query('pt == 1')._merge.value_counts(normalize =True).loc['both'] > 0.5
users = users.drop('_merge', axis='columns')
users['calls_aug_sept'] = users['calls_aug_sept'].fillna(0)
assert (users['calls_aug_sept'] >= 0).all()
del call_freq


# For PT subscribers, put in zeros for in caracas count if missing. 
for i in ['in_caracas_weekend', 'in_caracas_weekday']:
    users.loc[users.pt & pd.notnull(users.interp_home_estado) & pd.isnull(users[i]), i] = 0


# Drop people not in 4 / 25
file_stem = 'graphs/vz_graph_voz4_sms12_0.25_months.graphml'
g = ig.Graph.Read(f=file_stem, format='graphml')

in_graph = pd.DataFrame({'user': g.vs['name']})
in_graph['user'] = in_graph['user'].astype('int')

assert not in_graph.user.duplicated().any()
assert not users.user.duplicated().any()
pre = len(users)
users = pd.merge(users, in_graph, on='user', how='inner')
assert len(users) == len(in_graph)
assert pre > len(in_graph)


#########
# Create formatted participate vars for MUD and psuv
#########

users['participant_PSUV'] = users.psuv.copy()
users['participant_MUD'] = np.abs(-(users.psuv - 1))

check_sum = (users['participant_MUD'] + users['participant_PSUV'])
assert (( check_sum == 1 ) | pd.isnull(check_sum) ).all()
assert pd.isnull(users.loc[pd.isnull(users['participant_MUD']), 'participant_PSUV']).all()
assert pd.isnull(users.loc[pd.isnull(users['participant_PSUV']), 'participant_MUD']).all()
assert pd.notnull(users.loc[pd.notnull(users['participant_PSUV']), 'participant_MUD']).all()


assert (users.query('pt == True').calls_aug_sept == 0).mean() < 0.25

users.to_hdf('usuarios/90_users_with_participation_mobility_in_voz4.h5', key='key',
                     fletcher32=True, format='table')

# Coverage summary stats:
os.chdir(barrio_networks)
users.coverage.value_counts(normalize=True).to_latex('results/georef_coverage_in_voz4.tex')

