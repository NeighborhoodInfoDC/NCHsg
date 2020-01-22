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





proc summary data=fiveyeartotal;
class county2_char agegroup race1 inc;
	var totalpop;
	weight hhwt;
	output out = Householderbreakdown_NC(where=(_TYPE_=15)) sum=;
	format race1 racenew. agegroup agegroupnew. ;
run;

/*data set for all units that we can determine cost level*/ 
data all(label= "NC all regular housing units 13-17 pooled");
	set fiveyeartotal fiveyeartotal_vacant (in=a);
	if a then inc=6; 
format inc inc_cat.;
run; 

proc contents data= all; run;

/*output current households by unit cost catgories by tenure*/
proc freq data=all;
tables inc*allcostlevel /nopercent norow nocol out=region_units;
weight hhwt_geo;
run;
proc freq data=all;
tables inc*allcostlevel /nopercent norow nocol out=region_rental;
where tenure=1;
weight hhwt_geo;
run;
proc freq data=all;
tables inc*allcostlevel /nopercent norow nocol out=region_owner;
where tenure=2;
weight hhwt_geo;
run;

	proc transpose data=region_owner prefix=level out=ro;
	by inc;
	var count;
	run;
	proc transpose data=region_rental prefix=level out=rr;
	by inc;
	var  count;
	run;
	proc transpose data=region_units  prefix=level  out=ru;
	by inc;
	var count;
	run;
	data region (drop=_label_ _name_); 
		set ru (in=a) ro (in=b) rr (in=c);
	
		length name $20.; 
	if _name_="COUNT" & a then name="Actual All";
	if _name_="COUNT" & b then name="Actual Owner";
	if _name_="COUNT" & c then name="Actual Rental";
	run; 


/*to create a distribution of units by income categories and cost categories that meets more housing needs than the current distribution with
	large mismatch between needs and units and likely is more probable future goal than desired/ideal scenario*/
/*Create this scenario by randomly select observations to reduce cost burden halfway*/

data all_costb;
	set fiveyeartotal;
	where costburden=1;
	run;

proc surveyselect data=all_costb  groups=2 seed=5000 out=randomgroups noprint;
run; 
proc sort data=randomgroups;
by year serial;
proc sort data=fiveyeartotal;
by year serial;
data fiveyearrandom;
merge fiveyeartotal randomgroups (keep=year serial groupid);
by year serial;

reduced_costb=.;
/*need to change inc range in NC question for Leah*/
if inc in (1, 2, 3, 4, 5) and groupid=1 then reduced_costb=0;
else reduced_costb=costburden; 

if tenure=1 then do; 

	if reduced_costb=1 then reduced_rent =rentgrs_a;
	if reduced_costb=0 and costburden=1 then reduced_rent=max_rent;
	if reduced_costb=0 and costburden=0 then reduced_rent=rentgrs_a; 

	 allcostlevel_halfway=.; 
          /*need to discuss for NC*/
				if reduced_rent<800 then allcostlevel_halfway=1;
				if 800 <=reduced_rent<1300 then allcostlevel_halfway=2;
				if 1300 <=reduced_rent<1800 then allcostlevel_halfway=3;
				if 1800 <=reduced_rent<2500 then allcostlevel_halfway=4;
				if 2500 <=reduced_rent<3500 then allcostlevel_halfway=5;
				if reduced_rent >= 3500 then allcostlevel_halfway=6;

end; 

if tenure=2 then do; 

	if reduced_costb=1 then reduced_totalmonth =owncost_a; *using owncost_a (actual costs) instead of First-time homebuyer costs;
	if reduced_costb=0 and costburden=1 then reduced_totalmonth=max_ocost;
	if reduced_costb=0 and costburden=0 then reduced_totalmonth=owncost_a; 

		 allcostlevel_halfway=.; 
          /*need to discuss for NC*/
				if reduced_totalmonth<800 then allcostlevel_halfway=1;
				if 800 <=reduced_totalmonth<1300 then allcostlevel_halfway=2;
				if 1300 <=reduced_totalmonth<1800 then allcostlevel_halfway=3;
				if 1800 <=reduced_totalmonth<2500 then allcostlevel_halfway=4;
				if 2500 <=reduced_totalmonth<3500 then allcostlevel_halfway=5;
				if reduced_totalmonth >= 3500 then allcostlevel_halfway=6; 
