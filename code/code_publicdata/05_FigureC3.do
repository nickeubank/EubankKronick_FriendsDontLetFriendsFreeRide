

	******************************************************************
	**
	**
	**		NAME:		DOROTHY KRONICK
	**		DATE: 		April 4, 2018
	**		PROJECT: 	Networks
	**
	**		DETAILS: 	Plots the distribution of within-pair
	**					differences in network exposure.
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
* Distribution of within-pair differences for Sept 1 and petition
*-------------------------------------------------------------------------------



* loop over two events
*---------------------

foreach event in "sept1" "petition" {



	* focus on participants for these graphs
	*---------------------------------------

	foreach reach_type in "all" {



        * diffusion results
        *------------------

        use "intermediate_files/precinct_characteristics/PersonMstr_`event'_ln.dta", ///
            clear



        * Focus on participants
        *----------------------

        keep if reach_type == "`reach_type'"



		* choose IV
		*----------

		local x = "step_$step_count"



        * check that previous coding error was corrected
        *-----------------------------------------------

        su step_1

        assert `r(mean)' == 0

        assert `r(max)' == 0

        count

        assert r(N) == 10000



		/* check that demographics are the same within pair
		*-------------------------------------------------

		gen tag = 0

		foreach var of varlist codigo_centro_nuevo psuv registration_female {

			egen long mean = mean(`var'), by(pair_id)

			replace tag = 1 if `var' ~= mean

			drop mean

			} */



		* order
		*------

		sort `x'

		
		
		* Get overall means before differencing
		*-------------------------------------

		sum `x'
		
		local cleaned_statistic: display %12.1fc `r(mean)'
		
		display "`cleaned_statistic'"
		
		file open myfile using $barrios_dir/results/exposure_densities/undifferenced_avg_`event'_`reach_type'.tex, write text replace
		
		file write myfile "`cleaned_statistic'"
		
		file close myfile

		
		
		* Get overall means before differencing
		*-------------------------------------

		sum `x'
		
		local cleaned_statistic: display %12.1fc `r(mean)'
		
		display "`cleaned_statistic'"
		
		file open myfile using $barrios_dir/results/exposure_densities/undifferenced_avg_`event'_`reach_type'.tex, write text replace
		
		file write myfile "`cleaned_statistic'"
		
		file close myfile


		
		* within-pair difference
		*-----------------------

		keep pair_id participants `x'

		qui su `x'

		local mean_dv = `r(mean)'

		reshape wide `x', i(pair_id) j(participants)

		gen abs_dif = `x'1 - `x'0



		* within-pair deviation from mean
		*--------------------------------

		gen dev_1 = `x'1 - 0.5*(`x'1 + `x'0)

		gen dev_0 = `x'0 - 0.5*(`x'1 + `x'0)



		* graph, densities of within-pair deviations
		*-------------------------------------------

		qui su dev_1, d

		local top = `r(p99)'

		qui su dev_0, d

		local bottom = `r(p1)'

		local xlab

		if "`event'" == "petition" & "`reach_type'" == "participant" local xlab "-5(1)5"

		if "`event'" == "sept1" & "`reach_type'" == "participant" local xlab "-1.5(.5)1.5"

		#delimit;

		twoway (kdensity dev_1 if dev_1 > `bottom' & dev_1 < `top', lcolor(gs10) lwidth(thick))

			   (kdensity dev_0 if dev_0 > `bottom' & dev_0 < `top', lcolor(black) lpattern(dash)),

		graphregion(fcolor(white) lcolor(white) margin(zero))

        plotregion(fcolor(white) lstyle(none) lcolor(white) ilstyle(none))

        xsize(7) ysize(5)

        ytitle("Density", size(vlarge))

		xtitle("")

        yscale(lcolor(none))

		ylabel(, labsize(vlarge) glcolor(white) angle(horizontal))

		xlabel(`xlab', labsize(vlarge))

		xscale(lcolor(none))

        legend(pos(11) cols(1) ring(0) symxsize(*.5) region(lcolor(white)) size(large)
			   order(1 "Participants" 2 "Matched non-" "participants"))

        title("`event', mean = `mean_dv'");

        graph export "$barrios_dir/results/exposure_densities/Deviations_`x'_`event'_`reach_type'.pdf", replace;

        #delimit cr



* close loops over events and reach types
*----------------------------------------

}

}
