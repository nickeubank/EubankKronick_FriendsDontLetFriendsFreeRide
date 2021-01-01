#!/usr/bin/env python3
# -*- coding: utf-8 -*-


###########
# Identify people at Sept 1st 2016 protest
# by finding all calls from that day
# and subsetting to calls connecting to 
# towers in immediate proximity of protest. 
# #########

import os
import pandas as pd
import igraph as ig
from barrio_directories import get_path
identificados_dir = get_path("datos_identificados")
barrio_networks = get_path("barrio_networks")



# Get user file with protestors
os.chdir(identificados_dir)
users = pd.read_hdf('usuarios/80_users_with_protest_recall.h5')
assert pd.isnull(users.loc[users.sept1protest_exclude==1, 'sept1protest']).all()

thinned_users = users[['municipio', 'signed_recall', 'sept1protest']].copy()
thinned_users['user_count'] = 1


counts = thinned_users.groupby('municipio', as_index=False).sum()

os.chdir(barrio_networks)
counts.to_csv('non_public_files/municipio_participation_counts.csv')
