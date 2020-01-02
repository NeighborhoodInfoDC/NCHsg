/**************************************************************************
 Program:  Housing_needs_units_targets-Alt.sas
 Library:  NCHsg
 Project:  NC Housing
 Author:   YS from L. Hendey
 Created:  12/07/2019
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 
 Description:  

 ****Housing_needs_units_targets-Alt.sas USES ACTUAL COSTS FOR OWNERS NOT COSTS FOR FIRST TIME HOMEBUYERS
	AS IN Housing_needs_units_targets.sas*** 

***aS OF 4-26-19 -CURRENT NEEDS WILL BE BASED ON THE ALT PROGRAM AND FUTURE NEEDS ON THE ORIGINAL TARGET PROGRAM***

 Produce numbers for housing needs and targets analysis from 2013-17
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
				04-23-19 LH Test using actual costs for current gap (renters and owners). 
				05-02-19 LH Add couldpaymore flag
                01/20    YS update for NC housing 
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( NCHsg )
%DCData_lib( Ipums )

%let date=12072019Alt; 

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
/*
  value county2_char
    1= "DC"
	2= "Charles County"
	3= "Frederick County "
	4="Montgomery County"
	5="Prince Georges "
	6="Arlington"
	7="Fairfax, Fairfax city and Falls Church"
	8="Loudoun"
	9="Prince William, Manassas and Manassas Park"
    10="Alexandria"
  	;
*/
  value rcost
	  1= "$0 to $749"
	  2= "$750 to $1,199"
	  3= "$1,200 to $1,499"
	  4= "$1,500 to $1,999"
	  5= "$2,000 to $2,499"
	  6= "More than $2,500"
  ;

  value ocost
	  1= "$0 to $1,199"
	  2= "$1,200 to $1,799"
	  3= "$1,800 to $2,499"
	  4= "$2,500 to $3,199"
	  5= "$3,200 to $4,199"
	  6= "More than $4,200"
  ;

  value acost
	  1= "$0 to $799"
	  2= "$800 to $1,299"
	  3= "$1,300 to $1,799"
	  4= "$1,800 to $2,499"
	  5= "$2,500 to $3,499"
	  6= "More than $3,500"
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

  1= 'natural affordable (rent < $750)'
  0= 'not natural affordable';
run;


/*read in dataset created by NCHousing_needs_units_targets.sas*/
data fiveyeartotal;
	set NCHsg.fiveyeartotal_alt ;
run;

 data fiveyeartotal_vacant; 
   set NCHsg.fiveyeartotal_vacant_alt;
 run;

 data fiveyeartotal_othervacant; 
   set NCHsg.fiveyeartotal_othervacant_alt ;
 run;

 proc tabulate data=fiveyeartotal format=comma12. noseps missing;
  class county2_char;
  var hhwt_5;
  table
    all='Total' county2_char=' ',
    sum='Sum of HHWTs' * ( hhwt_5='Original 5-year'  )
  / box='Occupied housing units';
  *format county2_char county2_char.;
run;

proc tabulate data=fiveyeartotal_vacant format=comma12. noseps missing;
  class county2_char;
  var hhwt_5;
  table
    all='Total' county2_char=' ',
    sum='Sum of HHWTs' * ( hhwt_5='Original 5-year')
  / box='Vacant (nonseasonal) housing units';
  *format county2_char county2_char.;
run;

proc tabulate data=fiveyeartotal_othervacant format=comma12. noseps missing;
  class county2_char;
  var hhwt_5;
  table
    all='Total' county2_char=' ',
    sum='Sum of HHWTs' * ( hhwt_5='Original 5-year' )
  / box='Seasonal vacant housing units';
  *format county2_char county2_char.;
run;

proc export data=other_vacant
 	outfile="&_dcdata_default_path\NCHsg\Prog\other_vacant_&date..csv"
   dbms=csv
   replace;
   run;


/*data set for all units that we can determine cost level*/ 
data all;
	set fiveyeartotal fiveyeartotal_vacant (in=a);
	if a then inc=6; 
format inc inc_cat.;
run; 

