

###########
# Identify people at On street week before sept 1st (aug 25th)
# as placebo. Done
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

os.chdir(identificados_dir)
users = pd.read_hdf('usuarios/60_users_with_locations.h5')


# First run

for date_pair in [('sept', '01'), 
                  ('aug', '04'), ('aug', '11'), ('aug', '18'), 
                  ('aug', '23'), ('aug', '25'), 
                  ('sept', '08'), ('sept', '15'), ('sept', '22'), 
                  ('sept', '29')]:

    code = date_pair[0] + str(int(date_pair[1]))
    month_string = {'aug':'08', 'sept': '09'}[date_pair[0]]

    # Get cdr records from day of protest
    cdrs = pd.read_hdf('cdrs/voz/2016_{}/trafico_aa_voz_{}{}16.h5'.format(
                       month_string, date_pair[1], month_string))

    cdrs = cdrs[cdrs.fecha.dt.day==int(date_pair[1])]
    cdrs = cdrs[(cdrs.fecha.dt.hour >= 8) & (cdrs.fecha.dt.hour < 14)]

    assert (cdrs.fecha.dt.month == int(month_string)).all()
    assert (cdrs.fecha.dt.day == int(date_pair[1])).all()
    cdrs = cdrs[['a', 'celda_switch']]

        # Get towers relevant to protest
    towers = pd.read_csv('torres/towers_near_protest_2016sept1.csv')
    assert ((towers.estado == 'MIRANDA') | (towers.estado=="DISTRITO CAPITAL")).all()
    tower_codes = towers[['celda_switch']]
    assert not (tower_codes .duplicated()).any()

    participants = pd.merge(cdrs, tower_codes, how='left', on='celda_switch', indicator=True)
    assert (participants._merge != 'right_only').all()

    # Tag if apparent participant
    participant_code = 'participant_' + code
    participants.loc[participants._merge == 'both', 'temp'] = 1
    participants['temp'] = participants['temp'].fillna(0)
    participants[participant_code] = participants[['temp', 'a']].groupby('a').transform(max)
    participants = participants.drop('temp', axis='columns')
    
    # Tag if made call at tower NOT in zone and made no calls IN zone
    anti_participant_code = 'anti_participant_' + code
    participants.loc[(participants._merge == 'left_only') & (participants[participant_code] == 0), 'temp2'] = 1
    participants['temp2'] = participants['temp2'].fillna(0)
    participants[anti_participant_code] = participants[['temp2', 'a']].groupby('a').transform(max)
    participants = participants.drop(['temp2', '_merge'], axis='columns')


    participants = participants.drop_duplicates(['a', participant_code, anti_participant_code])
    participants = participants.drop('celda_switch', axis='columns')
    assert (participants.loc[participants[participant_code] == 1,  anti_participant_code] == 0).all()
    assert participants[participant_code].sum() < participants[anti_participant_code].sum()


    #########
    # Merge in with main user dataset
    #########

    users['temp'] = 1
    users = pd.merge(users, participants, left_on='user', right_on='a',
                            how='outer', validate='1:1')
    users = users.drop('a', axis='columns')

    # No one in protest data not in master users
    assert not (pd.isnull(users.temp) & (users[participant_code]== 1)).any()
    users = users.drop('temp', axis='columns')

    users[participant_code] = users[participant_code].fillna(0)


    #########
    # Exclude people who live near protest site.
    # These are all parroquias that touch protest route OR touch a paRRoquia that
    # touches

    #########
    contaminated = pd.read_csv(barrio_networks + 'source_data/protest_maps/contaminated_parroquias.txt')
    contaminated = contaminated[['id_estado', 'id_municip', 'id_parroqu']]
    contaminated['bad'] = 1
    assert not contaminated.duplicated().any()

    contaminated['id_estado'] = contaminated['id_estado'].astype('float64')


    exclude_participants_code = 'exclude_' + participant_code
    users[exclude_participants_code] = False
    for i in ['home', 'work']:
        left_keys = ['interp_{}_estado'.format(i), 'interp_{}_municipio'.format(i), 'interp_{}_parroquia'.format(i)]
        right_keys = ['id_estado', 'id_municip', 'id_parroqu']
        pre_len = len(users)

        users = pd.merge(users, contaminated,
                                left_on=left_keys,
                                right_on=right_keys,
                                how='outer')
        assert len(users) == pre_len
        assert users.bad.value_counts()[1] > 0
        users.loc[users.bad==1, participant_code] = np.nan
        users.loc[users.bad==1, anti_participant_code] = np.nan

        users.loc[users.bad==1, exclude_participants_code] = True
        users = users.drop(['bad']+right_keys, axis='columns')

    protest_sums = users[participant_code].value_counts(dropna=False)

    print('{} has {}'.format(code, protest_sums[1]))
    sizes = {'sept1': 33953,
            'aug4': 36454,
            'aug11': 37242,
            'aug18': 40335,
            'aug23': 39021,
            'aug25': 40535,
            'sept8': 40333,
            'sept15': 41844,
            'sept22': 41729,
            'sept29': 42790
             }
    try: 
        size_check = (protest_sums[1] > sizes[code] - 1000) and (protest_sums[1] < sizes[code] + 1000)
    except: 
        size_check = pd.Series(True)
    assert size_check.all()

#########
# Save
#########

users.to_hdf('usuarios/70_users_with_participants.h5', key='key', fletcher32=True,
                format='table')
