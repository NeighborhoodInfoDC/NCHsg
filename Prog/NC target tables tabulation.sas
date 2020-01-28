/**************************************************************************
 Program:  NC target tables tabulation.sas
 Library:  NCHsg
 Project:  NC housing
 Author:   YS adapted from L. Hendey
 Created:  12/07/2019
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 
 Description:  Produce numbers for housing needs and targets analysis from 2013-17
 ACS IPUMS data. Program outputs counts of units based on distribution of income categories
 and housing cost categories for the region and jurisdictions for 3 scenarios:

 a) actual distribution of units by income category and unit cost category
 b) desired (ideal) distribution of units by income category and unit cost category in which
	all housing needs are met and no households have cost burden.
 c) halfway - distribution of units by income category and unit cost category in which
	cost burden rates are cut in half for households below 120% of AMI as a more pausible 
	set of targets for the future. 

 Modifications: 02-12-19 LH Adjust weights using Calibration from Steven's projections 
						 	so that occupied units match COG 2015 HH estimation.
                02-17-19 LH Readjust weights after changes to calibration to move 2 HH w/ GQ=5 out of head of HH
				03-30-19 LH Remove hard coding and merge in contract rent to gross rent ratio for vacant units. 
				04-26-19 LH Change halfway from 30% of income to max_rent or max_ocost.
                01/2020  YS update for NC housing project
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( NCHsg )
%DCData_lib( Ipums )

%let date=01152020; 

proc format;

  value hud_inc
   .n = 'Vacant'
    1 = '0-30% AMI'
    2 = '31-50%'
    3 = '51-80%'
    4 = '81-120%'
    5 = '120-200%'
    6 = 'More than 200%'
	;

  value tenure
    1 = 'Renter units'
    2 = 'Owner units'
	;

 value rcost
	  1= "$0 to $349"
	  2= "$350 to $699"
	  3= "$700 to $999"
	  4= "$1,000 to $1,499"
	  5= "$1,500 to $2,499"
	  6= "More than $2,500"
  ;

  value ocost
	  1= "$0 to $349"
	  2= "$350 to $699"
	  3= "$700 to $999"
	  4= "$1,000 to $1,499"
	  5= "$1,500 to $2,499"
	  6= "More than $2,500"
  ;

  value acost
	  1= "$0 to $349"
	  2= "$350 to $699"
	  3= "$700 to $999"
	  4= "$1,000 to $1,499"
	  5= "$1,500 to $2,499"
	  6= "More than $2,500"
  ;
	
  value inc_cat

    1 = '20 percentile'
    2 = '40 percentile'
    3 = '60 percentile'
	4 = '80 percentile'
	5= '100 percentile'
    6= 'vacant'
	;
  value structure
	1= 'Single family attached and detached'
	2= '2-9 units in strucutre'
	3= '10+ units in strucutre'
	4= 'Mobile or other'
	5= 'NA'
	;
  	
  value afford

  1= 'natural affordable (rent < $700)'
  0= 'not natural affordable'; 
run;
data categories;
set NCHsg.Puma_categories_121;
run;

/*read in dataset created by NCHousing_needs_units_targets.sas*/
data fiveyeartotal;
	set NCHsg.fiveyeartotal (drop= County) ;
	by county2_char;
	retain group 0;
	if first.county2_char then group=group+1;
run;

 data fiveyeartotal_vacant; 
   set NCHsg.fiveyeartotal_vacant;
	by county2_char;
	retain group 0;
	if first.county2_char then group=group+1;
 run;

 data fiveyeartotal_othervacant; 
   set NCHsg.fiveyeartotal_othervacant ;
	by county2_char;
	retain group 0;
	if first.county2_char then group=group+1;
 run;

proc freq data=fiveyeartotal_othervacant;
by county2_char;
tables vacancy /nopercent norow nocol out=other_vacant;
weight hhwt_geo;
*format county2_char county2_char.;
run; 
proc export data=fiveyeartotal_othervacant
 	outfile="&_dcdata_default_path\NCHsg\Prog\other_vacant_&date..csv"
   dbms=csv
   replace;
   run;

/*tabulate percent cost burdened by category and income quintiles*/
data fiveyeartotal_cat;
merge fiveyeartotal(in=a) categories;
if a;
by group ;
run;

proc freq data=fiveyeartotal_cat;
tables Category*costburden /nopercent norow nocol out=costburden_group;
weight hhwt_geo;
run;

proc freq data=fiveyeartotal_cat;
tables Category*costburden*inc /nopercent norow nocol out=costburden_incgroup;
weight hhwt_geo;
run;

proc transpose data=costburden_incgroup prefix=count out=costburden_incgroup2;
by Category costburden;
ID inc;
var count;
run;

