
###########
# Identify people who signed recall petition
# using cedula codes (dorothy has list)
# #########

import os
import pandas as pd
import igraph as ig
from barrio_directories import get_path
identificados_dir = get_path("datos_identificados")
barrio_networks = get_path("barrio_networks")



# Get user file with protestors
os.chdir(identificados_dir)
users = pd.read_hdf('usuarios/70_users_with_participants.h5')

os.chdir(barrio_networks)
signatories = pd.read_stata('non_public_files/recall/recall_signatories.dta')
signed = signatories[['cedula']].copy()
signed['participant_petition'] = 1
assert not pd.isnull(signed.cedula).any()
assert not signed.cedula.duplicated().any()
assert not users[pd.notnull(users.cedula)].cedula.duplicated().any()

users_w_signatures = pd.merge(users, signed, on='cedula', how='left')
users_w_signatures['participant_petition'] = users_w_signatures['participant_petition'].fillna(0)

os.chdir(identificados_dir)

users_w_signatures['cedula'] = users_w_signatures['cedula'].astype('float64')
users_w_signatures.to_hdf('usuarios/80_users_with_protest_recall.h5', key='key',
                          fletcher32=True, format='table')
