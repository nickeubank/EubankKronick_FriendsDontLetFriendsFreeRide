

##################################################################
##
##
##		NAME:		  Nick Eubank
##		DATE: 		September 5th, 2017
##		PROJECT: 	Vz networks
##
##		DETAILS: 	Identify cell-phone towers in close proximity to 
##              Sept 1st 2006 protests
##
##				
##		Version: 	R 3.2.6
##
##################################################################







##  ##  ##	##	##	##	##	##	##	##	##	##	##
##	##	##	##	##	##	##	##	##	##	##	##	##
##	##	##	##	##	##	##	##	##	##	##	##	##



#-------------------------------------------------------------------------------
# preliminaries: set working directory and install packages
#-------------------------------------------------------------------------------



# directory
# Note below have to hard-path 
# to non-public tower location 
# data
#----------

setwd("~/github/barrio_networks/")



# packages
#---------
library(rgdal)
library(rgeos)
library(sp)

# Get line file of protest route
# and tower locations.
# Harmonize projections. 
#-------------------------------

route = readOGR('source_data/protest_maps', 'TomaDeCaracas_ruta_line_utm19n')

towers = read.csv('/Volumes/Tonka_Disk_2/datos_identificados/torres/torres.csv')
coordinates(towers) = c('tower_long', 'tower_lat')
proj4string(towers) = CRS('+init=epsg:4326')
towers_utm = spTransform(towers, CRS(proj4string(route)))

# Get towers within certain 
# of protest route. Distance
# mostly from looking at maps
# for reasonable "nearest" set. 
# 750m seems more than adequete to 
# get what looks like near set of 
# towers
#-------------------------------

stopifnot(length(route) == 1)
stopifnot(proj4string(route) == proj4string(towers_utm))

dists = gDistance(towers_utm, route, byid=TRUE)
stopifnot(length(dists) == length(towers_utm))
towers_utm$dists = dists[1,]
stopifnot( mean(towers_utm[towers_utm$estado=="DISTRITO CAPITAL",]$dists) < mean(towers_utm[towers_utm$estado!="DISTRITO CAPITAL", ]$dists))
stopifnot(mean(towers_utm[towers_utm$estado=="DISTRITO CAPITAL",]$dists) < 5000)

near_protest = towers_utm[towers_utm$dists < 750, c('celda_switch', 'estado', 'municipio', 'parroquia')]@data
write.csv(near_protest, '/Volumes/Tonka_Disk_2/datos_identificados/torres/towers_near_protest_2016sept1.csv')


