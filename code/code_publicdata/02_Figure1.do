

	******************************************************************
	**
	**
	**		NAME:		DOROTHY KRONICK
	**		DATE: 		April 4, 2018
	**		PROJECT: 	Networks
	**
	**		DETAILS: 	Results graphs plots for individual-level
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
* Main results graphs: Sept 1, petition
*-------------------------------------------------------------------------------



* loop over two events
*---------------------

foreach event in "sept1" "petition" {



	* loop over reach types
	*----------------------

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



        * de-meaned network exposure
        *---------------------------

		egen mean_`x' = mean(`x'), by(pair_id)

		gen dm_`x' = `x' - mean_`x'



		* bins of de-meaned nework exposure
		*----------------------------------

		sort dm_`x'

		gen bin = _n - 200 if _n > 200 & _n < 9800

		replace bin = ceil(bin / 240)

		egen bin_median = median(dm_`x'), by(bin)

		egen bin_dv_mean = mean(participants), by(bin)



        * cut off top 2%
        *---------------

        *qui su dm_`x', d

		local top = 9800

		local min = 200



		* get fitted values
		*------------------

		lpoly participants dm_`x' if _n <= `top' & _n >= `min', ///
		      kernel(gaussian) degree(1) gen(dm_`x'_x dm_`x'_y) se(fitted_se) ///
			  nograph

	    gen ci_upper = dm_`x'_y + 1.96 * fitted_se

	    gen ci_lower = dm_`x'_y - 1.96 * fitted_se


		* x axis labels
		*--------------

		local xlabel

		if "`reach_type'" == "participant" {

			local xlabel "-1(.25)1"

			}

		if "`reach_type'" == "participant" & "`event'" == "petition" {

			local xlabel "-4(1)4"

			}

		if "`reach_type'" == "all" {

			local xlabel "-50(25)50"

			}



		* titles
		*-------

		if "`event'" == "sept1" {

			local event_title = "Toma de Caracas Protest"

			}

		else if "`event'" == "petition" {

			local event_title = "Petition Signing"

			}

		else {

			local event_title = "`event'"

			}

			

        * graph: figure for paper
        *------------------------

        #delimit;

		twoway (scatter bin_dv_mean bin_median if _n < `top' & _n > `min',
				mcolor(black) msize(small) mcolor(gs8))

			   (line ci_upper dm_`x'_x if ci_upper < 1,
			    lcolor(gs10) lpattern(shortdash) lwidth(thin))

			   (line ci_lower dm_`x'_x if ci_lower > 0,
			    lcolor(gs10) lpattern(shortdash) lwidth(thin))

			   (line dm_`x'_y dm_`x'_x if dm_`x'_y < 1,
			    lcolor(black)),

		graphregion(fcolor(white) lcolor(white) margin(zero))

        plotregion(fcolor(white) lstyle(none) lcolor(white) ilstyle(none))

        xsize(7) ysize(5)

        ytitle("Pr(Participation)", size(vlarge))

        yscale(lcolor(none) range(.35 .9))

		ylabel(0(.2)1, labsize(vlarge) glcolor(white) angle(horizontal))

		xlabel(`xlabel', labsize(vlarge))

		xscale(lcolor(none))

        legend(off)

        title("`event_title'");

        graph export "$barrios_dir/results/binnedscatters/`event'_ln_`x'_reach`reach_type'.pdf", replace;

		#delimit cr


	* close loop over reach types
	*----------------------------

	}



* close loop over dates
*----------------------

}







			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**
						   ** End of do file **