proc transpose data=costburden_incgroup2 prefix=count out=costburden_incgroup3;
by Category;
ID costburden;
var count20_percentile count40_percentile count60_percentile count80_percentile count100_percentile;
run;

data costburden_incgroup4;
set costburden_incgroup3;
pctburdened= count1/(count0+count1);
run;

proc transpose data=costburden_incgroup4 prefix=count out=costburden_incgroup5;
by Category;
ID _NAME_;
var pctburdened;
run;

proc export data=costburden_incgroup5
 	outfile="&_dcdata_default_path\NCHsg\Prog\costburden_incgroup_&date..csv"
   dbms=csv
   replace;
   run;

proc summary data = costburden_incgroup4;
class _NAME_;
var count0 count1 ;
output out= inccat sum=;
run;
data inccat2;
set inccat;
pctburdened= count1/(count0+count1);
total= count0+count1;
run;
proc transpose data=inccat2 prefix=count out=inccat3;
by _TYPE_;
ID _NAME_;
var pctburdened;
run;

proc export data=inccat3
 	outfile="&_dcdata_default_path\NCHsg\Prog\inccat_total_&date..csv"
   dbms=csv
   replace;
   run;

proc summary data = costburden_incgroup4;
class Category;
var count0 count1 ;
output out= burden_cat sum=;
run;
data burden_cat2;
set burden_cat;
pctburdened= count1/(count0+count1);
total= count0+count1;
run;
proc export data=burden_cat2
 	outfile="&_dcdata_default_path\NCHsg\Prog\burden_cat_&date..csv"
   dbms=csv
   replace;
   run;

/*monthly housing cost by classifications*/
data monthlycost;
set Fiveyeartotal_cat;
cost= costratio* hhincome_a/12;
keep county2_char group County_FIPS County Category cost hhwt_geo;
run;
/*
proc summary data= monthlycost;
class county2_char group Category;
var cost;
weight hhwt_geo;
output out= monthlycost2(where= (_TYPE_=7)) mean=;
run;
*/

proc freq data=Fiveyeartotal_cat;
tables Category*allcostlevel /nofreq nopercent nocol out=allcostcat;
weight hhwt_geo;
run;
proc freq data=Fiveyeartotal_cat;
tables allcostlevel /nofreq nopercent nocol out=allcostcat2;
weight hhwt_geo;
run;
proc freq data=Fiveyeartotal_cat;
tables group*allcostlevel /nofreq nopercent nocol out=allcostcat3;
weight hhwt_geo;
run;
proc freq data=Fiveyeartotal_cat;
tables group /nofreq nopercent nocol out=allcostcat4;
weight hhwt_geo;
run;

data allcostcat5;
set allcostcat4;
total= COUNT;
drop COUNT PERCENT;
run;
data allcostcat6 ;
	merge allcostcat3(in=a) allcostcat5;
	if a;
	by group ;
	percent= COUNT/total;
	run;

proc transpose data= allcostcat6 out=allcostcat7;
by group;
ID allcostlevel;
var percent;
run;

proc transpose data=structurecost out=structurecost2;
by structure ;
ID allcostlevel;
var total;
run;


/*
proc export data=monthlycost2
 	outfile="&_dcdata_default_path\NCHsg\Prog\housingcost_cat_&date..csv"
   dbms=csv
   replace;
   run;
*/
proc export data=allcostcat
 	outfile="&_dcdata_default_path\NCHsg\Prog\allcost_cat_&date..csv"
   dbms=csv
   replace;
   run;

proc export data=allcostcat2
 	outfile="&_dcdata_default_path\NCHsg\Prog\allcost_all_&date..csv"
   dbms=csv
   replace;
   run;
proc export data=allcostcat7
 	outfile="&_dcdata_default_path\NCHsg\Prog\allcost_county2_&date..csv"
   dbms=csv
   replace;
   run;

/*cost by structure type*/
proc summary data= Fiveyeartotal_cat;
class allcostlevel structure;
var total;
weight hhwt_geo;
output out= structurecost(where= (_TYPE_=3)) sum=;
run;

proc sort data= structurecost;
by structure;
run;

proc transpose data=structurecost out=structurecost2;
by structure ;
ID allcostlevel;
var total;
run;

proc export data=structurecost2
 	outfile="&_dcdata_default_path\NCHsg\Prog\structure_cost_&date..csv"
   dbms=csv
   replace;
   run;

proc freq data=Fiveyeartotal_cat;
tables Category*structure /nofreq nopercent nocol out=structurecat;
weight hhwt_geo;
run;

proc transpose data=structurecat out=structurecat2;
by category;
ID structure;
var COUNT;
run;

proc export data=structurecat2
 	outfile="&_dcdata_default_path\NCHsg\Prog\structure_cat_&date..csv"
   dbms=csv
   replace;
   run;

