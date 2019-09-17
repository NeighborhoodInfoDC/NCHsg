/**************************************************************************
 Program:  tabulate householder income for projection.sas
 Library:  NCHsg
 Project:  NeighborhoodInfo DC
 Author:   Yipeng Su
 Created:  7/11/19
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Produce detailed tabulation of household income distribution by holders' age group, race ethnicity and jurisciation from 2013-2017
 ACS IPUMS data for NC:

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

/*crosswalk between county and PUMA as a baseline reference for assigning projection geographies. */
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
		if gq=5 then relate =12;  /*reclassify and don't assign household head*/
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

	data Householddetail_&year.;
		set Household_&year._2 (where=(relate=1));  /*keep only householders*/
		keep race hispan age hhincome hhincome_a pernum relate gq upuma county_char county2 county2_char hhwt perwt year serial numprec race1 agegroup totpop_&year. afact AFACT2;
        
		/*assign the summary unit-- county if larger than PUMA, PUMA if containing more than 1 county*/
		%assign_NCcounty2;  /* assign geography for counties that contain PUMAs  26 total*/
		%assign_NCcounty3;  /* assign geography for PUMAs that contain multiple counties  28 total*/
		county2_char = put(county2, 5.);

		/*inflation adjustment*/
		%dollar_convert( hhincome, hhincome_a, &year., 2017, series=CUUR0000SA0 )

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
	run;

	proc freq data=Householddetail_&year.;
	  tables race1 * agegroup  / list missing;
	run;

	proc freq data=Householddetail_&year.;
	tables agegroup/missing; 
	run;

/*make sure all PUMA got assigned a geography for tabulation, the output should be a blank dataset*/
proc freq data= Householddetail_&year. (where=(county2_char=""));
tables upuma;
run;

%mend householdinfo;

%householdinfo(2013);
%householdinfo(2014);
%householdinfo(2015);
%householdinfo(2016);
%householdinfo(2017);

%macro tabulateinc(year);
/*tabulate deciles of income for state by year*/
proc univariate data= Householddetail_&year.;
	var  hhincome_a;
	weight hhwt;
	output out= inc_&year. pctlpre= P_ pctlpts= 10 to 100 by 10 ;
run;  /*by nature of this function, the output dataset is named data1, data2, data3...*/

data inc_&year._2;
set inc_&year.;
year= &year.;
run;

data Householddetail_&year._inc;
	merge Householddetail_&year.(in=a) inc_&year._2;
	if a;
	by year ;
run;

%mend tabulateinc;

%tabulateinc(2013);
%tabulateinc(2014);
%tabulateinc(2015);
%tabulateinc(2016);
%tabulateinc(2017);

/*compile 13-17 data for tabulation */
data fiveyeartotal;
set Householddetail_2013_inc  Householddetail_2014_inc Householddetail_2015_inc Householddetail_2016_inc Householddetail_2017_inc;
totalpop=0.2;
totpop_wt= totalpop*AFACT2; 

if hhincome_a in ( 9999999, .n ) then inc = .n;
  else do;
 /*assign income category based on each year's HH income quintile*/
		if hhincome_a < P_10 then inc=1;
		if P_10  =< hhincome_a < P_20 then inc=2;
		if P_20  =< hhincome_a < P_30 then inc=3;
		if P_30  =< hhincome_a < P_40 then inc=4;
		if P_40  =< hhincome_a < P_50 then inc=5;
		if P_50  =< hhincome_a < P_60 then inc=6;
		if P_60  =< hhincome_a < P_70 then inc=7;
		if P_70  =< hhincome_a < P_80 then inc=8;
		if P_80  =< hhincome_a < P_90 then inc=9;
		if P_90  =< hhincome_a =< P_100 then inc=10;
  end;

run;

/****by NC analysis geography categories county2 (most of them are counties but if multiple counties are in each PUMA it is summarized by PUMA)****/
proc sort data=fiveyeartotal;
by county2_char agegroup race1 inc;
run;

proc summary data=fiveyeartotal;
class county2_char agegroup race1 inc;
	var totpop_wt;
	weight hhwt;
	output out = Householderbreakdown_NC(where=(_TYPE_=15)) sum=;
	format race1 racenew. agegroup agegroupnew. ;
run;

proc sort data=Householderbreakdown_NC;
by county2_char agegroup race1 ;
run;

proc transpose data=Householderbreakdown_NC out=NCdistribution;
by county2_char agegroup race1 ;
id inc;
var totpop_wt;
run;
proc stdize data=NCdistribution out=NCdistribution_2 reponly missing=0;
   var _1 _2 _3 _4 _5 _6 _7 _8 _9 _10;
run;
data NCdistribution_3;
	set NCdistribution_2;
	denom= _1+_2+_3 +_4 +_5 +_6 + _7 + _8 +_9 + _10;
	incomecat1=_1/denom ;
	incomecat2=_2/denom ;
	incomecat3=_3/denom ;
	incomecat4=_4/denom ;
	incomecat5=_5/denom ;
	incomecat6=_6/denom ;
    incomecat7=_7/denom ;
	incomecat8=_8/denom ;
	incomecat9=_9/denom ;
	incomecat10=_10/denom ;

run;
proc sort data= NCdistribution_3;
by county2_char race1 agegroup;
run;

/*should have 54 unique county2_char values*/
PROC FREQ LEVELS data= NCdistribution_3 (keep = county2_char);
run;

proc export data = NCdistribution_3
   outfile="&_dcdata_default_path\NCHsg\Prog\Householderincometab_NCcounty_&date..csv"
   dbms=csv
   replace;
run;

/*total NC state*/
proc sort data=fiveyeartotal;
by agegroup race1 inc;
run;

proc summary data=fiveyeartotal;
class agegroup race1 inc;
	var totpop_wt;
	weight hhwt;
	output out = Householderbreakdown (where=(_TYPE_=7)) sum=;
	format race1 racenew. agegroup agegroupnew. ;
run;

proc sort data=Householderbreakdown;
by agegroup race1;
run;

proc transpose data=Householderbreakdown out=distribution;
by agegroup race1;
id inc;
var totpop_wt;
run;
proc stdize data=distribution out=distribution_2 reponly missing=0;
   var _1 _2 _3 _4 _5 _6 _7 _8 _9 _10;
run;

data distribution_3;

retain agegroup race1 incomecat1 incomecat2 incomecat3 incomecat4 incomecat5 incomecat6 incomecat7 incomecat8 incomecat9 incomecat10;
set distribution_2;
	denom= _1+_2+_3 +_4 +_5 +_6 + _7 + _8 +_9 + _10 ;
	
	incomecat1=_1/denom ;
	incomecat2=_2/denom ;
	incomecat3=_3/denom ;
	incomecat4=_4/denom ;
	incomecat5=_5/denom ;
	incomecat6=_6/denom ;
	incomecat7=_7/denom ;
	incomecat8=_8/denom ;
	incomecat9=_9/denom ;
	incomecat10=_10/denom ;

run;

proc export data = distribution_3
   outfile="&_dcdata_default_path\NCHsg\Prog\Householderincometab_NC_&date..csv"
   dbms=csv
   replace;
run;
