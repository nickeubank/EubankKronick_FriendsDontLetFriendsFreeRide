
###########
# Identify people at Sept 1st 2016 protest
# by finding all calls from that day
# and subsetting to calls connecting to
# towers in immediate proximity of protest.
#
# Once this "possible" set is identified,
# I then "drop" everyone who lives in parroquias with towers.
# I COULD do by municipio, but I don't want to drop the mass of
# Libertador which I think is far enough to be uncontaminated.
# #########

import os
import pandas as pd
import numpy as np
import igraph as ig
from barrio_directories import get_path
identificados_dir = get_path("datos_identificados")
barrio_networks = get_path("barrio_networks")
otros = get_path("otros")


###############
# Find people present at location of protest
###############

dates = [{'month':8, 'day':'04', 'dayplus':'05'}, 
         {'month':8, 'day':'11', 'dayplus':'12'}, 
         {'month':8, 'day':'18', 'dayplus':'19'}, 
         {'month':8, 'day':'25', 'dayplus':'26'}, 
         {'month':9, 'day':'01', 'dayplus':'02'}, 
         {'month':9, 'day':'08', 'dayplus':'09'}, 
         {'month':9, 'day':'15', 'dayplus':'16'}, 
         {'month':9, 'day':'22', 'dayplus':'23'},
         {'month':9, 'day':'29', 'dayplus':'30'}] 


results = pd.DataFrame({'month': [i['month'] for i in dates],
                        'day':  [i['day'] for i in dates]})

for date in dates:

    
    
    # Get cdr records from day of protest
    os.chdir(identificados_dir)
    cdrs = pd.read_hdf('cdrs/voz/2016_0{}/trafico_aa_voz_{}0{}16.h5'.format(
                       date['month'], date['day'], date['month']))
    cdrs2 = pd.read_hdf('cdrs/voz/2016_0{}/trafico_aa_voz_{}0{}16.h5'.format(
                        date['month'], date['dayplus'], date['month']))
    
    cdrs = cdrs[(cdrs.fecha.dt.day == int(date['day'])) & (cdrs.fecha.dt.month == date['month'])]
    cdrs2 = cdrs2[(cdrs2.fecha.dt.day == int(date['day'])) & (cdrs2.fecha.dt.month == date['month'])]
    cdrs = pd.concat([cdrs, cdrs2], axis='index')
    del cdrs2
    
    assert (cdrs.fecha.dt.month == int(date['month'])).all()
    assert (cdrs.fecha.dt.day == int(date['day'])).all()
    cdrs = cdrs[['a', 'celda_switch']]
    
    
    # Get towers relevant to protest
    towers = pd.read_csv('torres/towers_near_protest_2016sept1.csv')
    assert ((towers.estado == 'MIRANDA') | (towers.estado=="DISTRITO CAPITAL")).all()
    tower_codes = towers[['celda_switch']]
    assert not (tower_codes .duplicated()).any()
    
    protestors = pd.merge(cdrs, tower_codes, how='inner', on='celda_switch')
    assert len(protestors) < len(cdrs)
    
    protestors = protestors[['a']].drop_duplicates()
    protestors['pop_to_count'] = 1
    
    results.loc[(results.month == date['month']) & (results.day == date['day']), 'total'] = len(protestors)
    
    
    #########
    # Merge in with main user dataset
    #########
    
    users = pd.read_hdf('usuarios/60_users_with_locations.h5')
    users['temp'] = 1
    users_w_prot = pd.merge(users, protestors, left_on='user', right_on='a', how='outer')
    
    # No one in protest data not in master users
    assert not (pd.isnull(users_w_prot.temp) & (users_w_prot.pop_to_count == 1)).any()
    users_w_prot = users_w_prot.drop('temp', axis='columns')
    
    users_w_prot['pop_to_count'] = users_w_prot.pop_to_count.fillna(0)
    
    
    
    #########
    # Exclude people who live near protest site.
    # These are all parroquias that touch protest route OR touch a paRRoquia that
    # touches
    
    #########
    contaminated = pd.read_csv(barrio_networks + 'source_data/protest_maps/contaminated_parroquias.txt')
    contaminated = contaminated[['id_estado', 'id_municip', 'id_parroqu']]
    contaminated['bad'] = 1
    assert not contaminated.duplicated().any()
    
    
    users_w_prot['exclude'] = False
    
    for i in ['home', 'work']:
        left_keys = ['interp_{}_estado'.format(i), 'interp_{}_municipio'.format(i), 'interp_{}_parroquia'.format(i)]
        right_keys = ['id_estado', 'id_municip', 'id_parroqu']
        pre_len = len(users_w_prot)
    
        users_w_prot = pd.merge(users_w_prot, contaminated,
                                left_on=left_keys,
                                right_on=right_keys,
                                how='outer')
        assert len(users_w_prot) == pre_len
        assert users_w_prot.bad.value_counts()[1] > 0
        users_w_prot.loc[users_w_prot.bad==1, 'pop_to_count'] = np.nan
    
        users_w_prot.loc[users_w_prot.bad==1, 'exclude'] = True
        users_w_prot = users_w_prot.drop(['bad']+right_keys, axis='columns')
    
    
    results.loc[(results.month == date['month']) & (results.day == date['day']), 
                 'excluding_local'] = users_w_prot.pop_to_count.value_counts(dropna=False)[1]
    

os.chdir(barrio_networks)
results.to_latex('results/people_in_protest_zone_by_date.tex', index=False, float_format=lambda x: '{:,.0f}'.format(x))
results.to_hdf('intermediate_files/people_in_protest_zone_by_date.h5', key='key')
