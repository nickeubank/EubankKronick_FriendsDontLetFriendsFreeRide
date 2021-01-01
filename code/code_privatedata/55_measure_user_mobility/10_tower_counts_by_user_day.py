#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Apr  1 23:01:13 2017

@author: Nick
"""

import pandas as pd
import os
from vz_directory import get_path
identificados_dir = get_path('datos_identificados')
os.chdir(identificados_dir)


# Get relevant files. August and September minus week around protest
dates = [('2016_08', '{:02}0816'.format(i)) for i in range(1, 28)] 
dates = dates + [('2016_09', '{:02}0916'.format(i)) for i in range(5, 31)]

directory = "cdrs/voz/"

# Collapse pre-conditioning.
def import_and_collapse(date_tuple):
    folder, date = date_tuple
    df = pd.read_hdf(directory + folder + '/trafico_aa_voz_' + date + '.h5')[['a', 'celda_switch', 'fecha']]

    assert df.fecha.dt.hour.max() > 12
    
    df = df[pd.notnull(df.fecha)]
    df['date'] = (df.fecha.dt.day * 100 + df.fecha.dt.month).astype('int16')
    df = df[df.date == int(date)//100]
    df['counter'] = True

    # Total in a day
    per_day = df.copy().drop(['fecha'], axis='columns')
    per_day = per_day.groupby(by=['a', 'celda_switch', 'date'], as_index=False).sum()

    per_day['celda_switch'] = pd.to_numeric(per_day['celda_switch'], downcast='integer')
    per_day['counter'] = pd.to_numeric(per_day.counter, downcast='integer')

    per_day = per_day.loc[(per_day.celda_switch != -1)]

    per_day.to_hdf('usuarios/user_day_tower_counts/{}.h5'.format(date), key='key', format='fixed',
                   complevel=9, fletcher32=True)
    del per_day
    
    # Protest hours only 
    df = df[(df.fecha.dt.hour >= 8) & (df.fecha.dt.hour < 14)]
    protest_hours = df.drop(['fecha'], axis='columns')
    protest_hours = protest_hours.groupby(by=['a', 'celda_switch', 'date'], as_index=False).sum()

    protest_hours['celda_switch'] = pd.to_numeric(protest_hours['celda_switch'], downcast='integer')
    protest_hours['counter'] = pd.to_numeric(protest_hours.counter, downcast='integer')

    protest_hours= protest_hours.loc[(protest_hours.celda_switch != -1)]

    protest_hours.to_hdf('usuarios/user_day_tower_counts/protest_hours_{}.h5'.format(date), key='key', format='fixed',
                           complevel=9, fletcher32=True)


    return 1

# Run!

from joblib import Parallel, delayed
new_results = Parallel(n_jobs=7, verbose=40)(delayed(import_and_collapse)(date_tuple) 
                                             for date_tuple in dates)
