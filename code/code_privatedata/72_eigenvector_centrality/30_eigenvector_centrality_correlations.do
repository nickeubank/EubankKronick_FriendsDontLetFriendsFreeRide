

	******************************************************************
	**
	**
	**		NAME:		DOROTHY KRONICK
	**		DATE: 		July 26, 2018
	**		PROJECT: 	Networks
	**
	**		DETAILS: 	Results table for individual-level
	**					analysis.
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



* clear
*------

clear

eststo clear



* set more off
*-------------

set more off



* set directory
*--------------

cd "$barrios_dir"








			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**



*-------------------------------------------------------------------------------
* correlations
*-------------------------------------------------------------------------------



* choose event
*-------------

local event = "sept1"



* choose reach type
*------------------

local reach_type = "all"



* diffusion results
*------------------

use "intermediate_files/precinct_characteristics/PersonMstr_`event'_ln.dta", ///
    clear

	
	
* choose reach type
*------------------

keep if reach_type == "`reach_type'"	



* display
*--------

di "`event', `reach_type'"



* check that previous coding error was corrected
*-----------------------------------------------

su step_1

assert `r(mean)' == 0

assert `r(max)' == 0

count

assert r(N) == 10000




* correlations, capture in matrix and move to memory
*---------------------------------------------------

corr step_2-step_10 eigenvector_centrality

mat cor = r(C)

clear

svmat cor








			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**



*-------------------------------------------------------------------------------
* make TeX table
*-------------------------------------------------------------------------------



* format
*-------

format cor* %4.3f

tostring cor*, replace usedisplayformat force



* diagonal
*---------

forvalues i = 1/10 {

	replace cor`i' = "" if _n < `i'
	
	}


	
* labels
*-------

gen label = ""

forvalues i = 1/9 {

	replace label = " $ N_{i,`i'}^a $ " if _n == `i'
	
	}

replace label = "E.C." if _n == 10

	
	

* TeX
*----	
	
gen latex = label	
	
foreach var of varlist cor1-cor10 {

	replace latex = latex + " & " + `var'

	}

replace latex = latex + " \\" 

outsheet latex using "results/tables/StepCorrelations.tex", ///
         noquote nonames replace










			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**
						   ** End of do file **



