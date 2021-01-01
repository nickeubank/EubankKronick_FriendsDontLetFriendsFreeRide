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


dailies = [pd.read_hdf('usuarios/user_day_interpolated_location/{}.h5'.format(date)) for date in dates]
users = pd.concat(dailies)

centroids = users[['user', 'interpolated_x', 'interpolated_y']].groupby('user').transform(np.mean)
users['centroid_x'] = centroids['interpolated_x']
users['centroid_y'] = centroids['interpolated_y']

users['dist'] = np.sqrt( (users.interpolated_x - users.centroid_x)**2 + 
                         (users.interpolated_y - users.centroid_y)**2)


user_var = users[['user', 'dist']].groupby('user', as_index=False).var()
user_var = user_var.rename(columns={'dist':'spatial_variance'})

user_var.to_hdf('usuarios/15_user_spatial_variance.h5',
                          key='key', format='fixed',
                          complevel=9, fletcher32=True)
