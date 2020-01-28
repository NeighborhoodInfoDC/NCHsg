/**************************************************************************
 Program:  tabulate state profile.sas
 Library:  NCHsg
 Project:  NeighborhoodInfo DC
 Author:   Yipeng Su
 Created:  1/22/19
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  tabulate state demographics and housing profile


 Modifications: 
tabulation
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( NCHsg)
%DCData_lib( Ipums)

%let date=01222020;

proc format;

	value agegroupnew
	.n= 'Not available'
	1= 'under 18 years old'
	2= '18-64 years old'
	3='65+ years old';
  value hispan
     .n = 'Not available'
    0 = 'Not Hispanic'
    1 = 'Hispanic';
 value racenew
   .n = 'Not available'
    1 = 'White non-Hispanic'
    2 = 'Black non-Hispanic'
    3 = "Hispanic"
	4 = "Asian and Pacific Islander non-Hispanic "
	5 = "All other non-Hispanic ";
  value inc_cat

    1 = '20 percentile'
    2 = '40 percentile'
    3 = '60 percentile'
	4 = '80 percentile'
	5= '100 percentile'
    6= 'vacant'
	;
run;

data categories;
set NCHsg.Puma_categories_121;
run;

data crosswalk;
	set NCHsg.PUMA_county_crosswalk ;
	county_char= put(county14, 5.);
	length puma_new $5;
	puma_new = put(input(cats(puma12),8.),z5.);
	upuma= "37"||puma_new;
run;


%macro householdinfo(year);

	data Household_&year. ;
		set Ipums.Acs_&year._NC;
	run;

	proc sort data= Household_&year. ;
	by upuma;
	run;

	proc sort data= crosswalk;
	by upuma;
	run;

	/*merge IPUMS with crosswalk to county, check #observations*/
	data Household_&year._2 ;
	merge Household_&year.(in=a) crosswalk;
	if a;
	by upuma ;
	run;


	data  Household_&year._3 ;
		set Household_&year._2 ;

		%assign_NCcounty2;  
		%assign_NCcounty3;  
		county2_char = put(county2,12.);
	 
	run;

	data Householddetail_&year.;
		set Household_&year._3 ;
		keep race hispan age hhincome hhincome_a pernum relate gq puma county2_char upuma hhwt perwt year serial numprec race1 agegroup totpop_&year. afact AFACT2;

		if hispan=0 then do;

		 if race=1 then race1=1;
		 else if race=2 then race1=2;
         else if race in (4 5 6) then race1=4;
		 else race1=5;
		end;

		if hispan in(1 2 3 4) then race1=3;

		if 0<=age<18 then agegroup=1;
		else if 18<=age<65 then agegroup=2;
		else if age>=65 then agegroup=3;

		totpop_&year. = 1;

		if gq=5 then relate =12;


%dollar_convert( hhincome, hhincome_a, &year., 2017, series=CUUR0000SA0 )  

		run;

		proc freq data=Householddetail_&year.;
		  tables race1 * agegroup  / list missing;
		run;

		proc sort data=Householddetail_&year.;
		by county2_char agegroup race1 relate;
		run;

%mend householdinfo;

%householdinfo(2013);
%householdinfo(2014);
%householdinfo(2015);
%householdinfo(2016);
%householdinfo(2017);

/*compile 13-17 data for tabulation*/
data fiveyeartotal;
set Householddetail_2013 Householddetail_2014 Householddetail_2015 Householddetail_2016 Householddetail_2017;
totalpop=0.2;
*totpop_wt= totalpop*AFACT2;  /*removed afact weights from tabulation*/
run;

proc sort data= fiveyeartotal;by county2_char; run;

data fiveyeartotal2;
	set fiveyeartotal;
	by county2_char;
	retain group 0;
	if first.county2_char then group=group+1;
run;

/*tabulate state demographics*/
data fiveyeartotal_dem;
merge fiveyeartotal2(in=a) categories;
if a;
by group ;
perwt_geo= perwt*0.2;
hhwt_geo= hhwt*0.2;
run;

/*race*/
proc freq data=fiveyeartotal_dem;
tables Category*race1 /nopercent norow nocol out=race_group;
weight perwt_geo;
run;
proc sort data= race_group;
by race1;
run;

proc transpose data=race_group prefix=count out=race_group2;
by race1;
ID Category;
var count;
run;

proc export data=race_group2
 	outfile="&_dcdata_default_path\NCHsg\Prog\state_race_&date..csv"
   dbms=csv
   replace;
   run;

/*age*/
proc freq data=fiveyeartotal_dem;
tables Category*agegroup/nopercent norow nocol out=age_group;
weight perwt_geo;
run;
proc sort data= age_group;
by agegroup;
run;

proc transpose data=age_group prefix=count out=age_group2;
by agegroup;
ID Category;
var count;
run;
proc export data=age_group2
 	outfile="&_dcdata_default_path\NCHsg\Prog\state_age_&date..csv"
   dbms=csv
   replace;
   run;

/*household tabulations */
  data fiveyeartotal_occ;
	set NCHsg.fiveyeartotal (drop= County) ;
	by county2_char;
	retain group 0;
	if first.county2_char then group=group+1;
run;

proc sort data= fiveyeartotal_occ;
by Category ;
run;

