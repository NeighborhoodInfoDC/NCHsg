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


 Modifications: 01/16/19 LH Update incomecat for capped 80% of AMI. Add date for output. 
			    02/13/19 LH Change relate for 2 serials to better reflect household structure. 
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( NCHsg)
%DCData_lib( Ipums)

%let date=08072019;

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
run;


%macro householdinfo(year);


	data Household_&year. ;
		set Ipums.Acs_&year._NC;
/*create county for merging with income limits and county2 for tabulating*/
		%assign_NCcounty;
		%assign_NCcounty2;
		county_char = put(county, 5.);
		county2_char = put(county2, 5.);
	run;


	data Householddetail_&year.;
		set Household_&year. ;
		keep race hispan age hhincome pernum relate gq puma county2_char upuma hhwt perwt year serial numprec race1 agegroup  totpop_&year. ;

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

		proc sort data=Householddetail_&year.;
		by county2 agegroup race1 relate;
		run;

%mend householdinfo;

%householdinfo(2013);
%householdinfo(2014);
%householdinfo(2015);
%householdinfo(2016);
%householdinfo(2017);


/*make sure all PUMA got assigned a geography for tabulation*/
proc freq data= Household_2013 (where=(county2_char=""));
tables upuma;
run;

/*remove numprec >10 from 2013-2017 as the are classified HoH but really reflect GQ - GQ=5 )*/
%macro droplargeHH(year);

data Householddetail_&year._r;
	set Householddetail_&year.;

if numprec in (11, 12, 13, 14, 15, 16, 17, 18, 19, 20) then drop=1;

run; 

%mend droplargeHH;

%droplargeHH(2013);
%droplargeHH(2014);
%droplargeHH(2015);
%droplargeHH(2016);
%droplargeHH(2017);

/*compile 13-17 data for tabulation*/
data fiveyeartotal;
set Householddetail_2013_r(where=(drop~= 1 )) Householddetail_2014_r(where=(drop~= 1 )) Householddetail_2015_r(where=(drop~= 1 )) Householddetail_2016_r(where=(drop~= 1 )) Householddetail_2017_r(where=(drop~= 1 ));
totalpop=0.2;
run;

/*total NC*/

proc sort data=fiveyeartotal;
by agegroup race1 relate;
run;

proc summary data=fiveyeartotal;
class agegroup race1 relate;
	var totalpop;
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
	var totalpop;
run;
proc stdize data=distribution out=distribution_2 reponly missing=0;
   var grandchild parent Parent_in_Law;
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
	var totalpop;
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
	var totalpop;
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

proc export data = NCdistribution_3
   outfile="&_dcdata_default_path\NCHsg\Prog\Householderratio_NCcounty_&date..csv"
   dbms=csv
   replace;
run;

