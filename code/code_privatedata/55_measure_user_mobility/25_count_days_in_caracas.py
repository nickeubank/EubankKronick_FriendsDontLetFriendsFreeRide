#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Apr  5 17:48:57 2017

@author: Nick
"""

import pandas as pd
import numpy as np
import os
from datetime import datetime
from vz_directory import get_path
identificados_dir = get_path('datos_identificados')
os.chdir(identificados_dir)


# Get relevant files. August and September minus week around protest
dates = ['{:02}0816'.format(i) for i in range(1, 28)] 
dates = dates + ['{:02}0916'.format(i) for i in range(5, 31)]


# 0909 not actually 0909 -- telecomm error. :(
dates = [date for date in dates if date != "090916"]


# Get protest zone towers
towers = pd.read_csv('torres/towers_near_protest_2016sept1.csv')
assert ((towers.estado == 'MIRANDA') | (towers.estado=="DISTRITO CAPITAL")).all()
tower_codes = towers[['celda_switch']].copy()
assert not (tower_codes.duplicated()).any()


def identify_days_in_caracas(date):

    date_as_datetime = datetime.strptime(date, "%d%m%y")
    assert date_as_datetime.year == 2016
    assert date_as_datetime.weekday() in range(0, 7)
    weekend = date_as_datetime.weekday() in [5, 6]
    
    # Estimate as weighted average of celda centroids
    users = pd.read_hdf('usuarios/user_day_tower_counts/protest_hours_' + date + '.h5')

    users = users.reset_index(drop=True)
    users = users.rename(columns={'a':'user'})
    
    users_w_caracas = pd.merge(users, tower_codes, on='celda_switch', how='inner',
                               validate='m:1')
    assert  len(users_w_caracas) / len(users) < 0.1

    if weekend:
        users_w_caracas['in_caracas_weekend'] = 1
        users_w_caracas['in_caracas_weekday'] = 0
    elif not weekend:
        users_w_caracas['in_caracas_weekend'] = 0
        users_w_caracas['in_caracas_weekday'] = 1
    else: raise ValueError("Shouldn't get here!")

    users_w_caracas = users_w_caracas[['user', 'in_caracas_weekend', 'in_caracas_weekday']].copy()
    users_w_caracas = users_w_caracas.drop_duplicates()
    return users_w_caracas

# Run!

#########
# Excluding protest week
#########
from joblib import Parallel, delayed
new_results = Parallel(n_jobs=7, verbose=40)(delayed(identify_days_in_caracas)(date) 
                                            for date in dates)

counts = pd.concat(new_results)
collapsed_counts = counts.groupby('user', as_index=False).sum()
assert collapsed_counts.in_caracas_weekend.sum() > 0
assert collapsed_counts.in_caracas_weekday.sum() > 0

assert (collapsed_counts.in_caracas_weekday < (len(dates) * (5/7) + 3)).all()
assert (collapsed_counts.in_caracas_weekend < (len(dates) * (2/7) )).all()



collapsed_counts.to_hdf('usuarios/65_users_in_caracas.h5', key='key')

