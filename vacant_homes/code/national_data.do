/*
	This file imports, cleans, and plots data on vacant homes
	
	Date created:  22 Jan 2022
	Last modified: 22 Jan 2022
	Author: Danny Edgel
*/

/*
	Housekeeping
*/

// clear workspace
clear all


// establish project directory
cd "C:/Users/edgel/Google Drive/100 Beers/vacant_homes"


/*
	Load, combine, and clean the data
*/

// append files into a panel
forval y = 2005/2019{
    qui{
		preserve 
		import delimited data/us_acs_data_`y'.csv, clear varn(1)
		g year = `y'
		order year
		drop geoid name *m
		qui destring *, replace
		save temp, replace
		restore 
		append using temp
	}
}

// label variables
lab var b01001_001e "Population"
lab var b25001_001e "Housing Units"
lab var b25002_002e "Occupied Units"
lab var b25002_003e "Vacant Units"
lab var b25003_001e "Tenure"
lab var b25004_001e "Total Vacant"
lab var b25004_002e "For Rent"
lab var b25004_003e "Rented but Unoccupied"
lab var b25004_004e "For Sale"
lab var b25004_005e "Sold but Unoccupied"
lab var b25004_006e "Seasonal/Recreational/etc."
lab var b25004_007e "Migrant Worker Housing"
lab var b25004_008e "Other Vacant Units"
lab var b25005_001e "Total Vacant"
lab var b25005_002e "Vacant with Residence Elsewhere"
lab var b25005_003e "Other Vacant"

// define variables in the millions
foreach var of varlist b*{
    replace `var' = `var' / 1000000
}

/*
	Plot the data 
*/


// plot vacant homes by reason
preserve
g sale_or_rent 		= b25004_002e + b25004_004e
g rented_or_sold	= b25004_003e + b25004_005e

lab var sale_or_rent 	"Listed for Sale/Rent"
lab var rented_or_sold	"Sold/Rented but Unoccupied"
   
loc vars b25004_008e sale_or_rent b25004_006e rented_or_sold b25004_007e 

forval i = 2/`: word count `vars''{
    loc vbl `: word `=`i'-1' of `vars''
	loc vbn `: word `i' of `vars''
	replace `vbn' = `vbn' + `vbl'
}

g zero = 0

mylabels 0(2.5)20, local(ylabs) suffix(mil)

loc x = `: word count `vars''
loc y = `x'
tw	///
	rarea `: word `x--' of `vars'' `: word `x' of `vars'' 	year, col(red) 	||	///
	rarea `: word `x--' of `vars'' `: word `x' of `vars'' 	year, col(gs12) ||	///
	rarea `: word `x--' of `vars'' `: word `x' of `vars'' 	year, col(gs8) 	||	///
	rarea `: word `x--' of `vars'' `: word `x' of `vars'' 	year, col(gs4) 	||	///
	rarea `: word `x--' of `vars'' zero						year, col(gs0) 		///
		ylab(`ylabs', angle(horizontal) nogrid labs(small))						///
		title("Vacant homes in the U.S. by vacancy reason") leg(off)			///
		xlab(2005(1)2019, angle(45) nogrid labs(small)) 						///
		graphregion(color(white) margin(r=35)) subtitle(" ")					///
		text(17.5 	2022 "`: var lab `: word `y--' of `vars'''", 	///
										m(zero)	col(red) size(small) j(left))	///
		text(16 	2022.5 "`: var lab `: word `y--' of `vars'''", 	///
										m(zero)	col(gs2) size(small) j(left))	///
		text(12.5 	2022.25 "`: var lab `: word `y--' of `vars'''", 	///
										m(zero)	col(gs2) size(small) j(left))	///
		text(7.75 	2021.5 "`: var lab `: word `y--' of `vars'''", 	///
										m(zero)	col(gs2) size(small) j(left))	///
		text(2.5 	2021.35 "`: var lab `: word `y--' of `vars'''", 	///
										m(zero)	col(gs2) size(small) j(left))	///
		note("Source: American Community Survey (U.S. Census Bureau)"	///
				"Compiled by Danny Edgel",	///
			size(vsmall) al(bottom) place(swest))
		
graph export output/us_vacant_homes_2005-2019.png, replace
restore


erase temp.dta
