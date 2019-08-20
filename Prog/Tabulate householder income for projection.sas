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

%let date=08072019; 

proc format;

	value agegroupnew
	.n= 'Not available'
	1= 'under 17 years old'
	2= '17-25 years old'
	3= '25-45 years old'
	4= '45-65 years old'
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

data crosswalk;
	set NCHsg.PUMA_county_crosswalk ;
	county_char= put(county14, 5.);
	length puma_new $5;
	*puma_new = input( puma12,best5.),z5.);
	*puma_new= translate(right(puma12),'0',' ');  /*not right*/
	puma_new = put(input(cats(puma12),8.),z5.);
	upuma= "37"||puma_new;
run;

%macro householdinfo(year);

	data Household_&year. ;
		set Ipums.Acs_&year._NC;
	run;

	/* no longer need HUD income limits

	data Inc_&year. ;
	set NCHsg.IncomeLimits_&year. (where= (State=37));
        county_new = put(County,z3.);
        state2= put(State, z2.);
        county_char= state2||county_new;
	run;
*/

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
		set Household_&year._2 (where=(relate=1));
		keep race hispan age hhincome hhincome_a pernum relate gq upuma county_char county2 county2_char hhwt perwt year serial numprec race1 agegroup totpop_&year. afact AFACT2;
        
		/*assign the summary unit-- county if larger than PUMA, PUMA if containing more than 1 county*/
		%assign_NCcounty2;
		county2_char = put(county2, 5.);

		/*inflation adjust*/
		%dollar_convert( hhincome, hhincome_a, &year., 2016, series=CUUR0000SA0 )

		if hispan=0 then do;

		 if race=1 then race1=1;
		 else if race=2 then race1=2;
         else if race in (4 5 6) then race1=4;
		 else race1=5;
		end;

		if hispan in(1 2 3 4) then race1=3;

		
		if 0<=age<17 then agegroup=1;
		else if 17<=age<25 then agegroup=2;
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


/*remove numprec >10 from 2013-2017 as the are classified HoH but really reflect GQ - GQ=5 ) and then put income in decile*/
%macro droplargeHH(year);

data Householddetail_&year._r;
	set Householddetail_&year.;
	if numprec in (11, 12, 13, 14, 15, 16, 17, 18, 19, 20) then drop=1;
run; 

data Householddetail_&year._noGQ;
set Householddetail_&year._r (where=(drop~= 1 ));
run; 

	/*tabulate deciles of income for state by year*/
proc univariate data= Householddetail_&year._noGQ;
	var  hhincome_a;
	weight hhwt;
	output pctlpre= P_ pctlpts= 10 to 100 by 10 ;
run;  /*by nature of this function, the output dataset is named data1, data2, data3...*/


%mend droplargeHH;

%droplargeHH(2013);
%droplargeHH(2014);
%droplargeHH(2015);
%droplargeHH(2016);
%droplargeHH(2017);

/*compile 13-17 data for tabulation */
data fiveyeartotal;
set Householddetail_2013_noGQ  Householddetail_2014_noGQ Householddetail_2015_noGQ Householddetail_2016_noGQ Householddetail_2017_noGQ;
totalpop=0.2;
totpop_wt= totalpop*AFACT2; 

if hhincome_a in ( 9999999, .n ) then inc = .n;
  else do;

    select ( year );
      when ( 2013 )
	        do; 
		if hhincome_a < 11332.894053 then inc=1;
		if 11332.894053  =< hhincome_a < 19781.051439 then inc=2;
		if 19781.051439  =< hhincome_a < 27817.103586 then inc=3;
		if 27817.103586  =< hhincome_a < 36677.366209 then inc=4;
		if 36677.366209  =< hhincome_a < 46361.839309 then inc=5;
		if 46361.839309  =< hhincome_a < 58106.838601 then inc=6;
		if 58106.838601  =< hhincome_a < 73457.758728 then inc=7;
		if 73457.758728  =< hhincome_a < 93753.941715 then inc=8;
		if 93753.941715  =< hhincome_a < 131461.57102 then inc=9;
		if 131461.57102  =< hhincome_a =< 1209528.8744 then inc=10;
        end;

      when ( 2014 )
        do;
		if hhincome_a < 11821.10714 then inc=1;
		if 11821.10714  =< hhincome_a < 20174.959871 then inc=2;
		if 20174.959871  =< hhincome_a < 28386.87821 then inc=3;
		if 28386.87821  =< hhincome_a < 36700.178258 then inc=4;
		if 36700.178258  =< hhincome_a < 46635.585631 then inc=5;
		if 46635.585631  =< hhincome_a < 58801.390579 then inc=6;
		if 58801.390579  =< hhincome_a < 73603.119931 then inc=7;
		if 73603.119931  =< hhincome_a < 94284.988341 then inc=8;
		if 94284.988341  =< hhincome_a < 131897.60197 then inc=9;
		if 131897.60197  =< hhincome_a =< 910407.73689 then inc=10;
        end;

      when ( 2015 )
        do;
		if hhincome_a < 12151.381546 then inc=1;
		if 12151.381546  =< hhincome_a < 20252.302577 then inc=2;
		if 20252.302577  =< hhincome_a < 29163.315712 then inc=3;
		if 29163.315712  =< hhincome_a < 37669.282794 then inc=4;
		if 37669.282794  =< hhincome_a < 48605.526186 then inc=5;
		if 48605.526186  =< hhincome_a < 60756.907732 then inc=6;
		if 60756.907732  =< hhincome_a < 76351.180717 then inc=7;
		if 76351.180717  =< hhincome_a < 99236.28263 then inc=8;
		if 99236.28263  =< hhincome_a < 138120.70358 then inc=9;
		if 138120.70358  =< hhincome_a =< 1146280.3259 then inc=10;
        end;

      when ( 2016 )
        do;
		if hhincome_a < 12000 then inc=1;
		if 12000  =< hhincome_a < 20700 then inc=2;
		if 20700  =< hhincome_a < 30000 then inc=3;
		if 30000  =< hhincome_a < 40000 then inc=4;
		if 40000  =< hhincome_a < 50000 then inc=5;
		if 50000  =< hhincome_a < 62500 then inc=6;
		if 62500  =< hhincome_a < 78270 then inc=7;
		if 78270  =< hhincome_a < 100000 then inc=8;
		if 100000  =< hhincome_a < 140100 then inc=9;
		if 140100  =< hhincome_a =< 1035000 then inc=10;
        end;

      when ( 2017 )
        do;
		if hhincome_a < 12435.088528 then inc=1;
		if 12435.088528  =< hhincome_a < 21541.098238 then inc=2;
		if 21541.098238  =< hhincome_a < 30353.365698 then inc=3;
		if 30353.365698  =< hhincome_a < 40144.773988 then inc=4;
		if 40144.773988  =< hhincome_a < 50915.323107 then inc=5;
		if 50915.323107  =< hhincome_a < 63644.153884 then inc=6;
		if 63644.153884  =< hhincome_a < 79408.32123 then inc=7;
		if 79408.32123  =< hhincome_a < 102809.78704 then inc=8;
		if 102809.78704  =< hhincome_a < 145794.06944 then inc=9;
		if 145794.06944  =< hhincome_a =< 1537251.1015 then inc=10;
        end;
    end;

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

data distribution_2;
set distribution;
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

proc export data = distribution_2
   outfile="&_dcdata_default_path\NCHsg\Prog\Householderincometab_NC_&date..csv"
   dbms=csv
   replace;
run;
