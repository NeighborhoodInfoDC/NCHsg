clear all

import excel "D:\Users\Ysu\Box\North Carolina Housing Investment\Data Analysis\Projections\hhincproj_template_0220.xlsx", sheet("hhincpumatotals") firstrow

foreach year in 2015 2020 2025 2030 2035 {

	gen inc1_`year' = hhincd1_`year' + hhincd2_`year'
	gen inc2_`year' = hhincd3_`year' + hhincd4_`year'
	gen inc3_`year' = hhincd5_`year' + hhincd6_`year'
	gen inc4_`year' = hhincd7_`year' + hhincd8_`year'
	gen inc5_`year' = hhincd9_`year' + hhincd10_`year'

}

keep puma inc1_* inc2_* inc3_* inc4_* inc5_*

gen group = _n

merge 1:1 group using "D:\Users\Ysu\Box\North Carolina Housing Investment\Data Analysis\puma_categories_121.dta"

label define cat 1 "Counties with large cities" 2"Large population counties in Metro area " 3 "Small population counties in Metro area" 4 "More affordable rural in non Metro" 5 "Less affordable rural in non Metro" 6 "Higher share fo revenue from recreation and mostly SF"
label values Category cat

collapse (sum) inc1_* inc2_* inc3_* inc4_* inc5_*, by (Category)

reshape long inc1_ inc2_ inc3_ inc4_ inc5_, i(Category) j(year)

gen total= inc1_ + inc2_ + inc3_ + inc4_ + inc5_ 

sort Category year

order Category year inc1_ inc2_ inc3_ inc4_ inc5_ total 

gen pct1= inc1_/total
gen pct2= inc2_/total
gen pct3= inc3_/total
gen pct4= inc4_/total
gen pct5= inc5_/total

drop if year==2020

sort year Category

keep if year==2015

collapse (sum) inc1_ inc2_ inc3_ inc4_ inc5_ total, by(Category)

gen pct1= inc1_/total
gen pct2= inc2_/total
gen pct3= inc3_/total
gen pct4= inc4_/total
gen pct5= inc5_/total

clear

import excel "D:\Users\Ysu\Box\North Carolina Housing Investment\Data Analysis\Projections\hhincproj_template_0220.xlsx", sheet("hhincpumatotals") firstrow

foreach year in 2015 2020 2025 2030 2035 {

	gen inc1_`year' = hhincd1_`year' + hhincd2_`year'
	gen inc2_`year' = hhincd3_`year' + hhincd4_`year'
	gen inc3_`year' = hhincd5_`year' + hhincd6_`year'
	gen inc4_`year' = hhincd7_`year' + hhincd8_`year'
	gen inc5_`year' = hhincd9_`year' + hhincd10_`year'

}

keep puma inc1_* inc2_* inc3_* inc4_* inc5_*

gen group = _n
merge 1:1 group using "D:\Users\Ysu\Box\North Carolina Housing Investment\Data Analysis\puma_categories_121.dta"

reshape long inc1_ inc2_ inc3_ inc4_ inc5_, i(puma) j(year)
gen total= inc1_ + inc2_ + inc3_ + inc4_ + inc5_ 
gen pct1= inc1_/total
gen pct2= inc2_/total
gen pct3= inc3_/total
gen pct4= inc4_/total
gen pct5= inc5_/total
keep if year==2015

sort group

clear

import excel "D:\Users\Ysu\Box\North Carolina Housing Investment\Data Analysis\Projections\hhincproj_template_0220.xlsx", sheet("hhincpumatotals") firstrow

foreach year in 2015 2020 2025 2030 2035 {

	gen inc1_`year' = hhincd1_`year' + hhincd2_`year'
	gen inc2_`year' = hhincd3_`year' + hhincd4_`year'
	gen inc3_`year' = hhincd5_`year' + hhincd6_`year'
	gen inc4_`year' = hhincd7_`year' + hhincd8_`year'
	gen inc5_`year' = hhincd9_`year' + hhincd10_`year'

}

keep puma inc1_* inc2_* inc3_* inc4_* inc5_*

gen group = _n
merge 1:1 group using "D:\Users\Ysu\Box\North Carolina Housing Investment\Data Analysis\puma_categories_121.dta"

reshape long inc1_ inc2_ inc3_ inc4_ inc5_, i(group) j(year)
keep if year==2030


gen total= inc1_ + inc2_ + inc3_ + inc4_ + inc5_ 
gen pct_1= inc1_/total
gen pct_2= inc2_/total
gen pct_3= inc3_/total
gen pct_4= inc4_/total
gen pct_5= inc5_/total
rename inc1_ inc_1
rename inc2_ inc_2
rename inc3_ inc_3
rename inc4_ inc_4
rename inc5_ inc_5

reshape long inc_ pct_, i(group) j(level)

export excel using "D:\distribution2030.xlsx", firstrow(variables) replace


clear

import excel "D:\Users\Ysu\Box\North Carolina Housing Investment\Data Analysis\Projections\hhincproj_template_0220.xlsx", sheet("hhincpumatotals") firstrow

foreach year in 2015 2020 2025 2030 2035 {

	gen inc1_`year' = hhincd1_`year' + hhincd2_`year'
	gen inc2_`year' = hhincd3_`year' + hhincd4_`year'
	gen inc3_`year' = hhincd5_`year' + hhincd6_`year'
	gen inc4_`year' = hhincd7_`year' + hhincd8_`year'
	gen inc5_`year' = hhincd9_`year' + hhincd10_`year'

}

keep puma inc1_* inc2_* inc3_* inc4_* inc5_*

gen group = _n
merge 1:1 group using "D:\Users\Ysu\Box\North Carolina Housing Investment\Data Analysis\puma_categories_121.dta"

reshape long inc1_ inc2_ inc3_ inc4_ inc5_, i(group) j(year)
keep if year==2015


gen total= inc1_ + inc2_ + inc3_ + inc4_ + inc5_ 
gen pct_1= inc1_/total
gen pct_2= inc2_/total
gen pct_3= inc3_/total
gen pct_4= inc4_/total
gen pct_5= inc5_/total
rename inc1_ inc_1
rename inc2_ inc_2
rename inc3_ inc_3
rename inc4_ inc_4
rename inc5_ inc_5

reshape long inc_ pct_, i(group) j(level)

export excel using "D:\distribution2015.xlsx", firstrow(variables) replace




