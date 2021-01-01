* Sets global var barrios_dir used in all stata file paths.


* location
*---------

global barrios_dir "/Users/nick/desktop/EubankKronick_FriendsDontLetFriendsFreeRide"
*global barrios_dir "/Users/kronick/EubankKronick_FriendsDontLetFriendsFreeRide"



* events
*-------

global event_list "aug4 aug11 aug18 aug25 sept1 sept8 sept15 sept22 sept29 petition PSUV MUD"


* step count
*-----------

global step_count = 6


* make directories
*-----------------

capture mkdir $barrios_dir/results/binnedscatters
capture mkdir $barrios_dir/results/exposure_densities
capture mkdir $barrios_dir/results/descriptives
capture mkdir $barrios_dir/results/effects
capture mkdir $barrios_dir/results/tables



* Our tables have two components: a `.tex` file with the structure of the table
* that imports actual values with `primitiveimport`, and an "inner" .tex
* with actual values. Move the outer portion into the results folder:
*--------------------------------------------------------------------

foreach f in "Correlations_EC.tex" "Effects_Main.tex" ///
             "Effects_ParticipantExposure.tex" "Effects_Population.tex" ///
             "Effects_SES.tex" {
    copy "$barrios_dir/results_nonpublicsource/tables/`f'" ///
         "$barrios_dir/results/tables/`f'", replace
}



* Run code
*---------

do $barrios_dir/code/code_publicdata/01_Table1.do
do $barrios_dir/code/code_publicdata/02_Figure1.do
do $barrios_dir/code/code_publicdata/03_Tables2_3_4.do
do $barrios_dir/code/code_publicdata/04_FigureC2.do
do $barrios_dir/code/code_publicdata/05_FigureC3.do
do $barrios_dir/code/code_publicdata/06_TableC3.do
