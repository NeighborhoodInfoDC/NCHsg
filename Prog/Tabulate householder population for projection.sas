/**************************************************************************
 Program:  tabulate householder population for projection.sas
 Library:  NCHsg
 Project:  NeighborhoodInfo DC
 Author:   Yipeng Su
 Created:  7/16/19
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Produce detailed popualtion by age group, race ethnicity and jurisciation from 2008-2017
 ACS IPUMS data for the NC region:


 Modifications: 8/16/19 based on Steven's new race and place categories
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( NCHsg)
%DCData_lib( Ipums)

%let date=09172019;

proc format;

	value agegroupnew
	.n= 'Not available'
	1= 'under 18 years old'
	2= '18-24 years old'
	3= '25-44 years old'
	4= '45-64 years old'
	5='65+ years old';
  value race
   .n = 'Not available'
    1 = 'White'
    2 = 'Black'
    3 = "All Other ";
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

		%assign_NCcounty2;   /* assign geography for counties that contain PUMAs  26 total*/
		%assign_NCcounty3;   /* assign geography for PUMAs that contain multiple counties  28 total*/
		county2_char = put(county2, 5.);
	run;

	data Householddetail_&year.;
		set Household_&year._3 ;
		keep race hispan age hhincome pernum relate gq puma county2_char upuma hhwt perwt year serial numprec race1 agegroup totpop_&year. afact AFACT2;

		if hispan=0 then do;

		 if race=1 then race1=1;
		 else if race=2 then race1=2;
         else if race in (4 5 6) then race1=4;
		 else race1=5;
		end;

		if hispan in(1 2 3 4) then race1=3;

		if 0<=age<18 then agegroup=1;
		else if 18<=age<25 then agegroup=2;
		else if 25<=age<45 then agegroup=3;
		else if 45<=age<65 then agegroup=4;
		else if age>=65 then agegroup=5;

		totpop_&year. = 1;

		if gq=5 then relate =12;

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

/*make sure all PUMA got assigned a geography for tabulation*/
proc freq data= Household_2013_3 (where=(county2_char=""));
tables upuma;
run;

/*compile 13-17 data for tabulation*/
data fiveyeartotal;
set Householddetail_2013 Householddetail_2014 Householddetail_2015 Householddetail_2016 Householddetail_2017;
totalpop=0.2;
totpop_wt= totalpop*AFACT2; 
run;

/*total NC*/
proc sort data=fiveyeartotal;
by agegroup race1 relate;
run;

proc summary data=fiveyeartotal;
class agegroup race1 relate;
	var totpop_wt;
	weight perwt;
	output out = Householdbreakdown(where=(_TYPE_=7)) sum=;
	format race1 racenew. agegroup agegroupnew.;
run;

proc sort data=Householdbreakdown;
	by agegroup race1;
run;

/*transpose summary table for calculating ratios*/
proc transpose data=Householdbreakdown out=distribution;
	by agegroup race1;
	id relate;
	var totpop_wt;
run;
proc stdize data=distribution out=distribution_2 reponly missing=0;
   var grandchild parent Parent_in_Law Child_in_law Sibling_in_law Spouse;
run;
data distribution_3;
	set distribution_2;
	denom= Head_Householder + Spouse + Child+ Child_in_law+ Sibling + Sibling_in_Law + Grandchild + Other_relatives + Partner__friend__visitor + Other_non_relatives + Institutional_inmates+ Parent+ Parent_in_Law;
	percenthouseholder=Head_Householder/denom ;
run;

proc export data = distribution_3
   outfile="&_dcdata_default_path\NCHsg\Prog\Householderratio_NC_&date..csv"
   dbms=csv
   replace;
run;

/*by county*/

proc sort data=fiveyeartotal;
	by county2_char agegroup race1 relate;
run;
proc summary data=fiveyeartotal;
class county2_char agegroup race1 relate;
	var totpop_wt;
	weight perwt;
	output out = Householdbreakdown_NC(where=(_TYPE_=15)) sum=;
	format race1 racenew. agegroup agegroupnew. ;
run;
proc sort data=Householdbreakdown_NC;
	by agegroup race1 county2_char;
run;

proc transpose data=Householdbreakdown_NC out=NCdistribution;
	by agegroup race1 county2_char;
	id relate;
	var totpop_wt;
run;
proc stdize data=NCdistribution out=NCdistribution_2 reponly missing=0;
   var Head_Householder Spouse Child Child_in_law  Sibling Sibling_in_Law Grandchild Other_relatives Partner__friend__visitor Other_non_relatives Institutional_inmates Parent Parent_in_Law;
run;
data NCdistribution_3;
	set NCdistribution_2;
	denom= Head_Householder + Spouse + Child+ Child_in_law+ Sibling + Sibling_in_Law + Grandchild + Other_relatives + Partner__friend__visitor + Other_non_relatives + Institutional_inmates+ Parent+ Parent_in_Law;
	percenthouseholder=Head_Householder/denom ;
run;
proc sort data= NCdistribution_3;
	by county2_char race1 agegroup;
run;

/*should have 54 unique county2_char values*/
PROC FREQ LEVELS data= NCdistribution_3 (keep = county2_char);
run;

proc export data = NCdistribution_3
   outfile="&_dcdata_default_path\NCHsg\Prog\Householderratio_NCcounty_&date..csv"
   dbms=csv
   replace;
run;

