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

  1= 'natural affordable (rent < $70)'
  0= 'not natural affordable';
run;
data categories;
set NCHsg.Puma_categories_121;
run;

/*read in dataset created by NCHousing_needs_units_targets.sas*/
data fiveyeartotal;
	set NCHsg.fiveyeartotal_alt ;
	by county2_char;
	retain group 0;
	if first.county2_char then group=group+1;
run;

 data fiveyeartotal_vacant; 
   set NCHsg.fiveyeartotal_vacant_alt;
   	by county2_char;
	retain group 0;
	if first.county2_char then group=group+1;
 run;

 data fiveyeartotal_othervacant; 
   set NCHsg.fiveyeartotal_othervacant_alt ;
   	by county2_char;
	retain group 0;
	if first.county2_char then group=group+1;
 run;

proc export data=fiveyeartotal_othervacant
 	outfile="&_dcdata_default_path\NCHsg\Prog\other_vacant_&date..csv"
   dbms=csv
   replace;
   run;

/*data set for all units that we can determine cost level*/ 
data all(label= "NC all regular housing units 13-17 pooled");;
	set fiveyeartotal fiveyeartotal_vacant (in=a);
	if a then inc=6; 
format inc inc_cat.;
run; 
proc contents data=all; run;

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
proc freq data=all;
where couldpaymore=1;
tables inc*allcostlevel /nopercent norow nocol out=region_paymore;
weight hhwt_geo;
run; 
proc freq data=all;
tables paycategory*allcostlevel /nopercent norow nocol out=region_paycategory;
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

proc export data=region
 	outfile="&_dcdata_default_path\NCHsg\Prog\Current_housing_cost_&date..csv"
   dbms=csv
   replace;
   run;

/*jurisdiction desired units*/
proc sort data=fiveyeartotal;
by inc; 
proc freq data=fiveyeartotal;
*by county2_char;
tables inc*mallcostlevel /nopercent norow nocol out=geo_desire;
weight hhwt_geo;
*format county2_char county2_char. mallcostlevel;
run;
	proc transpose data=geo_desire out=geo_d
	prefix=level;
	id mallcostlevel;
	by inc;
	var count;
	run;

proc freq data=fiveyeartotal;
*by county2_char;
tables inc*mallcostlevel /nopercent norow nocol out=geo_desire_rent;
weight hhwt_geo;
where tenure=1 ;
*format county2_char county2_char. mallcostlevel;
run;
	proc transpose data=geo_desire_rent out=geo_dr
	prefix=level;
	id mallcostlevel;
	by inc;
	var count;
	run;

proc freq data=fiveyeartotal;
*by county2_char;
tables inc*mallcostlevel /nopercent norow nocol out=geo_desire_own;
weight hhwt_geo;
where tenure=2 ;
*format county2_char county2_char. mallcostlevel;
run;
	proc transpose data=geo_desire_own out=geo_do
	prefix=level;
	id mallcostlevel;
	by inc;
	var count;
	run;
data geo_desire_units (drop=_label_ _name_); 
		set geo_d (in=a) geo_do (in=b) geo_dr (in=c);

	length name $20.;

	if _name_="COUNT" & a then name="Desired All";
	if _name_="COUNT" & b then name="Desired Owner";
	if _name_="COUNT" & c then name="Desired Renter";
	run; 
proc export data=geo_desire_units
 	outfile="&_dcdata_default_path\NCHsg\Prog\geo_desireunits_&date..csv"
   dbms=csv
   replace;
   run;

/*housing stock by abiltiy to pay*/
*finish could pay more;
proc freq data=all;
*by county2_char;
tables couldpaymore*allcostlevel /nopercent norow nocol out=geo_paymore;
weight hhwt_geo;
*format county2_char county2_char.;
run;
	proc transpose data=geo_paymore out=geo_m prefix=level;
	id allcostlevel;
	by couldpaymore;
	var count;
	run;

 data couldpaymore (drop=_label_ _name_);
 	set geo_m (in=c);

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

proc freq data=all;
*by county2_char;
tables vacancy* allcostlevel /nopercent norow nocol out=geo_vacant;
weight hhwt_geo;
*format county2_char county2_char.;
run;

proc transpose data=geo_vacant out=geo_vacant2 prefix=level;
id allcostlevel;
by vacancy;
var count;
run;

proc export data=geo_vacant2
 outfile="&_dcdata_default_path\NCHsg\Prog\vacant_cost_&date..csv"
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
	proc transpose data=Allgeo out=geo_u prefix=level;;
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
	proc transpose data=allgeo_rent out=geo_r prefix=level;;
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



*finish could pay more;
proc freq data=all;
where couldpaymore=1; 
by county2_char;
tables inc*allcostlevel /nopercent norow nocol out=geo_paymore;
weight hhwt_geo;
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
  weight hhwt_geo;
   *format county2_char county2_char.;
run;
proc freq data=all;
where costburden=1;
tables inc*county2_char /nopercent norow nocol out=hhlds_juris_cb;
  weight hhwt_geo;
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


