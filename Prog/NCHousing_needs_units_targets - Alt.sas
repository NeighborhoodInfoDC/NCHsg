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

  1= 'natural affordable (rent < $750)'
  0= 'not natural affordable';
run;

data crosswalk;
	set NCHsg.PUMA_county_crosswalk ;
	county_char= put(county14, 5.);
	length puma_new $5;
	puma_new = put(input(cats(puma12),8.),z5.);
	upuma= "37"||puma_new;
run;
	proc sort data= crosswalk;
	by upuma;
	run;
proc sort data=NCHsg.NC17_limits out=NC17_limits;
by MID;
run;

%macro single_year(year);

	data NCvacant_&year._1 ;
		set Ipums.Acs_&year._vacant_NC ;
	run;

	proc sort data= NCvacant_&year._1;
	by upuma;
	run;

	/*merge IPUMS with crosswalk to county, check #observations*/
	data NCvacant_&year. ;
	merge NCvacant_&year._1(in=a) crosswalk;
	if a;
	by upuma ;
	%assign_NCcounty2;
	%assign_NCcounty3;
	county2_char = county2;

	run;


	proc sort data=Ipums.Acs_&year._NC out=NCarea_&year._1;
	by upuma;
	run;

	data NCarea_&year. ;
	merge NCarea_&year._1(in=a) crosswalk;
	if a;
	by upuma ;
	%assign_NCcounty2;
	%assign_NCcounty3;
	county2_char = county2;
	run;

 %**create ratio for rent to rentgrs to adjust rents on vacant units**;
	 data Ratio_&year.;

		  set NCarea_&year.
		    (keep= rent rentgrs pernum gq ownershpd county2_char
		     where=(pernum=1 and gq in (1,2) and ownershpd in ( 22 )));
		     
		  Ratio_rentgrs_rent_&year. = rentgrs / rent;
		 
		run;

		proc means data=Ratio_&year.;
		  var  Ratio_rentgrs_rent_&year. rentgrs rent;
		  output out=Ratio_&year (keep=Ratio_rentgrs_rent_&year.) mean=;
		run;

