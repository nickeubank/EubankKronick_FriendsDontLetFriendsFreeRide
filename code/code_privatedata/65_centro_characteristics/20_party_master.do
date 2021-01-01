
	******************************************************************
	**
	**
	**		NAME:		DOROTHY KRONICK
	**		DATE: 		March 19, 2018
	**		PROJECT: 	Networks
	**
	**		DETAILS: 	This file creates merges precinct
	**					characteristics to the expansion results,
	**					for the random samples of PSUV and MUD
	**					voters.
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
			 closest to the protest. */

			 
			 
* loop over the six states we have
*---------------------------------

foreach state in aragua carabobo df lara miranda vargas {

	
	
* import spatial join
*---------------------

import delimited "intermediate_files/precinct_characteristics/joined_`state'.csv", ///
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



* loop over parties
*------------------

foreach party in MUD PSUV {



* get individual characteristics
*-------------------------------

use "intermediate_files/individual_participants_and_matches/demographics_participants_`party'_n5000.dta", clear

append using "intermediate_files/individual_participants_and_matches/demographics_matches_`party'_n5000.dta"



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

merge 1:m pair_id participants using ///
      "intermediate_files/individual_diffusion_results/aggregated_`party'_10steps_indiv_ln_n5000_2019_02_25.dta"

drop _m



* for now
*--------

keep if voz_threshold == 2 



* which file
*-----------

gen start = "`party'"



* save
*-----

tempfile expansion`party'

save `expansion`party''

}


* append
*-------

use `expansionPSUV', clear

append using `expansionMUD'





		

			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**
	


*-------------------------------------------------------------------------------
* merge census-tract code to file of individuals with their precincts	
*-------------------------------------------------------------------------------



* merge file created above
*-------------------------

merge m:1 codigo_centro_nuevo using `census_to_precincts'

drop if _m == 2

drop _m

	/* Note: */





		

			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**
	


*-------------------------------------------------------------------------------
* merge precinct characteristics from census	
*-------------------------------------------------------------------------------



* merge file created in Prep2011Census_CensusTract.do
*----------------------------------------------------

merge m:1 cod_segmento using "intermediate_files/precinct_characteristics/Census2011.dta"

drop if _m == 2

drop _m

	/* Note, 7,278 of 7,302 people have census-tract
	         characteristics matched. Come back 
			 to missings here; we should have all of them. */





		

			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**
	


*-------------------------------------------------------------------------------
* save	
*-------------------------------------------------------------------------------



* save
*-----

save "intermediate_files/precinct_characteristics/PersonMstr.dta", replace
