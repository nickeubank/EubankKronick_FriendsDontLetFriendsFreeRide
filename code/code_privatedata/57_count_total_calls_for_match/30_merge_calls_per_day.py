#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Apr  5 17:48:57 2017

@author: Nick
"""

import pandas as pd
import numpy as np
import os
from barrio_directories import get_path
identificados_dir = get_path('datos_identificados')
os.chdir(identificados_dir)


# Get relevant files. August and September minus week around protest
dates = ['{:02}0816'.format(i) for i in range(1, 28)] 
dates = dates + ['{:02}0916'.format(i) for i in range(5, 31)]

# 0909 not actually 0909 -- telecomm error. :(
dates = [date for date in dates if date != "090916"]

dailies = [pd.read_hdf('usuarios/user_call_counts/{}.h5'.format(date)) for date in dates]
users = pd.concat(dailies)

# Check 
avg = users.groupby('a').size().mean()
med = users.groupby('a').size().median()

assert avg > 28 and avg < 35
assert med > 28 and med < 35

# Collapse again
call_count = users[['a', 'counter']].groupby('a').sum()
call_count = call_count.rename({'counter': 'calls_aug_sept'}, axis='columns') 
call_count.index.name = 'user'

assert (call_count.calls_aug_sept > 0).all()

call_count.to_hdf('usuarios/17_user_total_calls_in_aug_sept.h5',
                          key='key', format='fixed',
                          complevel=9, fletcher32=True)