proc summary data = fiveyeartotal_occ;
class Category;
var numprec hhincome;
weight hhwt_geo;
output out= hhprofile mean=;
run;
proc export data=hhprofile
 	outfile="&_dcdata_default_path\NCHsg\Prog\state_hhcat_&date..csv"
   dbms=csv
   replace;
   run;
/**************************************************************************
Housing profile
**************************************************************************/
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

data all(label= "NC all regular housing units 13-17 pooled");
	set fiveyeartotal_occ fiveyeartotal_vacant (in=a);
	if a then inc=6; 
format inc inc_cat.;
if inc= 6 then vacantstatus=1;
else vacantstatus=0;
run; 

proc sort data=all;
by group;
run;

/*tabulate state demographics*/
data allunits;
merge all(in=a) categories;
if a;
by group ;
run;

proc freq data=allunits;
tables Category*vacantstatus/nopercent norow nocol out=vacancy_group;
weight hhwt_geo;
run;

proc sort data= vacancy_group;
by vacantstatus;
run;

proc transpose data=vacancy_group prefix=count out=vacancy_group2;
by vacantstatus;
ID Category;
var count;
run;

proc export data=vacancy_group2
 	outfile="&_dcdata_default_path\NCHsg\Prog\state_units_&date..csv"
   dbms=csv
   replace;
   run;

/*tenure*/
proc freq data=allunits;
tables Category*tenure/nopercent norow nocol out=tenure_group;
weight hhwt_geo;
run;
proc sort data= tenure_group;
by tenure;
run;

proc transpose data=tenure_group prefix=count out=tenure_group2;
by tenure;
ID Category;
var count;
run;
proc export data=tenure_group2
 	outfile="&_dcdata_default_path\NCHsg\Prog\state_stenure_&date..csv"
   dbms=csv
   replace;
   run;

/*structure*/

proc freq data=allunits;
tables Category*structure/nopercent norow nocol out=structure_group;
weight hhwt_geo;
run;
proc sort data= structure_group;
by structure;
run;

proc transpose data=structure_group prefix=count out=structure_group2;
by structure;
ID Category;
var count;
run;
proc export data=structure_group2
 	outfile="&_dcdata_default_path\NCHsg\Prog\state_structure_&date..csv"
   dbms=csv
   replace;
   run;

/*strcuture age*/

proc freq data=allunits;
tables Category*structureyear/nopercent norow nocol out=structureyear_group;
weight hhwt_geo;
run;
proc sort data= structureyear_group;
by structureyear;
run;

proc transpose data=structureyear_group prefix=count out=structureyear_group2;
by structureyear;
ID Category;
var count;
run;
proc export data=structureyear_group2
 	outfile="&_dcdata_default_path\NCHsg\Prog\state_structureyear_&date..csv"
   dbms=csv
   replace;
   run;

/*pct costburden*/
data allocc;
merge fiveyeartotal_occ(in=a) categories;
if a;
by group ;
run;

proc freq data=allocc;
tables Category*costburden/nopercent norow nocol out=costburden_group;
weight hhwt_geo;
run;
proc sort data= costburden_group;
by costburden;
run;

proc transpose data=costburden_group prefix=count out=costburden_group2;
by costburden;
ID Category;
var count;
run;
proc export data=costburden_group2
 	outfile="&_dcdata_default_path\NCHsg\Prog\state_costburden_&date..csv"
   dbms=csv
   replace;
   run;

/* cost category*/
proc freq data=allocc;
tables Category*allcostlevel/nopercent norow nocol out=allcostlevel_group;
weight hhwt_geo;
run;

proc sort data= allcostlevel_group;
by allcostlevel;
run;

proc transpose data=allcostlevel_group prefix=count out=allcostlevel_group2;
by allcostlevel;
ID Category;
var count;
run;

proc export data=allcostlevel_group2
 	outfile="&_dcdata_default_path\NCHsg\Prog\state_costlevel_&date..csv"
   dbms=csv
   replace;
   run;






















  ** Determine maximum HH size based on bedrooms **;
  
  select ( bedrooms );
    when ( 1 )       /** Efficiency **/
      Max_hh_size = 1;
    when ( 2 )       /** 1 bedroom **/
      Max_hh_size = 2;
    when ( 3 )       /** 2 bedroom **/
      Max_hh_size = 3;
    when ( 4 )       /** 3 bedroom **/
      Max_hh_size = 4;
    when ( 5 )       /** 4 bedroom **/
      Max_hh_size = 5;
    when ( 6, 7, 8, 9, 10, 11, 12 )       /** 5+ bedroom **/
      Max_hh_size = 7;
    otherwise
      do; 
        %err_put( msg="Invalid bedroom size: " serial= bedrooms= ) 
      end;
  end;

  if ownershpd in ( 12,13,21,22 ) then do;
    %Hud_inc_2011( hud_inc=Hud_inc_hh )
  end;
  else do;
    Hud_inc_hh = .n;
  end;
  
  %Hud_inc_2011( hhinc=Max_income, hhsize=Max_hh_size, hud_inc=Hud_inc_unit )
  
  label
    Hud_inc_hh = 'HUD income category for household'
    Hud_inc_unit = 'HUD income category for unit';

run;

%File_info( data=DMPED.Housing_needs_baseline, freqvars=Hud_inc_hh Hud_inc_unit )


