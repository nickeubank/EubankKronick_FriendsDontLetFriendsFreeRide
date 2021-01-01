
	******************************************************************
	**
	**
	**		NAME:		NICK EUBANK & DOROTHY KRONICK
	**		DATE: 		March 19, 2018
	**		PROJECT: 	Networks
	**
	**		DETAILS: 	This file creates merges precinct
	**					characteristics to the expansion results,
	**					for the participants and matches for all dates.
	**
	**
	**
	**		Version: 	Stata MP 14
	**
	******************************************************************









			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**



*-------------------------------------------------------------------------------
* preliminaries
*-------------------------------------------------------------------------------



* set more off
*-------------

set more off



* directory
*----------

cd "$barrios_dir"







			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**



*-------------------------------------------------------------------------------
* prepare file matching PRECINCT IDs to CENSUS TRACT IDs
*-------------------------------------------------------------------------------


	/* Note: RA Jiaqi Zhu prepared this spatial join.
	         Note also, we only have census tract shapefiles
			 for six states (fortunately, the states
			 closest to the protest). */



* loop over the six states we have
*---------------------------------

foreach state in aragua carabobo df lara miranda vargas {



* import spatial join
*---------------------

import delimited "/Users/kronick/barrio_networks/intermediate_files/precinct_characteristics/joined_`state'.csv", ///
       encoding(ISO-8859-1)clear



* formatting
*-----------

cap rename id_seg cod_ubigeo

format cod_ubigeo %12.0f /* This is the census-tract ID */



* save
*-----

tempfile `state'

savesome state_name mun_name parish_name codigo_centro_nuevo cod_ubigeo using ``state''

	}



* append all
*-----------

clear

foreach state in aragua carabobo df lara miranda vargas {

	append using ``state''

	}


* make census-tract-id string
*----------------------------

tostring cod_ubigeo, usedisplayformat replace

replace cod_ubigeo = "0" + cod_ubigeo if length(cod_ubigeo) == 11

rename cod_ubigeo cod_segmento



* save
*-----

tempfile census_to_precincts

save `census_to_precincts'







			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**



*-------------------------------------------------------------------------------
* merge individual-level characteristics to expansion results
*-------------------------------------------------------------------------------



* loop over dates
*----------------

foreach event in $event_list {




    * get individual characteristics
    *-------------------------------

    use "/Users/kronick/barrio_networks/intermediate_files/individual_participants_and_matches/demographics_participants_`event'_n5000.dta", clear

    append using "/Users/kronick/barrio_networks/intermediate_files/individual_participants_and_matches/demographics_matches_`event'_n5000.dta"



    * check that precinct is the same within pair
    *--------------------------------------------

    bysort pair_id: egen min_reg = min(registration_precinct)

    bysort pair_id: egen max_reg = max(registration_precinct)

    assert min_reg == max_reg

    drop min_reg max_reg



    * names and formats
    *------------------

    rename participant participants

    format registration_precinct %13.0f

    rename registration_precinct codigo_centro_nuevo



    * merge diffusion results
    *------------------------

	merge 1:m pair_id participants using ///
      "/Users/kronick/barrio_networks/intermediate_files/individual_diffusion_results/aggregated_`event'_10steps_indiv_ln_n5000_2019_03_27.dta"
/*
if _rc ~= 0 {

	merge 1:m pair_id participants using ///
		  "intermediate_files/individual_diffusion_results/aggregated_`date'_15steps_indiv_ln_n5000_2018_05_01.dta"

	}
*/

	drop _m



    * for now
    *--------

    keep if voz_threshold == 2







    			**	**	**	**	**	**	**	**	**	**	**	**	**
    			**	**	**	**	**	**	**	**	**	**	**	**	**
    			**	**	**	**	**	**	**	**	**	**	**	**	**



    *-------------------------------------------------------------------------------
    * merge census-tract code to file of individuals with their precincts
    *-------------------------------------------------------------------------------



    * merge file created above
    *-------------------------

    merge m:1 codigo_centro_nuevo using `census_to_precincts'

    drop if _m == 2 /* I.e., precincts without any people in our sample. */

    drop _m








    			**	**	**	**	**	**	**	**	**	**	**	**	**
    			**	**	**	**	**	**	**	**	**	**	**	**	**
    			**	**	**	**	**	**	**	**	**	**	**	**	**



    *-------------------------------------------------------------------------------
    * merge precinct characteristics from census
    *-------------------------------------------------------------------------------



    * merge file created in Prep2011Census_CensusTract.do
    *----------------------------------------------------

    merge m:1 cod_segmento using "/Users/kronick/barrio_networks/intermediate_files/precinct_characteristics/Census2011.dta"

    drop if _m == 2 /* I.e., census tracts without any people in our sample */

    drop _m



    * convert reach type to string to avoid possible confusion
    *---------------------------------------------------------

    rename reach_type temp

    decode temp, gen(reach_type)

	drop temp



    * add eigenvector Centrality to Sept 1
    *--------------------------------------

    if event == "sept1" {

			preserve

	   use "/Users/kronick/barrio_networks/intermediate_files/eigenvector_centrality/eigen_w_pairid_voz2_sept1.dta", clear

	   drop index

	   rename eigen eigenvector_centrality

	   label var eigenvector_centrality "Eigenvector Centrality"

	   drop matches

	   sort pair_id  participants

	   tempfile eigens

	   save `eigens', replace

			restore

        merge m:1 pair_id participants using `eigens'

		assert _m == 3

		drop _m

		}






				**	**	**	**	**	**	**	**	**	**	**	**	**
    			**	**	**	**	**	**	**	**	**	**	**	**	**
    			**	**	**	**	**	**	**	**	**	**	**	**	**


*-------------------------------------------------------------------------------
* anonymize and save only necessary variables
*-------------------------------------------------------------------------------




* keep
*-----

gen mapped = (entidad ~= "")

if event == "sept1" {
	
keep pair_id reach_type registration_municipio registration_estado ///
	 participant_* step_* piso_cemento licenciados participants mapped eigenvector_centrality 
	 
	 }
	 
else {	 

keep pair_id reach_type registration_municipio registration_estado ///
	 participant_* step_* piso_cemento licenciados participants mapped 
	 
	 }
	 
	 
	 
* anonymize state and municipality
*---------------------------------

merge m:1 registration_estado registration_municipio using "/Users/kronick/barrio_networks/intermediate_files/anonymizing.dta"
	
drop if _m == 2

drop _m

drop registration_estado registration_municipio e



* round licenciados and piso_cemento so that they're not de-anonymizable
*-----------------------------------------------------------------------

replace licenciados = round(licenciados, .001)

replace piso_cemento = round(piso_cemento, .001)
	

	
	* order and labels
	*-----------------
	
	order pair_id muni_group
	
	label var muni_group "Anonymized municipality ID"
	
	label var licenciados "Percent of adults in census tract with college degree"
	
	label var piso_cemento "Percent of households in census tract with dirt floor"
	
	label var mapped "In sample of states with census-tract maps" 
	
	


				**	**	**	**	**	**	**	**	**	**	**	**	**
    			**	**	**	**	**	**	**	**	**	**	**	**	**
    			**	**	**	**	**	**	**	**	**	**	**	**	**


*-------------------------------------------------------------------------------
* save
*-------------------------------------------------------------------------------



    * save
    *-----
	
	compress

    save "intermediate_files/precinct_characteristics/PersonMstr_`event'_ln.dta", replace



    * close loop over events
    *-----------------------

}









			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**
						   ** End of do file **
