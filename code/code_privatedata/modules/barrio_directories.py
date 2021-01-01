#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Apr  7 20:31:21 2017
@author: Nick
"""

def get_path(request_string):
    """ Get path. 
        Valid requests:
            - home
            - datos_identificados_original
            - datos_identificados
            - datos_cifrados
            - barrio_networks
    """
    
    if request_string == 'barrio_networks':
        return "/users/nick/github/barrio_networks/"    
    if request_string == 'datos_identificados_original':
        return "/volumes/tonka_disk_3/datos_identificados_original/"
    if request_string == 'datos_identificados':
        return "/volumes/tonka_disk_2/datos_identificados/"
    if request_string == 'code':
        return "/users/nick/vz/code/"
    if request_string == 'graphs':
        return "/volumes/tonka_disk_2/datos_identificados/graphs/"
    if request_string == 'otros':
        return "/users/nick/vz/otros_datos/"
    if request_string == 'datos_cifrados':
        return "/volumes/tonka_disk_3/wave2_transfer"    

    
    raise ValueError("Not a valid path")
        
