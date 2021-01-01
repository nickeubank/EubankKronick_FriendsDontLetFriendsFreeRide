

	******************************************************************
	**
	**
	**		NAME:		DOROTHY KRONICK
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
* descriptives
*-------------------------------------------------------------------------------


* density of people reached
*--------------------------

#delimit;

twoway kdensity `x' [aw = pweight], lcolor(black)

		graphregion(fcolor(white) lcolor(white) margin(zero))

        plotregion(fcolor(white) lstyle(none) lcolor(white) ilstyle(none))

        xsize(5) ysize(5)

        ytitle("Density", size(vlarge))

        xtitle("Network exposure at t=`paper_step_count'", size(vlarge))

        yscale(lcolor(none))

		ylabel(, labsize(vlarge) glcolor(white) angle(horizontal))

		xlabel(, labsize(vlarge))

		xscale(lcolor(none))

        legend(off)

        title("Density of `x'");

        graph export "$barrios_dir/results/descriptives/Density_`x'.pdf", replace;

        #delimit cr



* exposure and cement floor
*--------------------------

#delimit;

twoway (lpolyci `x' piso_cemento [aw = pweight],
				lcolor(gs5) degree(1)
				lpattern(dot) ciplot(rline) lwidth(thin))

	   (lpoly `x' piso_cemento [aw = pweight],
			    lcolor(black) degree(1)),

		graphregion(fcolor(white) lcolor(white) margin(zero))

        plotregion(fcolor(white) lstyle(none) lcolor(white) ilstyle(none))

        xsize(5) ysize(5)

        ytitle("Network exposure", size(vlarge))

        xtitle("% with cement floor", size(vlarge))

        yscale(lcolor(none))

		ylabel(0(20)90, labsize(vlarge) glcolor(white) angle(horizontal))

		xlabel(, labsize(vlarge))

		xscale(lcolor(none))

        legend(off)

        title("Exposure and poverty");

        graph export "$barrios_dir/results/descriptives/`x'_v_piso_cemento.pdf", replace;

        #delimit cr



* exposure and education
*-----------------------

#delimit;

twoway (lpolyci `x' licenciados [aw = pweight],
				lcolor(gs5) degree(1)
				lpattern(dot) ciplot(rline) lwidth(thin))

	   (lpoly `x' licenciados [aw = pweight],
			    lcolor(black) degree(1)),

		graphregion(fcolor(white) lcolor(white) margin(zero))

        plotregion(fcolor(white) lstyle(none) lcolor(white) ilstyle(none))

        xsize(5) ysize(5)

        ytitle("Network exposure", size(vlarge))

        xtitle("% with college degree", size(vlarge))

        yscale(lcolor(none))

		ylabel(0(20)90, labsize(vlarge) glcolor(white) angle(horizontal))

		xlabel(, labsize(vlarge))

		xscale(lcolor(none))

        legend(off)

        title("Exposure and education");

        graph export "$barrios_dir/results/descriptives/`x'_v_bachilleres.pdf", replace;

        #delimit cr



* density of log people reached
*------------------------------

#delimit;

twoway kdensity `iv' [aw = pweight], lcolor(black)

		graphregion(fcolor(white) lcolor(white) margin(zero))

        plotregion(fcolor(white) lstyle(none) lcolor(white) ilstyle(none))

        xsize(5) ysize(5)

        ytitle("Density", size(vlarge))

        xtitle("ln(Network exposure)", size(vlarge))

        yscale(lcolor(none))

		ylabel(, labsize(vlarge) glcolor(white) angle(horizontal))

		xlabel(, labsize(vlarge))

		xscale(lcolor(none))

        legend(off)

        title("Density of `iv'");

        graph export "$barrios_dir/results/descriptives/Density_`iv'.pdf", replace;

        #delimit cr



* protest and exposure
*---------------------

qui su `iv', d

#delimit;

twoway (lpolyci participant_sept1 `iv' if `iv' >= `r(p1)' & `iv' <= `r(p99)' [aw = pweight],
				lcolor(gs5) degree(1)
				lpattern(dot) ciplot(rline) lwidth(thin))

	   (lpoly participant_sept1 `iv' if `iv' >= `r(p1)' & `iv' <= `r(p99)' [aw = pweight],
			    lcolor(black) degree(1)),

		graphregion(fcolor(white) lcolor(white) margin(zero))

        plotregion(fcolor(white) lstyle(none) lcolor(white) ilstyle(none))

        xsize(5) ysize(5)

        ytitle("Pr(Protest)", size(vlarge))

        xtitle("ln(Network exposure)", size(vlarge))

        yscale(lcolor(none))

		ylabel(-.025(.05).125, labsize(vlarge) glcolor(white) angle(horizontal))

		xlabel(2(1)5, labsize(vlarge))

		xscale(lcolor(none))

        legend(off)

        title("Protest and exposure");

        graph export "$barrios_dir/results/descriptives/protest_v_`iv'.pdf", replace;

        #delimit cr



* petition and exposure
*----------------------

qui su `iv', d

#delimit;

twoway (lpolyci participant_petition `iv' if `iv' >= `r(p5)' & `iv' <= `r(p95)' [aw = pweight],
				lcolor(gs5) degree(1)
				lpattern(dot) ciplot(rline) lwidth(thin))

	   (lpoly participant_petition `iv' if `iv' >= `r(p5)' & `iv' <= `r(p95)' [aw = pweight],
			    lcolor(black) degree(1)),

		graphregion(fcolor(white) lcolor(white) margin(zero))

        plotregion(fcolor(white) lstyle(none) lcolor(white) ilstyle(none))

        xsize(5) ysize(5)

        ytitle("Pr(Sign petition)", size(vlarge))

        xtitle("ln(Network exposure)", size(vlarge))

        yscale(lcolor(none))

		ylabel(, labsize(vlarge) glcolor(white) angle(horizontal))

		xlabel(, labsize(vlarge))

		xscale(lcolor(none))

        legend(off)

        title("Petition and exposure");

        graph export "$barrios_dir/results/descriptives/petition_v_`iv'.pdf", replace;

        #delimit cr



