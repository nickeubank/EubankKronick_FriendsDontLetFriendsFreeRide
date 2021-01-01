#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Apr  5 17:48:57 2017

@author: Nick
"""

import pandas as pd
import numpy as np
import os
from vz_directory import get_path
identificados_dir = get_path('datos_identificados')
os.chdir(identificados_dir)


# Get relevant files. August and September minus week around protest
dates = ['{:02}0816'.format(i) for i in range(1, 28)] 
dates = dates + ['{:02}0916'.format(i) for i in range(5, 31)]


# 0909 not actually 0909 -- telecomm error. :(
dates = [date for date in dates if date != "090916"]


def collapse_by_user_day(date):
    # Estimate as weighted average of celda centroids
    users = pd.read_hdf('usuarios/user_day_tower_counts/' + date + '.h5')

    users = users.reset_index(drop=True)
    users = users.rename(columns={'a':'user'})
    
    # Merge with Towers.
    towers = pd.read_hdf('torres/tower_locations.h5')
    assert (~towers.celda_switch.duplicated()).all()
        
    for i in ['celda_x', 'celda_y']:
        towers[i] = towers[i].astype('float32')
        
    
    pre_merge_length = len(users)
    users = users.merge(towers, how='left', 
                        on='celda_switch',
                        indicator=True)
    assert len(users) == pre_merge_length
    
    # A bunch of the post-paid have bad tower locations. Just have to drop. 
    users._merge.value_counts()
    users._merge.value_counts(normalize=True).loc['left_only']
    assert users._merge.value_counts(normalize=True).loc['left_only'] < 0.05
    users = users.loc[users._merge == 'both'].drop(['_merge', 'celda_switch'], axis='columns')
    
    
    #####
    # Move from antennas to towers
    #####
    # Currently one observation PER ANTENNA, many many antennas per physical tower. 
    # Collapse once more. 
    
    users = users[['user', 'date', 'celda_x', 'celda_y', 'counter']].groupby(by=['user', 'date', 'celda_x', 'celda_y'], as_index=False).sum()
    assert users.counter.min() > 0
        
    
    ####
    # Flag  most used tower. 
    ####
    users = users.sort_values(['user', 'counter'], ascending=False)
    most_used = users[['user', 'celda_x', 'celda_y']].groupby(['user']).nth(0)
    most_used = most_used.rename(columns = {'celda_x':'most_used_x',
                                            'celda_y':'most_used_y'})
    
    # Merge back in
    pre_len = len(users)
    users = pd.merge(users, most_used, left_on='user', right_index=True, 
                                          how='outer', indicator=True)
    assert len(users) == pre_len
    assert (users._merge == 'both').all()
    users =  users.drop('_merge', axis='columns')
        
    
    #####
    # Get weighted averages
    #####
    grouped = users[['user', 'date', 'counter']].copy().groupby(['user', 'date'])
    users['total_calls'] = grouped.transform(sum)
    users['weight'] = users.counter / users.total_calls
    assert ((users.weight <= 1) & (users.weight > 0)).all()
    
    users['weight_t_x'] = users.weight * users.celda_x
    users['weight_t_y'] = users.weight * users.celda_y
    
    user_locations = users[['user', 'date', 'weight_t_x', 'weight_t_y']].groupby(['user', 'date']).sum()
    user_locations = user_locations.rename(columns={'weight_t_x':'interpolated_x', 'weight_t_y':'interpolated_y'})
    user_locations = user_locations.reset_index(drop=False)
    
    user_locations.to_hdf('usuarios/user_day_interpolated_location/{}.h5'.format(date),
                          key='key', format='fixed',
                          complevel=9, fletcher32=True)
    return 1

# Run!
from joblib import Parallel, delayed
new_results = Parallel(n_jobs=7, verbose=40)(delayed(collapse_by_user_day)(date) 
                                            for date in dates)