end;

label allcostlevel_halfway ='Housing Cost Categories (tenure combined) based on Current Rent or First-time Buyer Mtg -Reduced Cost Burden by Half';
format allcostlevel_halfway acost.;

run; 

proc print data=fiveyearrandom (obs=20);
where reduced_costb=0; 
var reduced_costb inc costburden tenure reduced_rent rentgrs_a hhincome reduced_totalmonth total_month owncost_a  ;
run; 
	proc freq data=fiveyeartotal;
	tables inc*costburden /nofreq nopercent nocol;
	weight hhwt_geo;
	title2 "initial cost burden rates";
	run;
	proc freq data=fiveyearrandom;
	tables inc*reduced_costb /nofreq nopercent nocol;
	weight hhwt_geo;
	title2 "reduced cost burden rates"; 
	run;

/*output income distributions by cost for desired cost and cost burden halfway solved*/ 
proc freq data=fiveyeartotal;
tables inc*mallcostlevel /nofreq nopercent nocol out=region_desire_byinc;
weight hhwt_geo;
title2;
run;
proc freq data=fiveyeartotal;
tables inc*mallcostlevel /nofreq nopercent nocol out=region_desire_rent;
weight hhwt_geo;
where tenure=1;
run;
proc freq data=fiveyeartotal;
tables inc*mallcostlevel /nofreq nopercent nocol out=region_desire_own;
weight hhwt_geo;
where tenure=2;
run;

proc freq data=fiveyearrandom;
tables inc*allcostlevel_halfway /nofreq nopercent nocol out=region_half_byinc;
weight hhwt_geo;
run;
proc freq data=fiveyearrandom;
tables inc*allcostlevel_halfway /nofreq nopercent nocol out=region_half_rent;
weight hhwt_geo;
where tenure=1;
run;
proc freq data=fiveyearrandom;
tables inc*allcostlevel_halfway /nofreq nopercent nocol out=region_half_own;
weight hhwt_geo;
where tenure=2; 
run;
data rdesire_half_byinc ;
	set region_desire_byinc (in=a rename=(mallcostlevel=allcostlevel) )
		region_desire_rent  (in=b rename=(mallcostlevel=allcostlevel))
		region_desire_own   (in=c rename=(mallcostlevel=allcostlevel))
		region_half_byinc (in=d rename=(allcostlevel_halfway=allcostlevel))
		region_half_rent  (in=e rename=(allcostlevel_halfway=allcostlevel))
		region_half_own   (in=f rename=(allcostlevel_halfway=allcostlevel));

	drop percent;

	length name $20.;

	if a then name="Desired All"; 
	if b then name="Desired Renter";  
	if c then name="Desired Owner";
	
	if d then name="Halfway All"; 
	if e then name="Halfway Renter";  
	if f then name="Halfway Owner"; 

format allcostlevel ; 
run;

proc sort data=rdesire_half_byinc;
by inc name;
proc transpose data=rdesire_half_byinc out=desire_half prefix=level; 
by inc name;
id allcostlevel ;
var count;
	run;

/*set with region units file (all, renter, owner) to output all 3 scenarios for the region */

data region_byinc_actual_to_desired;
set region desire_half (drop=_name_ _label_);

run; 
proc sort data=region_byinc_actual_to_desired;
by name; 

proc export data=region_byinc_actual_to_desired
 	outfile="&_dcdata_default_path\NCHsg\Prog\region_units_&date..csv"
   dbms=csv
   replace;
   run;

/*output by jurisdiction*./

 /*actual unit distribution (all, renter, owner) */
proc sort data=all;
by county2_char;
proc freq data=all;
by county2_char;
tables inc*allcostlevel /nopercent norow nocol out=Allgeo;
weight hhwt_geo;
*format county2_char county2_char.;
run;
	proc transpose data=Allgeo out=geo_u prefix=level;
	by county2_char inc;
	var count;

	run;

proc freq data=all;
by county2_char;
tables inc*allcostlevel /nopercent norow nocol out=allgeo_rent;
where tenure=1;
weight hhwt_geo;
*format county2_char county2_char.;
run;
	proc transpose data=allgeo_rent out=geo_r prefix=level;
	by county2_char inc;
	var count;

	run;

