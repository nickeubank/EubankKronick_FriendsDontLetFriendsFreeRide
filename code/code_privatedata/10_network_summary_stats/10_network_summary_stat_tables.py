#!/usr/bin/env python3
# -*- coding: utf-8 -*-

###########
# Read in graphml objects,
# strip identifiers to identify,
# export anonymized graph
# and vector of fundacomun assignments
# for analysis in Julia
#
# #########

import os
import numpy as np
import pandas as pd
import igraph as ig
from barrio_directories import get_path
barrio_networks = get_path("barrio_networks")

os.chdir(barrio_networks)

voz_levels = [2, 4, 6]
month_levels = [25, 50, 75]


stats = pd.DataFrame({'Calls': [i for i in voz_levels for j in month_levels],
                      'Share Months': month_levels * len(voz_levels)})
stats['Users'] = -1
stats['Connections'] = -1
stats['Avg Num Connections'] = -1
stats['Median Num Connections'] = -1


for voz in voz_levels:
    for month in month_levels:

        anon_stem = 'intermediate_files/graphs/anon_voz{}_{}_months.graphml'.format(voz, month)
        g = ig.Graph.Read(f=anon_stem, format='graphml')

        stats.loc[(stats['Calls'] == voz) &
                  (stats['Share Months'] == month), 'Users'] = '{:,d}'.format(g.vcount())

        stats.loc[(stats['Calls'] == voz) &
                  (stats['Share Months'] == month), 'Connections'] = '{:,d}'.format(g.ecount())

        stats.loc[(stats['Calls'] == voz) &
                  (stats['Share Months'] == month), 'Avg Num Connections'] = '{:.2f}'.format(g.ecount() / g.vcount())

        median_degree = np.median(g.degree())
        stats.loc[(stats['Calls'] == voz) &
                  (stats['Share Months'] == month), 'Median Num Connections'] = '{:,.0f}'.format(median_degree)

        assert( stats.loc[(stats['Calls'] == voz) &
                  (stats['Share Months'] == month), 'Median Num Connections'] <= 
                stats.loc[(stats['Calls'] == voz) &
                  (stats['Share Months'] == month), 'Avg Num Connections'])

stats['Share Months'] = stats['Share Months'].apply(lambda x: str(x) + r'\%')

stats = stats.rename(columns={'Share Months': r'\thead{Share \\ Months}',
                              'Avg Num Connections': r'\thead{Avg Num \\ Connections}',
                              'Median Num Connections': r'\thead{Median Num \\ Connections}',
                              'Users': r'\thead{Users}',
                              'Connections': r'\thead{Connections}',
                              'Calls': r'\thead{Calls}'})

file = 'results/network_summary_stats.tex'
stats.to_latex(file, index=False, escape=False, column_format='ccrrrr')

file = 'results/network_summary_stats.h5'
stats.to_hdf(file, key='key')

stats_thin = stats[stats[r'\thead{Share \\ Months}'] == r'25\%']
file = 'results/network_summary_stats_25s.tex'
stats_thin.to_latex(file, index=False, escape=False, column_format='ccrrrr')


