

	******************************************************************
	**
	**
	**		NAME:		NICK EUBANK & DOROTHY KRONICK
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
* Estimate parameters of y = alpha + beta * quantile(demeaned network exposure)
*-------------------------------------------------------------------------------



* loop over dates
*----------------

foreach event in $event_list {



* loop over reach types
*----------------------

foreach reach_type in "all" "participant" {



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



* de-meaned network exposure
*---------------------------

local iv "step_$step_count"

egen mean_`iv' = mean(`iv'), by(pair_id)

gen dm_`iv' = `iv' - mean_`iv'

qui su dm_`iv', d

local max = `r(p95)'

local min = `r(p5)'

local sd = `r(sd)'



* reg
*----

areg participants `iv', a(pair_id) cl(pair_id)

eststo `event'_`reach_type': nlcom (`iv'_`reach_type': (`sd') * _b[`iv']), post



	* export to place in-line in text
	*--------------------------------

	local cleaned_statistic: display %12.1fc 100*_b[`iv'_`reach_type']

	display "Stat:" "`cleaned_statistic'"

	file open myfile using $barrios_dir/results/effects_main_step_${step_count}_`event'_`reach_type'_onestd.tex, write text replace

	file write myfile "`cleaned_statistic'"

	file close myfile



* close loops over reach types and events
*----------------------------------------

}

}




* create table
*-------------

#delimit;

esttab using "results/tables/linear.tex",

       replace alignment(S)

       keep(`iv'*) nodepvars mtitle

       gaps compress se nostar fragment

       bookt nolines obslast nonumbers

	   cells(b(fmt(3)) se(fmt(a1)))

	   parentheses;

#delimit cr








			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**



*-------------------------------------------------------------------------------
* Additional table formatting
*-------------------------------------------------------------------------------



* read in previous results
*-------------------------

insheet using "results/tables/linear.tex", ///
        clear delim("&")



* make column titles into var names
*----------------------------------

foreach var of varlist v* {

	replace `var' = subinstr(`var', "\multicolumn{1}{c}{", "", .)

	replace `var' = subinstr(`var', "}", "", .)

	replace `var' = subinstr(`var', "\_", "_", .)

	replace `var' = subinstr(`var', "\\", "", .) if _n == 1

	}

replace v1 = "label" if _n == 1

foreach var of varlist v* {

	local name = `var'[1]

	rename `var' `name'

	}

drop in 1/2



* drop extra rows
*----------------

drop if label == "\addlinespace"



* parentheses
*------------

foreach var of varlist * {

	replace `var' = "(" + `var' + ")" if regexm(label[_n-1], "step") & `var' ~= ""

	}






			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**



*-------------------------------------------------------------------------------
* format table and send to TeX
*-------------------------------------------------------------------------------



* labels
*-------

replace label = "Exposure to participants ($ N_{i}^p)$" ///
				if regexm(label, "participant")

replace label = "Communication centrality ($ N_{i}^g$)" ///
				if regexm(label, "all")



* SES placebo
*------------

gen latex_table3 = label

foreach var of varlist aug*all sept*all  {

	replace latex_table3 = latex_table3 + " & " + `var' ///

	}

replace latex_table3 = latex_table3 + " \\" if latex_table3 ~= ""

replace latex_table3 = latex_table3 + "[-2pt]" if regexm(label, "\^g")

replace latex_table3 = latex_table3 + " \addlinespace[0.4ex]" if label == "" & latex_table3 ~= ""

replace latex_table3 = "\rowfont{\scriptsize} " + latex_table3 if label == "" & latex_table3 ~= ""

outsheet latex_table3 using "results/tables/Effects_Inside_SES.tex" if  (_n <=2), noquote nonames replace



* main results table
*-------------------

gen latex_table1 = label

foreach var of varlist sept1_all petition_all {

	replace latex_table1 = latex_table1 + " & " + `var'

	}

replace latex_table1 = latex_table1 + " \\"

replace latex_table1 = latex_table1 + "[-2pt]" if regexm(label, "-")

replace latex_table1 = latex_table1 + " \addlinespace[0.4ex]" if label == ""

replace latex_table1 = "\rowfont{\scriptsize} " + latex_table1 if label == ""

outsheet latex_table1 using "results/tables/Effects_Inside_Main.tex" if _n <=2, noquote nonames replace



* main results with participant exposure table
*---------------------------------------------

gen latex_table4 = label

foreach var of varlist sept1_all sept1_participant petition_all  petition_participant {

	replace latex_table4 = latex_table4 + " & " + `var'

	}

replace latex_table4 = latex_table4 + " \\"

replace latex_table4 = latex_table4 + "[-2pt]"

replace latex_table4 = latex_table4 + " \addlinespace[0.4ex]" if label == ""

outsheet latex_table4 using "results/tables/Effects_Inside_ParticipantExposure.tex" if _n ~= 5, noquote nonames replace








			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**




*-------------------------------------------------------------------------------
* export average of placebos to place in-line in text
*-------------------------------------------------------------------------------



* Need to update if labels change:
*---------------------------------

gen rowid = "all" if label == "Communication centrality ($ N_{i}^g$)"



* checks that conditions worked
*------------------------------

local check: di rowid[1]
di "`check'"

assert "`check'" == "all"

local type = "all"

* gen average of placebos
preserve
    keep if rowid=="`type'"
    keep aug*_`type' sept*_`type'
    drop sept1_`type'
    d
    assert c(k) == 8
    gen aggregator = 0
    foreach var of varlist aug* sept* {
        rename `var' temp
        destring temp, gen(`var')
        replace aggregator = aggregator + `var'
        drop temp
    }
    gen placebo_avg = (aggregator / 8)
    sum placebo_avg
    local placebo_pct_change = `r(mean)' * 100
restore

local cleaned_statistic: display %12.1fc `placebo_pct_change'
display "`cleaned_statistic'"

file open myfile using $barrios_dir/results/placebo_avg_step_${step_count}_`type'_onestd.tex, write text replace
file write myfile "`cleaned_statistic'"
file close myfile

















			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**
						   ** End of do file **
