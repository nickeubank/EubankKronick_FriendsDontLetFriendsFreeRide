

	******************************************************************
	**
	**
	**		NAME:		NICK EUBANK & DOROTHY KRONICK
	**		DATE: 		July 30, 2018
	**		PROJECT: 	Networks
	**
	**		DETAILS: 	Is exposure a strong predictor
	**				    in the general population?
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
* append participant samples to party samples
*-------------------------------------------------------------------------------



* signers
*--------

use "intermediate_files/precinct_characteristics/PersonMstr_petition_ln.dta", clear

keep if reach_type == "all" /* We don't have petition-participant reach for party samples */

keep if participants == 1

gen samp = "Signers"

tempfile signers

save `signers'



* protesters
*-----------

use "intermediate_files/precinct_characteristics/PersonMstr_sept1_ln.dta", clear

keep if reach_type == "all" /* We don't have sept1-participant reach for MUD and PSUV samples */

keep if participants == 1

gen samp = "Protesters"

tempfile protesters

save `protesters'



* MUD sample
*-----------

use "intermediate_files/precinct_characteristics/PersonMstr_MUD_ln.dta", clear

keep if participant_MUD == 1 /* Random sample of MUD voters */

keep if reach_type == "all"

gen samp = "MUD"

tempfile MUD

save `MUD'



* PSUV sample
*------------

use "intermediate_files/precinct_characteristics/PersonMstr_PSUV_ln.dta", clear

keep if participant_PSUV == 1 /* Random sample of PSUV voters */

keep if reach_type == "all"

gen samp = "PSUV"

tempfile PSUV

save `PSUV'



* append
*-------

use `signers', clear

append using `protesters'

append using `MUD'

append using `PSUV'



* check that previous coding error was corrected
*-----------------------------------------------

su step_1

assert `r(mean)' == 0

assert `r(max)' == 0

count

assert r(N) == 20000 /* 5,000 from each of four samples */








			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**



*-------------------------------------------------------------------------------
* create some additional variables
*-------------------------------------------------------------------------------



* weights
*--------

gen pweight = 1 / (5000 / 5339833) if samp == "PSUV"

replace pweight = 1 / (5000 / 10000000) if samp == "MUD"

replace pweight = 1 / (5000 / 1700000) if samp == "Signers"

replace pweight = 1 / (5000 / 192500) if samp == "Protesters" /* 192,500 Protesters from outside Caracas */



* iv
*---

local x "step_$step_count"

local paper_step_count = $step_count - 1

gen ln_`x' = ln(`x')

local iv "ln_`x'"



* identify and keep sample
*-------------------------

qui reg participant_sept1 `iv' if mapped == 1

keep if e(sample)






			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**



*-------------------------------------------------------------------------------
* regressions
*-------------------------------------------------------------------------------



* clear
*------

eststo clear



* save values so as to standardize coefficients later
*----------------------------------------------------

foreach var of varlist `iv' piso_cemento licenciados {

	qui su `var', d

	local max_`var' = `r(p95)'

	local min_`var' = `r(p5)'

	}



* de-meaned values for FE regressions
*------------------------------------

foreach var of varlist `iv' piso_cemento licenciados {

	egen mean_`var' = mean(`var'), by(muni_group)

	gen dm_`var' = `var' - mean_`var'

	qui su dm_`var', d

	local max_dm_`var' = `r(p95)'

	local min_dm_`var' = `r(p5)'

	}



* loop over DVs
*--------------

foreach dv in participant_sept1 participant_petition {



* regression number
*------------------

local rnum = 1



* include petition signing as a regressor when predicting protest
*----------------------------------------------------------------

if "`dv'" == "participant_sept1" local signed = "participant_petition"

if "`dv'" == "participant_sept1" local signed_nl = "(participant_petition: _b[participant_petition])"

if "`dv'" == "participant_petition" local signed

if "`dv'" == "participant_petition" local signed_nl



* bivariate
*----------

reg `dv' `iv' [aw = pweight], cl(muni_group)

eststo: nlcom (`iv': (`max_`iv'' - `min_`iv'')*_b[`iv']), post



* adding municipality FEs and political controls
*-----------------------------------------------

xi: reg `dv' `iv' participant_PSUV `signed' ///
		i.muni_group [aw = pweight], cl(muni_group)


eststo: nlcom (`iv': (`max_dm_`iv'' - `min_dm_`iv'')*_b[`iv'])  ///
	          (participant_PSUV: _b[participant_PSUV]) `signed_nl', post



* adding municipality FEs, political controls, SES
*-------------------------------------------------

xi: reg `dv' `iv' piso_cemento licenciados ///
		participant_PSUV `signed' ///
		i.muni_group [aw = pweight], cl(muni_group)

eststo: nlcom (`iv': (`max_dm_`iv'' - `min_dm_`iv'')*_b[`iv']) ///
			  (participant_PSUV: _b[participant_PSUV]) `signed_nl' ///
	          (piso_cemento: (`max_dm_piso_cemento' - `min_dm_piso_cemento')*_b[piso_cemento]) ///
	          (licenciados: (`max_dm_licenciados' - `min_dm_licenciados')*_b[licenciados]), post



* close loop over DVs
*--------------------

}









			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**



*-------------------------------------------------------------------------------
* make table
*-------------------------------------------------------------------------------



* fragment
*---------

#delimit;

esttab using "results/tables/Country_Inside.tex",

       replace alignment(S) substitute(\_ _)

       gaps compress se nostar

       bookt fragment nomtitles

	   nodepvars nonumbers nolines obslast

	   keep(`iv' participant* piso_cemento licenciados)

	   order(`iv' participant* piso_cemento licenciados)

	   cells(b(fmt(3)) se(fmt(a1) par));

#delimit cr





			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**



*-------------------------------------------------------------------------------
* additional formatting
*-------------------------------------------------------------------------------



* insheet results
*----------------

insheet using "results/tables/Country_Inside.tex", clear delim("&")



* drop extra rows
*----------------

drop if v1 == "\addlinespace"

drop in 1/1



* labels
*-------

replace v1 = "Communication centrality ($ N_{i,\StepCountInText}^g$)" ///
		     if v1 == "`iv'"

replace v1 = "Registered in PSUV (gov't party)" ///
		     if v1 == "participant_PSUV"

replace v1 = "Signed petition" ///
		     if v1 == "participant_petition"

replace v1 = "\% Neighborhood w/ cement floor" ///
		     if v1 == "piso_cemento"

replace v1 = "\% Neighborhood w/ college degree" ///
		     if v1 == "licenciados"



* latex code
*-----------

gen latex = v1

foreach var of varlist v2-v7 {

	replace latex = latex + " & " + `var'

	}


replace latex = latex + "[-2pt]" if v1 ~= "" & v1 ~= "Observations"

replace latex = latex + " \addlinespace[0.4ex]" if v1 == ""

replace latex = "\rowfont{\scriptsize} " + latex if v1 == ""

outsheet latex using "results/tables/Effects_Inside_Population.tex", noquote nonames replace