data Housing_needs_baseline_&year.;

  set NCarea_&year.
        (keep=year serial pernum hhwt hhincome numprec UNITSSTR BUILTYR2 bedrooms gq ownershp owncost ownershpd rentgrs valueh county2_char afact afact2
         where=(pernum=1 and gq in (1,2) and ownershpd in ( 12,13,21,22 )));

	 *adjust all incomes to 2017 $ to match use of 2017 family of 4 income limit in projections (originally based on use of most recent 5-year IPUMS; 

	  if hhincome ~=.n or hhincome ~=9999999 then do; 
		 %dollar_convert( hhincome, hhincome_a, &year., 2017, series=CUUR0000SA0 )
	   end; 

	*create HUD_inc - uses 2017 limits but has categories for 120-200% and 200%+ AMI; 

		%Hud_inc_NCState( hhinc=hhincome_a, hhsize=numprec )  /*use this statewide macro for now*/
run; 

data Housing_needs_baseline_&year._3;
  set Housing_needs_baseline_&year.;

	 *adjust housing costs for inflation; 

	  %dollar_convert( rentgrs, rentgrs_a, &year., 2017, series=CUUR0000SA0L2 )
	  %dollar_convert( owncost, owncost_a, &year., 2017, series=CUUR0000SA0L2 )
	  %dollar_convert( valueh, valueh_a, &year., 2017, series=CUUR0000SA0L2 )

  	** Cost-burden flag & create cost ratio **;
	    if ownershpd in (21, 22)  then do;

			if hhincome_a > 0 then Costratio= (rentgrs_a*12)/hhincome_a;
			  else if hhincome_a = 0 and rentgrs_a > 0 then costratio=1;
			  else if hhincome_a =0 and rentgrs_a = 0 then costratio=0; 
			  else if hhincome_a < 0 and rentgrs_a >= 0 then costratio=1; 
			  			  
		end;

	    else if ownershpd in ( 12,13 ) then do;
			if hhincome_a > 0 then Costratio= (owncost_a*12)/hhincome_a;
			  else if hhincome_a = 0 and owncost_a > 0 then costratio=1;
			  else if hhincome_a =0 and owncost_a = 0 then costratio=0; 
			  else if hhincome_a < 0 and owncost_a >= 0 then costratio=1; 
		end;
	    
			if Costratio >= 0.3 then costburden=1;
		    else if HHIncome_a~=. then costburden=0;
			if costratio >= 0.5 then severeburden=1;
			else if HHIncome_a~=. then severeburden=0; 

		tothh = 1;

    
    ****** Rental units ******;
    
   if ownershpd in (21, 22) then do;
        
    Tenure = 1;

	 *create maximum desired or affordable rent based on HUD_Inc categories*; 
    /* need to discuss for NC, use hudinc for now*/
	  if hud_inc in(1 2 3) then max_rent=HHINCOME_a/12*.3; *under 80% of AMI then pay 30% threshold; 
	  if hud_inc =4 then max_rent=HHINCOME_a/12*.2; *avg for all HH hud_inc=4 in NC; 
	  if costratio <=.16 and hud_inc = 5 then max_rent=HHINCOME_a/12*.16; *avg for all HH hud_inc=5 in NC; 	
		else if hud_inc = 5 then max_rent=HHINCOME_a/12*costratio; *allow 120-200% above average to spend more; 
	  if costratio <=.15 and hud_inc = 6 then max_rent=HHINCOME_a/12*.15; *avg for all HH hud_inc=6 in NC; 
	  	else if hud_inc=6 then max_rent=HHINCOME_a/12*costratio; *allow 200%+ above average to spend more; 
     
	 *create flag for household could "afford" to pay more; 
		couldpaymore=.;

		if max_rent ~= . then do; 
			if max_rent > rentgrs_a*1.1 then couldpaymore=1; 
			else if max_rent <= rentgrs_a*1.1 then couldpaymore=0; 
		end; 

	
    	*rent cost categories that make more sense for rents - no longer used in targets;
		/*need to discuss for NC*/
			rentlevel=.;
			if 0 <=rentgrs_a<350 then rentlevel=1;
			if 350 <=rentgrs_a<700 then rentlevel=2;
			if 700 <=rentgrs_a<1000 then rentlevel=3;
			if 1000 <=rentgrs_a<1500 then rentlevel=4;
			if 1500 <=rentgrs_a<2500 then rentlevel=5;
			if rentgrs_a >= 2500 then rentlevel=6;

			mrentlevel=.;
			if max_rent<350 then mrentlevel=1;
			if 350 <=max_rent<700 then mrentlevel=2;
			if 700 <=max_rent<1000 then mrentlevel=3;
			if 1000 <=max_rent<1500 then mrentlevel=4;
			if 1500 <=max_rent<2500 then mrentlevel=5;
			if max_rent >= 2500 then mrentlevel=6;

		 *rent cost categories now used in targets that provide a set of categories useable for renters and owners combined; 
			/*need to discuss for NC*/
			allcostlevel=.;
			if rentgrs_a<350 then allcostlevel=1;
			if 350 <=rentgrs_a<700 then allcostlevel=2;
			if 700 <=rentgrs_a<1000 then allcostlevel=3;
			if 1000 <=rentgrs_a<1500 then allcostlevel=4;
			if 1500 <=rentgrs_a<2500 then allcostlevel=5;
			if rentgrs_a >= 2500 then allcostlevel=6; 

			mallcostlevel=.;

			*for desired cost for current housing needs is current payment if not cost-burdened
			or income-based payment if cost-burdened;

			if costburden=1 then do; 

				if max_rent<350 then mallcostlevel=1;
				if 350 <=max_rent<700 then mallcostlevel=2;
				if 700 <=max_rent<1000 then mallcostlevel=3;
				if 1000 <=max_rent<1500 then mallcostlevel=4;
				if 1500 <=max_rent<2500 then mallcostlevel=5;
				if max_rent >= 2500 then mallcostlevel=6;

			end; 

			else if costburden=0 then do;

				if rentgrs_a<350 then mallcostlevel=1;
				if 350 <=rentgrs_a<700 then mallcostlevel=2;
				if 700 <=rentgrs_a<1000 then mallcostlevel=3;
				if 1000 <=rentgrs_a<1500 then mallcostlevel=4;
				if 1500 <=rentgrs_a<2500 then mallcostlevel=5;
				if rentgrs_a >= 2500 then mallcostlevel=6;

			end; 




	end;

	
	  		
		
  	else if ownershpd in ( 12,13 ) then do;

	    ****** Owner units ******;
	    
	    Tenure = 2;

		*create maximum desired or affordable owner costs based on HUD_Inc categories*; 

		/*need to discuss for NC*/
		if hud_inc in(1 2 3) then max_ocost=HHINCOME_a/12*.3; *under 80% of AMI then pay 30% threshold; 
		if hud_inc =4 then max_ocost=HHINCOME_a/12*.20; *avg for all HH hud_inc=4 in NC; 
		if costratio <=.16 and hud_inc = 5 then max_ocost=HHINCOME_a/12*.16; *avg for all HH HUD_inc=5 in NC;  
			else if hud_inc = 5 then max_ocost=HHINCOME_a/12*costratio; *allow 120-200% above average to pay more; 
		if costratio <=.15 and hud_inc=6 then max_ocost=HHINCOME_a/12*.15; *avg for all HH HUD_inc=6 in NC; 
			else if hud_inc = 6 then max_ocost=HHINCOME_a/12*costratio; *allow 120-200% above average to pay more; 
		
		*create flag for household could "afford" to pay more; 
		couldpaymore=.;

		if max_ocost ~= . then do; 
			if max_ocost > owncost_a*1.1 then couldpaymore=1; 
			else if max_ocost <= owncost_a*1.1 then couldpaymore=0; 
		end; 

	    **** 
	    Calculate monthly payment for first-time homebuyers. 
	    Using 4.1% as the effective mortgage rate for NC in 2017, 
	    calculate monthly P & I payment using monthly mortgage rate and compounded interest calculation
	    ******; 
	    
	    loan = .9 * valueh_a;
	    month_mortgage= (4.1 / 12) / 100; 
	    monthly_PI = loan * month_mortgage * ((1+month_mortgage)**360)/(((1+month_mortgage)**360)-1);

	    ****
	    Calculate PMI and taxes/insurance to add to Monthly_PI to find total monthly payment
	    ******;
	    
	    PMI = (.007 * loan ) / 12; **typical annual PMI is .007 of loan amount;
	    tax_ins = .25 * monthly_PI; **taxes assumed to be 25% of monthly PI; 
	    total_month = monthly_PI + PMI + tax_ins; **Sum of monthly payment components;

		
	
		*owner cost categories that make more sense for owner costs - no longer used in targets;
       /*need to discuss for NC*/
		ownlevel=.;
			if 0 <=total_month<350 then ownlevel=1;
			if 350 <=total_month<700 then ownlevel=2;
			if 000 <=total_month<1000 then ownlevel=3;
			if 1000 <=total_month<1500 then ownlevel=4;
			if 1500 <=total_month<2500 then ownlevel=5;
			if total_month >= 2500 then ownlevel=6;

		mownlevel=.;
			if max_ocost<350 then mownlevel=1;
			if 350 <=max_ocost<700 then mownlevel=2;
			if 700 <=max_ocost<1000 then mownlevel=3;
			if 1000 <=max_ocost<1500 then mownlevel=4;
			if 1500 <=max_ocost<2500 then mownlevel=5;
			if max_ocost >= 2500 then mownlevel=6;

         * Leah: this is what differs from the other program
		 *owner cost categories now used in targets that provide a set of categories useable for renters and owners combined; 
			allcostlevel=.;
			if owncost_a<350 then allcostlevel=1;
			if 350 <=owncost_a<700 then allcostlevel=2;
			if 700 <=owncost_a<1000 then allcostlevel=3;
			if 1000 <=owncost_a<1500 then allcostlevel=4;
			if 1500 <=owncost_a<2500 then allcostlevel=5;
			if owncost_a >= 2500 then allcostlevel=6; 

	
			*for desired cost for current housing needs is current payment if not cost-burdened
			or income-based payment if cost-burdened;
			mallcostlevel=.;

			if costburden=1 then do; 

				if max_ocost<350 then mallcostlevel=1;
				if 350 <=max_ocost<700 then mallcostlevel=2;
				if 700 <=max_ocost<1000 then mallcostlevel=3;
				if 1000 <=max_ocost<1500 then mallcostlevel=4;
				if 1500 <=max_ocost<2500 then mallcostlevel=5;
				if max_ocost >= 2500 then mallcostlevel=6;

			end;

			else if costburden=0 then do; 

				if owncost_a<350 then mallcostlevel=1;
				if 350 <=owncost_a<700 then mallcostlevel=2;
				if 700 <=owncost_a<1000 then mallcostlevel=3;
				if 1000 <=owncost_a<1500 then mallcostlevel=4;
				if 1500 <=owncost_a<2500 then mallcostlevel=5;
				if owncost_a >= 2500 then mallcostlevel=6;

			end; 
  end;

  *add structure of housing variable;
    if UNITSSTR =00 then structure=5;
	if UNITSSTR in (01, 02) then structure=4;
	if UNITSSTR in (03, 04) then structure=1;
	if UNITSSTR in (05, 06, 07) then structure=2;
	if UNITSSTR in (08, 09, 10) then structure=3;

  		*costburden and couldpaymore do not overlap. create a category that measures who needs to pay less, 
		who pays the right amount, and who could pay more;
		paycategory=.;
		if costburden=1 then paycategory=1;
		if costburden=0 and couldpaymore=0 then paycategory=2;
		if couldpaymore=1 then paycategory=3; 

		if BUILTYR2 in ( 00, 9999999, .n , . ) then structureyear=.;
		else do; 
		    if BUILTYR2  in (07, 08, 09, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22) then structureyear=1;
			else if BUILTYR2  in (04, 05, 06) then structureyear=2;
            else if BUILTYR2 in (01, 02, 03)  then structureyear=3;
		end;

		
	if rentgrs in ( 9999999, .n , . ) then affordable=.;
		else do; 
		    if rentgrs_a<750 then affordable=1;
			else if rentgrs_a>=750 then affordable=0;
			
		end;

	  label affordable = 'Natural affordable rental unit';

	total=1;


			label rentlevel = 'Rent Level Categories based on Current Gross Rent'
		 		  mrentlevel='Rent Level Categories based on Max affordable-desired rent'
				  allcostlevel='Housing Cost Categories (tenure combined) based on Current Rent or Current Owner Costs'
				  mallcostlevel='Housing Cost Categories (tenure combined) based on Max affordable-desired Rent-Owner Cost'
				  ownlevel = 'Owner Cost Categories based on First-Time HomeBuyer Costs'
				  mownlevel = 'Owner Cost Categories based on Max affordable-desired First-Time HomeBuyer Costs'
				  couldpaymore = "Occupant Could Afford to Pay More - Costs+10% are > Max affordable cost"
				  paycategory = "Whether Occupant pays too much, the right amount or too little" 
                  structure = 'Housing structure type'
				  structureyear = 'Age of structure'
				;

	
format mownlevel ownlevel ocost. rentlevel mrentlevel rcost. allcostlevel mallcostlevel acost. hud_inc hud_inc. structure structure.; 
run;

data Housing_needs_vacant_&year. Other_vacant_&year. ;

  set NCvacant_&year.(keep=year serial hhwt bedrooms gq vacancy rent valueh county2_char BUILTYR2 UNITSSTR);

  	if _n_ = 1 then set Ratio_&year.;

 	retain Total 1;

  *reassign vacant but rented or sold based on whether rent or value is available; 	
  vacancy_r=vacancy; 
  if vacancy=3 and rent ~= .n then vacancy_r=1; 
  if vacancy=3 and valueh ~= .u then vacancy_r=2; 
    
    ****** Rental units ******;
	 if  vacancy_r = 1 then do;
	    Tenure = 1;
	    
	    	** Impute gross rent for vacant units **;
	  		rentgrs = rent*Ratio_rentgrs_rent_&year.;

			  %dollar_convert( rentgrs, rentgrs_a, &year., 2017, series=CUUR0000SA0L2 )

		if rent in ( 9999999, .n , . ) then affordable_vacant=.;
		else do; 
		    if rentgrs_a<700 then affordable_vacant=1;
			else if rentgrs_a>=700 then affordable_vacant=0;

		end;

	  label affordable_vacant = 'Natural affordable vacant rental unit';

		/*create rent level categories*/ 
			/*need to discuss for NC*/
		rentlevel=.;
		if 0 <=rentgrs_a<350 then rentlevel=1;
		if 350 <=rentgrs_a<700 then rentlevel=2;
		if 700 <=rentgrs_a<1000 then rentlevel=3;
		if 1000 <=rentgrs_a<1500 then rentlevel=4;
		if 1500 <=rentgrs_a<2500 then rentlevel=5;
		if rentgrs_a >= 2500 then rentlevel=6;

		/*create  categories now used in targets for renter/owner costs combined*/ 
				allcostlevel=.;
				if rentgrs_a<350 then allcostlevel=1;
				if 350 <=rentgrs_a<700 then allcostlevel=2;
				if 700 <=rentgrs_a<1000 then allcostlevel=3;
				if 1000 <=rentgrs_a<1500 then allcostlevel=4;
				if 1500 <=rentgrs_a<2500 then allcostlevel=5;
				if rentgrs_a >= 2500 then allcostlevel=6;
	  end;


	  else if vacancy_r = 2 then do;

	    ****** Owner units ******;
	    
	    Tenure = 2;

	    **** 
	    Calculate  monthly payment for first-time homebuyers. 
	    Using 3.69% as the effective mortgage rate for DC in 2016, 
	    calculate monthly P & I payment using monthly mortgage rate and compounded interest calculation
	    ******; 
	    %dollar_convert( valueh, valueh_a, &year., 2017, series=CUUR0000SA0L2 )
	    loan = .9 * valueh_a;
	    month_mortgage= (4.1 / 12) / 100; 
	    monthly_PI = loan * month_mortgage * ((1+month_mortgage)**360)/(((1+month_mortgage)**360)-1);

	    ****
	    Calculate PMI and taxes/insurance to add to Monthly_PI to find total monthly payment
	    ******;
	    
	    PMI = (.007 * loan ) / 12; **typical annual PMI is .007 of loan amount;
	    tax_ins = .25 * monthly_PI; **taxes assumed to be 25% of monthly PI; 
	    total_month = monthly_PI + PMI + tax_ins; **Sum of monthly payment components;
		
			/*create owner cost level categories*/ 
			ownlevel=.;
				if 0 <=total_month<350 then ownlevel=1;
				if 350 <=total_month<700 then ownlevel=2;
				if 700 <=total_month<1000 then ownlevel=3;
				if 1000 <=total_month<1500 then ownlevel=4;
				if 1500 <=total_month<2500 then ownlevel=5;
				if total_month >= 2500 then ownlevel=6;
			
			/*create  categories now used in targets for renter/owner costs combined*/ 
				allcostlevel=.;
				if total_month<350 then allcostlevel=1;
				if 350 <=total_month<700 then allcostlevel=2;
				if 700 <=total_month<1000 then allcostlevel=3;
				if 1000 <=total_month<1500 then allcostlevel=4;
				if 1500 <=total_month<2500 then allcostlevel=5;
				if total_month >= 2500 then allcostlevel=6; 

	  end;


	  paycategory=4; *add vacant as a category to paycategory; 

		if BUILTYR2 in ( 00, 9999999, .n , . ) then structureyear=.;
		else do; 
		    if BUILTYR2  in (07, 08, 09, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22) then structureyear=1;
			else if BUILTYR2  in (04, 05, 06) then structureyear=2;
            else if BUILTYR2 in (01, 02, 03)  then structureyear=3;
		end;

		
  *add structure of housing variable;
    if UNITSSTR =00 then structure=5;
	if UNITSSTR in (01, 02) then structure=4;
	if UNITSSTR in (03, 04) then structure=1;
	if UNITSSTR in (05, 06, 07) then structure=2;
	if UNITSSTR in (08, 09, 10) then structure=3;

		label rentlevel = 'Rent Level Categories based on Current Gross Rent'
		 		  allcostlevel='Housing Cost Categories (tenure combined) based on Current Rent or First-time Buyer Mtg'
				  ownlevel = 'Owner Cost Categories based on First-Time HomeBuyer Costs'
				  paycategory = "Whether Occupant pays too much, the right amount or too little" 
				  structureyear = 'Age of structure'
				  structure = 'Housing structure type'
				;
	format ownlevel ocost. rentlevel rcost. vacancy_r VACANCY_F. allcostlevel acost. ; 

	*output other vacant - seasonal separately ;
	if vacancy in (1, 2, 3) then output Housing_needs_vacant_&year.;
	else if vacancy in (4, 7, 9) then output other_vacant_&year.; 
	run;

%mend single_year; 

%single_year(2013);
%single_year(2014);
%single_year(2015); 
%single_year(2016);
%single_year(2017);

/*merge single year data and reweight

revised to match Steven's files in https://urbanorg.box.com/s/nm4wb0arxsxv8aml98b6y062tudzp2i6
*/
data projectedHH;
set NChsg.projection_for_calibration;
county2_char= puma;
run;

data fiveyeartotal1;
set Housing_needs_baseline_2013_3 Housing_needs_baseline_2014_3 Housing_needs_baseline_2015_3 Housing_needs_baseline_2016_3 Housing_needs_baseline_2017_3;
totalpop=0.2;
merge=1;
*totpop_wt= totalpop*AFACT2; 
geoid=.;
if county2_char= "0100" then geoid=1;
else if  county2_char= "0200" then geoid=2;
else if  county2_char= "0300" then geoid=3;
else if  county2_char= "0400" then geoid=4;
else if  county2_char= "0500 or 0600" then geoid=5;
else if  county2_char= "0700" then geoid=6;
else if  county2_char= "0800" then geoid=7;
else if  county2_char= "0900" then geoid=8;
else if  county2_char= "1000" then geoid=9;
else if  county2_char= "1100" then geoid=10;
else if  county2_char= "1201 to 1208" then geoid=11;
else if  county2_char= "1301 to 1302" then geoid=12;
else if  county2_char= "1400" then geoid=13;
else if  county2_char= "1500" then geoid=14;
else if  county2_char= "1600" then geoid=15;
else if  county2_char= "1701 to 1704" then geoid=16;
else if  county2_char= "1801 to 1803" then geoid=17;
else if  county2_char= "1900 or 2900" then geoid=18;
else if  county2_char= "2000" then geoid=19;
else if  county2_char= "2100" then geoid=20;
else if  county2_char= "2201 to 2202" then geoid=21;
else if  county2_char= "2300 or 2400" then geoid=22;
else if  county2_char= "2500" then geoid=23;
else if  county2_char= "2600 or 2700" then geoid=24;
else if  county2_char= "2800" then geoid=25;
else if  county2_char= "3001 to 3003" then geoid=26;
else if  county2_char= "3101 to 3108" then geoid=27;
else if  county2_char= "3200 or 3300" then geoid=28;
else if  county2_char= "3400" then geoid=29;
else if  county2_char= "3500" then geoid=30;
else if  county2_char= "3600" then geoid=31;
else if  county2_char= "3700" then geoid=32;
else if  county2_char= "3800" then geoid=33;
else if  county2_char= "3900" then geoid=34;
else if  county2_char= "4000" then geoid=35;
else if  county2_char= "4100 or 4500" then geoid=36;
else if  county2_char= "4200" then geoid=37;
else if  county2_char= "4300" then geoid=38;
else if  county2_char= "4400" then geoid=39;
else if  county2_char= "4600 or 4700" then geoid=40;
else if  county2_char= "4800" then geoid=41;
else if  county2_char= "4900 or 5100" then geoid=42;
else if  county2_char= "5001 to 5003" then geoid=43;
else if  county2_char= "5200" then geoid=44;
else if  county2_char= "5300 or 5400" then geoid=45;

run;

/*calculate average cost ratio for each hud_inc group that is used for maximum desired or affordable rent/owncost*/
proc sort data= fiveyeartotal1;
by hud_inc /*tenure*/;
run;

proc summary data= fiveyeartotal1;
by hud_inc /*tenure*/;
var costratio HHincome_a;
output out= costratio_hudinc mean=;
run;

proc summary data= fiveyeartotal1;
by hud_inc /*tenure*/;
var HHincome_a owncost_a rentgrs_a;
output out= incomecategories mean=;
run;

/*calibrate ipums to 2015 population projection*/ 
proc sort data= fiveyeartotal1;
by geoid;
run;
proc summary data=fiveyeartotal1;
by geoid;
var totalpop;
weight hhwt;
output out=geo_sum sum=ACS_13_17;
run; 
proc sort data= projectedHH;
by geoid;
run;

data calculate_calibration;
merge geo_sum(in=a) projectedHH;
by geoid;
if a;
calibration=(hh2015/ACS_13_17);
run;

data fiveyeartotal_c;
merge fiveyeartotal1 calculate_calibration;
by geoid;

hhwt_geo=.; 

hhwt_geo=hhwt*calibration*0.2; 

label hhwt_geo="Household Weight Calibrated to Steven Estimates for Households"
	  calibration="Ratio of Steven 2015 estimate to ACS 2013-17 for 45 geographic units";

run; 

data fiveyeartotal;
set fiveyeartotal_c;
if hhincome_a in ( 9999999, .n ) then inc = .n;
  else do;
 /*hard code income categories to match the projections, since the calibrated distributino might be slightly different than the original one*/
		if hhincome_a < 20728.563641 then inc=1;
		if 20728.563641  =< hhincome_a < 39142.262306 then inc=2;
		if 39142.262306  =< hhincome_a < 62051.245269 then inc=3;
		if 62051.245269  =< hhincome_a < 100000 then inc=4;
		if 100000  =< hhincome_a =< 1570000 then inc=5;
  end;
	    label /*hud_inc = 'HUD Income Limits category for household (2016)'*/
	    inc='Income quintiles statewide not account for HH size';
		format inc inc_cat.; 
		hhwt_ori= hhwt*0.2;
run;

/*export dataset*/
 data NCHsg.fiveyeartotal_alt(label= "NC households 13-17 pooled alternative file"); 
   set fiveyeartotal;
 run;

 proc contents data= fiveyeartotal;
 run;

proc tabulate data=fiveyeartotal format=comma12. noseps missing;
  class county2_char;
  var hhwt_ori hhwt_geo;
  table
    all='Total' county2_char=' ',
    sum='Sum of HHWTs' * ( hhwt_geo='Adjusted to 2015 estimates' hhwt_ori= 'Original 5-year'  )
  / box='Occupied housing units';
  *format county2_char county2_char.;
run;

data fiveyeartotal_vacant;
	set Housing_needs_vacant_2013 Housing_needs_vacant_2014 Housing_needs_vacant_2015 Housing_needs_vacant_2016 Housing_needs_vacant_2017;
totalpop=0.2;
merge=1;
*totpop_wt= totalpop*AFACT2; 
geoid=.;
if county2_char= "0100" then geoid=1;
else if  county2_char= "0200" then geoid=2;
else if  county2_char= "0300" then geoid=3;
else if  county2_char= "0400" then geoid=4;
else if  county2_char= "0500 or 0600" then geoid=5;
else if  county2_char= "0700" then geoid=6;
else if  county2_char= "0800" then geoid=7;
else if  county2_char= "0900" then geoid=8;
else if  county2_char= "1000" then geoid=9;
else if  county2_char= "1100" then geoid=10;
else if  county2_char= "1201 to 1208" then geoid=11;
else if  county2_char= "1301 to 1302" then geoid=12;
else if  county2_char= "1400" then geoid=13;
else if  county2_char= "1500" then geoid=14;
else if  county2_char= "1600" then geoid=15;
else if  county2_char= "1701 to 1704" then geoid=16;
else if  county2_char= "1801 to 1803" then geoid=17;
else if  county2_char= "1900 or 2900" then geoid=18;
else if  county2_char= "2000" then geoid=19;
else if  county2_char= "2100" then geoid=20;
else if  county2_char= "2201 to 2202" then geoid=21;
else if  county2_char= "2300 or 2400" then geoid=22;
else if  county2_char= "2500" then geoid=23;
else if  county2_char= "2600 or 2700" then geoid=24;
else if  county2_char= "2800" then geoid=25;
else if  county2_char= "3001 to 3003" then geoid=26;
else if  county2_char= "3101 to 3108" then geoid=27;
else if  county2_char= "3200 or 3300" then geoid=28;
else if  county2_char= "3400" then geoid=29;
else if  county2_char= "3500" then geoid=30;
else if  county2_char= "3600" then geoid=31;
else if  county2_char= "3700" then geoid=32;
else if  county2_char= "3800" then geoid=33;
else if  county2_char= "3900" then geoid=34;
else if  county2_char= "4000" then geoid=35;
else if  county2_char= "4100 or 4500" then geoid=36;
else if  county2_char= "4200" then geoid=37;
else if  county2_char= "4300" then geoid=38;
else if  county2_char= "4400" then geoid=39;
else if  county2_char= "4600 or 4700" then geoid=40;
else if  county2_char= "4800" then geoid=41;
else if  county2_char= "4900 or 5100" then geoid=42;
else if  county2_char= "5001 to 5003" then geoid=43;
else if  county2_char= "5200" then geoid=44;
else if  county2_char= "5300 or 5400" then geoid=45;
run;

proc sort data=fiveyeartotal_vacant;
by geoid;
run;

data fiveyeartotal_vacant_c;
merge fiveyeartotal_vacant calculate_calibration;
by geoid;

hhwt_geo=.; 

hhwt_geo=hhwt*calibration*0.2; 
hhwt_ori= hhwt*0.2;
label hhwt_geo="Household Weight Calibrated to Steven Estimates for Households"
	  calibration="Ratio of Steven 2015 estimate to ACS 2013-17 for 45 geographic units";

run; 

/*export dataset*/
 data NCHsg.fiveyeartotal_vacant_alt(label= "NC vacant units 13-17 pooled alternative file"); 
   set fiveyeartotal_vacant_c;
 run;

 proc contents data= fiveyeartotal_vacant_c; run;

proc tabulate data=fiveyeartotal_vacant_c format=comma12. noseps missing;
  class county2_char;
  var hhwt_geo hhwt_ori;
  table
    all='Total' county2_char=' ',
    sum='Sum of HHWTs' * ( hhwt_geo='Adjusted to 2015 estimates' hhwt_ori= 'Original 5-year')
  / box='Vacant (nonseasonal) housing units';
  *format county2_char county2_char.;
run;

/*need to account for other vacant units in baseline and future targets for the region to complete picture of the total housing stock*/

data fiveyeartotal_othervacant;
   set other_vacant_2013 other_vacant_2014 other_vacant_2015 other_vacant_2016 other_vacant_2017;
totalpop=0.2;
merge=1;
*totpop_wt= totalpop*AFACT2; 
geoid=.;
if county2_char= "0100" then geoid=1;
else if  county2_char= "0200" then geoid=2;
else if  county2_char= "0300" then geoid=3;
else if  county2_char= "0400" then geoid=4;
else if  county2_char= "0500 or 0600" then geoid=5;
else if  county2_char= "0700" then geoid=6;
else if  county2_char= "0800" then geoid=7;
else if  county2_char= "0900" then geoid=8;
else if  county2_char= "1000" then geoid=9;
else if  county2_char= "1100" then geoid=10;
else if  county2_char= "1201 to 1208" then geoid=11;
else if  county2_char= "1301 to 1302" then geoid=12;
else if  county2_char= "1400" then geoid=13;
else if  county2_char= "1500" then geoid=14;
else if  county2_char= "1600" then geoid=15;
else if  county2_char= "1701 to 1704" then geoid=16;
else if  county2_char= "1801 to 1803" then geoid=17;
else if  county2_char= "1900 or 2900" then geoid=18;
else if  county2_char= "2000" then geoid=19;
else if  county2_char= "2100" then geoid=20;
else if  county2_char= "2201 to 2202" then geoid=21;
else if  county2_char= "2300 or 2400" then geoid=22;
else if  county2_char= "2500" then geoid=23;
else if  county2_char= "2600 or 2700" then geoid=24;
else if  county2_char= "2800" then geoid=25;
else if  county2_char= "3001 to 3003" then geoid=26;
else if  county2_char= "3101 to 3108" then geoid=27;
else if  county2_char= "3200 or 3300" then geoid=28;
else if  county2_char= "3400" then geoid=29;
else if  county2_char= "3500" then geoid=30;
else if  county2_char= "3600" then geoid=31;
else if  county2_char= "3700" then geoid=32;
else if  county2_char= "3800" then geoid=33;
else if  county2_char= "3900" then geoid=34;
else if  county2_char= "4000" then geoid=35;
else if  county2_char= "4100 or 4500" then geoid=36;
else if  county2_char= "4200" then geoid=37;
else if  county2_char= "4300" then geoid=38;
else if  county2_char= "4400" then geoid=39;
else if  county2_char= "4600 or 4700" then geoid=40;
else if  county2_char= "4800" then geoid=41;
else if  county2_char= "4900 or 5100" then geoid=42;
else if  county2_char= "5001 to 5003" then geoid=43;
else if  county2_char= "5200" then geoid=44;
else if  county2_char= "5300 or 5400" then geoid=45;

run;

proc sort data= fiveyeartotal_othervacant;
by geoid;
run;

data fiveyeartotal_othervacant_c;
merge fiveyeartotal_othervacant calculate_calibration;
by geoid;

hhwt_geo=.; 

hhwt_geo=hhwt*calibration*0.2; 
hhwt_ori= hhwt*0.2;
label hhwt_geo="Household Weight Calibrated to Steven Estimates for Households"
	  calibration="Ratio of Steven 2015 estimate to ACS 2013-17 for 45 geographic units";

run; 

/*export dataset*/
 data NCHsg.fiveyeartotal_othervacant_alt(label= "NC other vacant units 13-17 pooled alternative file"); 
   set fiveyeartotal_othervacant_c;
 run;

 proc contents data= fiveyeartotal_othervacant_c; run;

proc tabulate data=fiveyeartotal_othervacant_c format=comma12. noseps missing;
  class county2_char;
  var hhwt_geo hhwt_ori;
  table
    all='Total' county2_char=' ',
    sum='Sum of HHWTs' * (hhwt_geo='Adjusted to 2015 estimates' hhwt_ori= 'Original 5-year')
  / box='Seasonal vacant housing units';
  *format county2_char county2_char.;
run;

proc freq data=fiveyeartotal_othervacant_c;
by county2_char;
tables vacancy /nopercent norow nocol out=other_vacant;
weight hhwt_geo;
*format county2_char county2_char.;
run; 