/*output current households by unit cost catgories by tenure*/
proc freq data=all;
tables inc*allcostlevel /nopercent norow nocol out=region_units;
weight hhwt_5;
run;
proc freq data=all;
tables inc*allcostlevel /nopercent norow nocol out=region_rental;
where tenure=1;
weight hhwt_5;
run;
proc freq data=all;
tables inc*allcostlevel /nopercent norow nocol out=region_owner;
where tenure=2;
weight hhwt_5;
run;
proc freq data=all;
where couldpaymore=1;
tables inc*allcostlevel /nopercent norow nocol out=region_paymore;
weight hhwt_5;
run; 
proc freq data=all;
tables paycategory*allcostlevel /nopercent norow nocol out=region_paycategory;
weight hhwt_5;
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
	*transpose here but output later with jurisdiction level; 
	proc transpose data=region_paymore prefix=level out=rm; 
	by inc;
	var count;
	run; 
	proc transpose data=region_paycategory prefix=level out=rp;
	by paycategory;
	var count;
	run; 

	data region (drop=_label_ _name_); 
		set ru (in=a) ro (in=b) rr (in=c) ;
	
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
	weight hhwt_5;
	title2 "initial cost burden rates";
	run;
	proc freq data=fiveyearrandom;
	tables inc*reduced_costb /nofreq nopercent nocol;
	weight hhwt_5;
	title2 "reduced cost burden rates"; 
	run;

/*output income distributions by cost for desired cost and cost burden halfway solved*/ 

proc freq data=fiveyeartotal;
tables inc*mallcostlevel /nofreq nopercent nocol out=region_desire_byinc;
weight hhwt_5;
title2;
run;
proc freq data=fiveyeartotal;
tables inc*mallcostlevel /nofreq nopercent nocol out=region_desire_rent;
weight hhwt_5;
where tenure=1;
run;
proc freq data=fiveyeartotal;
tables inc*mallcostlevel /nofreq nopercent nocol out=region_desire_own;
weight hhwt_5;
where tenure=2;
run;

proc freq data=fiveyearrandom;
tables inc*allcostlevel_halfway /nofreq nopercent nocol out=region_half_byinc;
weight hhwt_5;

run;
proc freq data=fiveyearrandom;
tables inc*allcostlevel_halfway /nofreq nopercent nocol out=region_half_rent;
weight hhwt_5;
where tenure=1;
run;
proc freq data=fiveyearrandom;
tables inc*allcostlevel_halfway /nofreq nopercent nocol out=region_half_own;
weight hhwt_5;
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
weight hhwt_5;
*format county2_char county2_char.;
run;
	proc transpose data=Allgeo out=geo_u prefix=level;;
	by county2_char inc;
	var count;

	run;

proc freq data=all;
by county2_char;
tables inc*allcostlevel /nopercent norow nocol out=allgeo_rent;
where tenure=1;
weight hhwt_5;
*format county2_char county2_char.;
run;
	proc transpose data=allgeo_rent out=geo_r prefix=level;;
	by county2_char inc;
	var count;

	run;

proc freq data=all;
by county2_char;
tables inct*allcostlevel /nopercent norow nocol out=allgeo_own;
where tenure=2;
weight hhwt_5;
*format county2_char county2_char.;
run;
	proc transpose data=allgeo_own out=geo_o prefix=level;;
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
weight hhwt_5;
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
weight hhwt_5;
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
weight hhwt_5;
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
weight hhwt_5;

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
weight hhwt_5;
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
weight hhwt_5;
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

*finish could pay more;
proc freq data=all;
where couldpaymore=1; 
by county2_char;
tables inc*allcostlevel /nopercent norow nocol out=geo_paymore;
weight hhwt_5;
*format county2_char county2_char.;
run;
	proc transpose data=geo_paymore out=geo_m prefix=level;;
	by county2_char inc;
	var count;
	run;

 data couldpaymore (drop=_label_ _name_);
 	set rp (in=a) rm (in=b) geo_m (in=c);

	length name $20.;

	if _name_="COUNT" & a then name="Region Pay Category";

	if _name_="COUNT" & b then name="Region Pay More";

	if _name_="COUNT" & c then name="Juris Pay More";

	run;

proc export data=couldpaymore
 outfile="&_dcdata_default_path\NCHsg\Prog\couldpaymore_&date..csv"
  dbms=csv
   replace;
   run;


*export cost burden and households counts by income category for jurisdiction level handouts; 

   
proc freq data=all;
tables inc*county2_char /nopercent norow nocol  out=hhlds_juris;
  weight hhwt_5;
   *format county2_char county2_char.;
run;
proc freq data=all;
where costburden=1;
tables inc*county2_char /nopercent norow nocol out=hhlds_juris_cb;
  weight hhwt_5;
    *format county2_char county2_char.;
run;

data hhlds;
merge hhlds_juris (drop=percent rename=(count=households)) hhlds_juris_cb (drop=percent rename=(count=costburden)); 
by inc county2_char;

run; 

proc sort data=hhlds;
by county2_char inc;

proc export data=hhlds
 outfile="&_dcdata_default_path\NCHsg\Prog\hhlds_&date..csv"
  dbms=csv
   replace;
   run;