proc summary data= Fiveyeartotal_cat;
class group structure;
weight hhwt_geo;
var total;
output out=county_structure(where= (_TYPE_=3)) sum=;
run;

proc transpose data=county_structure out=county_structure2;
by group;
ID structure;
var total;
run;


proc export data=county_structure2
 	outfile="&_dcdata_default_path\NCHsg\Prog\structure_county_&date..csv"
   dbms=csv
   replace;
   run;

/*future housing needs desired units*/
/*jurisdiction desire and halfway (by tenure)*/
proc sort data=Fiveyeartotal_cat;
by Category; 
run;
proc freq data=Fiveyeartotal_cat;
by Category;
tables inc*mallcostlevel /nopercent norow nocol out=geo_desire;
weight hhwt_geo;
*format county2_char county2_char. mallcostlevel;
run;
proc transpose data=geo_desire out=geo_d
prefix=level;
id mallcostlevel;
by Category inc;
var count;
run;

proc freq data=Fiveyeartotal_cat;
by Category;
tables inc*mallcostlevel /nopercent norow nocol out=geo_desire_rent;
weight hhwt_geo;
where tenure=1 ;
*format county2_char county2_char. mallcostlevel;
run;
	proc transpose data=geo_desire_rent out=geo_dr
	prefix=level;
	id mallcostlevel;
	by Category inc;
	var count;
	run;

proc freq data=Fiveyeartotal_cat;
by Category;
tables inc*mallcostlevel /nopercent norow nocol out=geo_desire_own;
weight hhwt_geo;
where tenure=2 ;
*format county2_char county2_char. mallcostlevel;
run;
	proc transpose data=geo_desire_own out=geo_do
	prefix=level;
	id mallcostlevel;
	by Category inc;
	var count;
	run;
data geo_desire_units (drop=_label_ _name_); 
		set geo_d (in=a) geo_do (in=b) geo_dr (in=c);

	length name $20.;

	if _name_="COUNT" & a then name="Desired All";
	if _name_="COUNT" & b then name="Desired Owner";
	if _name_="COUNT" & c then name="Desired Renter";
	run; 

/*export all 3 jurisidiction scenarios*/ 
proc sort data= geo_desire_units ;
by Category inc;
proc export data=geo_desire_units 
	outfile="&_dcdata_default_path\NCHsg\Prog\geo_unitsdesired_&date..csv"
	dbms=csv
	replace;
run;

/*vacancy rate by cost level*/
data fiveyeartotal_all;
set fiveyeartotal fiveyeartotal_vacant;
run;

proc sort data= fiveyeartotal_all;
by group;
run;

data fiveyeartotal_cat_all;
merge fiveyeartotal_all(in=a) categories;
if a;
by group;
run;

proc sort data=Fiveyeartotal_cat_all;
by Category; 
run;

proc summary data= fiveyeartotal_cat_all;
class Category allcostlevel vacancy;
	var total;
	weight hhwt_geo;
	output out = geo_vacant sum=;
run;

proc export data= geo_vacant
	outfile="&_dcdata_default_path\NCHsg\Prog\geo_vacancy_&date..csv"
	dbms=csv
	replace;
run;

proc sort data=Fiveyeartotal_cat;
by Category; 
run;

proc summary data= fiveyeartotal_cat;
class Category allcostlevel;
	var total;
	weight hhwt_geo;
	output out = geo_nonvacant sum=;
run;

proc export data= geo_nonvacant
	outfile="&_dcdata_default_path\NCHsg\Prog\geo_nonvacant_&date..csv"
	dbms=csv
	replace;
run;








/*unsubsidized low cost stock*/

data rental;
set fiveyeartotal_cat (where= (tenure=1));
if rentgrs=<700 then delete;
if UNITSSTR = 00 then substrucutre=5;
if UNITSSTR in (01, 02) then substrucutre=4;
if UNITSSTR in (03, 04) then substrucutre=1;
if UNITSSTR in (05, 06) then substrucutre=2;
if UNITSSTR in (07, 08, 09, 10) then substrucutre=3;
run;

proc freq data=rental;
by category;
tables substrucutre*structureyear /nopercent norow nocol out=geo_lowcost;
weight hhwt_geo;
*format county2_char county2_char. mallcostlevel;
run;

proc sort data=geo_lowcost;
by category substructure structureyear;
run;

proc transpose data=geo_lowcost out=geo_lowcost2
prefix= level;
id structureyear;
by category substrucutre;
var count;
run;

proc export data=geo_lowcost2
	outfile="&_dcdata_default_path\NCHsg\Prog\geo_lowcost_&date..csv"
	dbms=csv
	replace;
run;





