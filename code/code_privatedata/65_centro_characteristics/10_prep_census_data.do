
	******************************************************************
	**
	**
	**		NAME:		DOROTHY KRONICK
	**		DATE: 		March 19, 2018
	**		PROJECT: 	Networks
	**
	**		DETAILS: 	This file creates a census-tract-level
	**                  measure of SES measures from the 
	**                  2011 census. 
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

cd "/Users/djkronick/Dropbox/"



* matsize
*--------

set matsize 5000






		

			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**
	


*-------------------------------------------------------------------------------
* prepare place codes
*-------------------------------------------------------------------------------



* list of place categories
*-------------------------

local places ENTIDAD MUNICIPI PARROQUI CENTROPO SEGMENTO CARGA ///
             TIPO_SEG SECTOR MANZANA PARCELA EDIFICA VIVIENDA	



* save temporary dta files of each place class
*---------------------------------------------

foreach i of local places {
             
	insheet using "Venezuela/Census/2011/Microdatos/csv/`i'.csv", delim(";") clear       	
	
	tempfile `i'_d
			 
	save ``i'_d', replace
			 
	}
			 
			 
			 
* merge place codes
*------------------			 

use `ENTIDAD_d', clear

local n = 2

foreach i of local places {

	if "`i'" ~= "VIVIENDA" {

	local j = lower("`i'")
			 
	local newfile = "`: word `n' of `places''"
			 
	merge 1:m `j'_ref_id using "``newfile'_d'"
	
	drop _m
					 
    local n = `n' + 1
    
    }
    
    else continue
			 
	}
	


* keep only place codes and place names
*--------------------------------------

keep *_ref_id entidad municipio parroquia centropo segmento
	
	
	
* save
*-----

tempfile place_ids

save `place_ids', replace


	
	
	

		

			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**
	


*-------------------------------------------------------------------------------
* vivienda data
*-------------------------------------------------------------------------------



* original data
*--------------
	
insheet using "Venezuela/Census/2011/Microdatos/csv/VIVIENDA.csv", delim(";") clear


* merge place codes
*------------------

merge 1:1 vivienda using `place_ids'



* piso cemento
*-------------

	*Codebook (p. 6): http://www.ine.gob.ve/documentos/Boletines_Electronicos/Estadisticas_Demograficas/Boletin_Demografico/pdf/02-N022013.pdf
	
gen piso_cemento = (matpiso == 2)

replace piso_cemento = . if matpiso == 0	



* number of dwellings
*--------------------

gen vivendas_count = 1



* collapse
*---------

collapse (sum) vivendas_count ///
         (mean) piso_cemento ///
         (first) entidad municipio parroquia centropo segmento, ///
         by(entidad_ref_id municipi_ref_id parroqui_ref_id segmento_ref_id)
	

	
* save
*-----
	
tempfile piso_cemento

save `piso_cemento'

	

	
		

			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**
	


*-------------------------------------------------------------------------------
* household data
*-------------------------------------------------------------------------------



* original data
*--------------
	
insheet using "Venezuela/Census/2011/Microdatos/csv/HOGAR.csv", delim(";") clear



* merge place codes
*------------------

merge m:1 vivienda using `place_ids'

drop if _m == 2



* save place codes for persona file
*----------------------------------

tempfile places2

savesome *ref_id using `places2'



* number of households
*---------------------

gen count = 1 



* recode
*-------

foreach var of varlist tvcable tv tlffijo internet {

replace `var' = . if `var' == 0

replace `var' = 0 if `var' == 2

}



* poverty
*--------

gen pobre = 1 if pobreza == 1 | pobreza == 2

replace pobre = 0 if pobreza == 0



* collapse
*---------

collapse (sum) count ///
         (mean) tv tvcable tlffijo internet pobre ///
         (first) entidad municipio parroquia centropo segmento, ///
         by(entidad_ref_id municipi_ref_id parroqui_ref_id segmento_ref_id)

		 
* save
*-----

tempfile hogares

save `hogares'		 
		

	
	
	

		

			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**
	


*-------------------------------------------------------------------------------
* person data
*-------------------------------------------------------------------------------



* original data
*--------------
	
insheet using "Venezuela/Census/2011/Microdatos/csv/PERSONA.csv", delim(";") clear



* interested in education level of adults
*----------------------------------------

keep if edad >= 25 & edad ~= .



* high school and college
*------------------------

gen bachilleres = (niveleduc >= 5)

replace bachilleres = . if niveleduc == . | niveleduc == 0

gen licenciados = (niveleduc == 7)

replace licenciados = . if niveleduc == . | niveleduc == 0



* merge
*------

merge m:1 hogar_ref_id using `places2'

	

* collapse
*---------

	/* Note: segmento IDs are unique within parroquia,
	         even though centro poblado is between parroquia
			 and segmento. */
			
gen count_adultos = 1

collapse (sum) count_adultos ///
         (mean) bachilleres licenciados, ///
         by(entidad_ref_id municipi_ref_id parroqui_ref_id segmento_ref_id)


	

		

			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**
	


*-------------------------------------------------------------------------------
* merge
*-------------------------------------------------------------------------------



* merge person-level variables to household and structure (vivienda)
*-------------------------------------------------------------------

merge 1:1 segmento_ref_id using `hogares'

drop _m

merge 1:1 segmento_ref_id using `piso_cemento'

drop if _m == 2

drop _m



	

		

			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**
	


*-------------------------------------------------------------------------------
* save
*-------------------------------------------------------------------------------



* string segmento ID
*-------------------

tostring entidad-parroquia segmento, replace

foreach var of varlist entidad-parroquia {

	replace `var' = "0" + `var' if length(`var') == 1
	
	}

destring centropo, replace ignore(A B C D E F G) force

tostring centropo, replace

replace centropo = "." if length(centropo) > 3

foreach var of varlist centropo segmento {

	replace `var' = "00" + `var' if length(`var') == 1	

	replace `var' = "0" + `var' if length(`var') == 2

	}
	
gen cod_segmento = entidad + municipio + parroquia + centropo + segmento



* duplicates (come back to this)
*------------------------------

duplicates tag cod_segmento, gen(tag)

drop if tag > 0

drop tag



* save
*-----

save "barrio_networks/intermediate_files/precinct_characteristics/Census2011.dta", replace









