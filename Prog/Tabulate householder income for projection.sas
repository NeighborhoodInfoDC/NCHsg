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

 Modifications: 

**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( RegHsg)
%DCData_lib( Ipums)

%let date=07112019; 

proc format;

	value agegroupnew
	.n= 'Not available'
	1='under 25 years old'
	2= '25-45 years old'
	3= '45-65 years old'
	4='65+ years old';
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
    3 = "Hispanic "
	4 = "All other non-Hispanic ";
  value agegroup
     .n = 'Not available'
    1= "0-5 years old"
	2= "5-9 years old"
	3= "10-14 years old "
	4="15-19 years old"
	5="20-24 years old "
	6="25-29 years old"
	7="30-34 years old"
	8="35-39 years old"
	9="40-44 years old"
    10="45-49 years old"
    11= "50-54 years old"
    12= "55-59 years old"
    13= "60-64 years old"
    14= "65-69 years old"
    15= "70-74 years old"
    16= "75-79 years old" 
    17 = "80-84 years old"
    18= "85+ years old";

	value newinc
	1= "$0-32,600"
	2= "32,600-54,300"
	3="$54,300-70,150"
	4="$86,880-108,600"
	5="$108,600-130,320"
	6="$130,320-217,200"
	7="More than 217,200";

run;

%macro householdinfo(year);


	data Household_&year. ;
		set Ipums.Acs_&year._NC;

		%assign_NCcounty;
		%assign_NCcounty2;

		fips2010= "37"+ county;

	run;

	data Inc_&year. ;
	set NCHsg.IncomeLimits_&year._NC (where= (State==37));

	run;

	proc sort data= Household_&year. ;
	by fips2010;
	run;

	proc sort data= Inc_&year. ;
	by fips2010;
	run;

	data Household_&year._2 ;
	merge Household_&year. Inc_&year.;
	by fips2010 ;
	run;

	data Householddetail_&year.;
		set Household_&year._2 (where=(relate=1));
		keep race hispan age hhincome hhincome_a pernum relate gq Jurisdiction hhwt perwt year serial numprec race1 agegroup incomecat totpop_&year. I50_1- I50_8 I30_1- I30_8 I80_1- I80_8  median&year. ;

		%dollar_convert( hhincome, hhincome_a, &year., 2016, series=CUUR0000SA0 )

        %Hud_inc_NCHsg( hhinc=hhincome, hhsize=numprec )
		  label
		  hud_inc = 'HUD income category for household'; 

		if hispan=0 then do;

		 if race=1 then race1=1;
		 else if race=2 then race1=2;
		 else race1=4;
		end;

		if hispan in(1 2 3 4) then race1=3;

		if 0<=age<25 then agegroup=1;
		else if 25<=age<45 then agegroup=2;
		else if 45<=age<65 then agegroup=3;
		else if age>=65 then agegroup=4;

		totpop_&year. = 1;
	run;

	proc freq data=Householddetail_&year.;
	  tables race1 * agegroup  / list missing;
	run;

	proc freq data=Householddetail_&year.;
	tables hud_inc/missing; 
	run;

	proc sort data=Householddetail_&year.;
	by county2 agegroup race1 relate hud_inc;
	run;

%mend householdinfo;

%householdinfo(2013);
%householdinfo(2014);
%householdinfo(2015);
%householdinfo(2016);
%householdinfo(2017);

/*remove serial 560493 and 255313 from 2013 as the are classified HoH but really reflect GQ - GQ=5 - have 11 and 20 people in the household)*/
data fiveyeartotal;
set Householddetail_2013 (where=(serial~=560493 and serial~=255313)) Householddetail_2014 Householddetail_2015 Householddetail_2016 Householddetail_2017;
totalpop=0.2;
run;
/*total COG*/
proc sort data=fiveyeartotal;
by agegroup race1 hud_inc;
run;

proc summary data=fiveyeartotal;
class agegroup race1 hud_inc;
	var totalpop;
	weight hhwt;
	output out = Householderbreakdown (where=(_TYPE_=7)) sum=;
	format race1 racenew. agegroup agegroupnew. ;
run;
proc sort data=Householderbreakdown;
by agegroup race1;
run;

proc transpose data=Householderbreakdown out=distribution;
by agegroup race1;
id hud_inc;
var totalpop;
run;

data distribution_2;
set distribution;
	denom= _1+_2+_3 +_4 +_5 +_6 +_7 ;
	
	incomecat1=_1/denom ;
	incomecat2=_2/denom ;
	incomecat3=_3/denom ;
	incomecat4=_4/denom ;
	incomecat5=_5/denom ;
	incomecat6=_6/denom ;
	incomecat7=_7/denom ;
run;

proc export data = distribution_2
   outfile="&_dcdata_default_path\NCHsg\Prog\Householderincometab_NC_&date..csv"
   dbms=csv
   replace;
run;

/****by jurisdiction****/
proc sort data=fiveyeartotal;
by county2 agegroup race1 hud_inc;
proc summary data=fiveyeartotal;
class county2 agegroup race1 hud_inc;
	var totalpop;
	weight hhwt;
	output out = Householderbreakdown_NC(where=(_TYPE_=15)) sum=;
	format race1 racenew. agegroup agegroupnew. county2 county2.;
run;
proc sort data=Householderbreakdown_NC;
by county2 agegroup race1 ;
run;

proc transpose data=Householderbreakdown_NC out=NCdistribution;
by county2 agegroup race1 ;
id hud_inc;
var totalpop;
run;
proc stdize data=NCdistribution out=NCdistribution_2 reponly missing=0;
   var _1 _2 _3 _4 _5 _6 _7;
run;
data NCdistribution_3;
	set NCdistribution_2;
	denom= _1+_2+_3 +_4 +_5 +_6 +_7 ;
	incomecat1=_1/denom ;
	incomecat2=_2/denom ;
	incomecat3=_3/denom ;
	incomecat4=_4/denom ;
	incomecat5=_5/denom ;
	incomecat6=_6/denom ;
	incomecat7=_7/denom ;
run;
proc sort data= NCdistribution_3;
by county2 race1 agegroup;
run;

proc export data = NCdistribution_3
   outfile="&_dcdata_default_path\NCHsg\Prog\Householderincometab_county_&date..csv"
   dbms=csv
   replace;
run;
