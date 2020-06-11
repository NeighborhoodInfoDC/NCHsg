/**************************************************************************
 Program:  appendix future housing needs.sas
 Library:  NCHsg
 Project:  NC housing
 Author:   YS adapted from L. Hendey
 Created:  3/11/2020
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

 Modifications:
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( NCHsg )
%DCData_lib( Ipums )

%let date=03112020; 

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

/*future housing needs desired units*/
/*jurisdiction desire and halfway (by tenure)*/

data five;
set nchsg.fiveyeartotal ;
run;

proc sort data=five ;
by group; 
run;

proc freq data=five ;
by group;
tables inc*mallcostlevel /nopercent norow nocol out=geo_desire;
weight hhwt_geo;
*format county2_char county2_char. mallcostlevel;
run;
proc transpose data=geo_desire out=geo_d
prefix=level;
id mallcostlevel;
by group inc;
var count;
run;

/*vacant units by cist*/

proc sort data= nchsg.fiveyeartotal_vacant out=five_vacant;
by group;
run;

proc freq data=five_vacant;
by group;
tables allcostlevel /nopercent norow nocol out=geo_vacant;
weight hhwt_geo;
*format county2_char county2_char. mallcostlevel;
run;

proc transpose data=geo_vacant out=geo_v
prefix=level;
id allcostlevel;
by group;
var count;
run;


data geo_desire_units (drop=_label_ _name_); 
		set geo_d (in=a) geo_v (in=b);

	length name $20.;

	if _name_="COUNT" & a then name="Desired All";
	if _name_="COUNT" & b then name="Vacant";
	run; 

/*export all 45 units of geography*/ 


proc export data=geo_desire_units 
	outfile="&_dcdata_default_path\NCHsg\Prog\appendix_unitsdesired_&date..csv"
	dbms=csv
	replace;
run;