proc freq data=all;
by county2_char;
tables inct*allcostlevel /nopercent norow nocol out=allgeo_own;
where tenure=2;
weight hhwt_geo;
*format county2_char county2_char.;
run;
	proc transpose data=allgeo_own out=geo_o prefix=level;
	by county2_char inc;
	var count;

	run;
data geo_units (drop=_label_ _name_); 
		set geo_u (in=a) geo_o (in=b) geo_r (in=c);

	length name $20.;

	if _name_="COUNT" & a then name="Actual All";
	if _name_="COUNT" & b then name="Actual Owner";
	if _name_="COUNT" & c then name="Actual Rental";
	run; 

/*jurisdiction desire and halfway (by tenure)*/
proc sort data=fiveyeartotal;
by county2_char; 
proc freq data=fiveyeartotal;
by county2_char;
tables inc*mallcostlevel /nopercent norow nocol out=geo_desire;
weight hhwt_geo;
*format county2_char county2_char. mallcostlevel;
run;
	proc transpose data=geo_desire out=geo_d
	prefix=level;
	id mallcostlevel;
	by county2_char inc;
	var count;
	run;

proc freq data=fiveyeartotal;
by county2_char;
tables inc*mallcostlevel /nopercent norow nocol out=geo_desire_rent;
weight hhwt_geo;
where tenure=1 ;
*format county2_char county2_char. mallcostlevel;
run;
	proc transpose data=geo_desire_rent out=geo_dr
	prefix=level;
	id mallcostlevel;
	by county2_char inc;
	var count;
	run;

proc freq data=fiveyeartotal;
by county2_char;
tables inc*mallcostlevel /nopercent norow nocol out=geo_desire_own;
weight hhwt_geo;
where tenure=2 ;
*format county2_char county2_char. mallcostlevel;
run;
	proc transpose data=geo_desire_own out=geo_do
	prefix=level;
	id mallcostlevel;
	by county2_char inc;
	var count;
	run;
data geo_desire_units (drop=_label_ _name_); 
		set geo_d (in=a) geo_do (in=b) geo_dr (in=c);

	length name $20.;

	if _name_="COUNT" & a then name="Desired All";
	if _name_="COUNT" & b then name="Desired Owner";
	if _name_="COUNT" & c then name="Desired Renter";
	run; 
proc sort data=fiveyearrandom;
by county2_char;
proc freq data=fiveyearrandom;
by county2_char;
tables inc*allcostlevel_halfway /nofreq nopercent nocol out=geo_half_byinc;
weight hhwt_geo;

*format county2_char county2_char. allcostlevel_halfway;
run;
proc transpose data=geo_half_byinc out=geo_half
	prefix=level;
	id allcostlevel_halfway;
	by county2_char inc;
	var count;
	run;
proc freq data=fiveyearrandom;
by county2_char;
tables inc*allcostlevel_halfway /nofreq nopercent nocol out=geo_half_rent;
weight hhwt_geo;
where tenure=1; 
*format county2_char county2_char. allcostlevel_halfway;
run;
proc transpose data=geo_half_rent out=geo_halfr
	prefix=level;
	id allcostlevel_halfway;
	by county2_char inc;
	var count;
	run;
proc freq data=fiveyearrandom;
by county2_char;
tables inc*allcostlevel_halfway /nofreq nopercent nocol out=geo_half_own;
weight hhwt_geo;
where tenure=2; 
*format county2_char county2_char. allcostlevel_halfway;
run;
proc transpose data=geo_half_own out=geo_halfo
	prefix=level;
	id allcostlevel_halfway;
	by county2_char inc;
	var count;
	run;

data geo_half_units (drop=_label_ _name_); 
		set geo_half (in=a) geo_halfo (in=b) geo_halfr (in=c);

	length name $20.;

	if _name_="COUNT" & a then name="Halfway All";
	if _name_="COUNT" & b then name="Halfway Owner";
	if _name_="COUNT" & c then name="Halfway Rental";
	run; 

/*export all 3 jurisidiction scenarios*/ 
data geo_all;
set geo_units geo_desire_units geo_half_units;
run; 
proc sort data= geo_all;
by county2_char name inc;
proc export data=geo_all
 	outfile="&_dcdata_default_path\NCHsg\Prog\geo_units_&date..csv"
   dbms=csv
   replace;
   run;
