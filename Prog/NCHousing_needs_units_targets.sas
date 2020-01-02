/**************************************************************************
 Program:  NCHousing_needs_units_targets.sas
 Library:  NCHsg
 Project:  NC housing
 Author:   YS adapted from L. Hendey
 Created:  12/07/2019
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

 COG region defined as:
 DC (11001)
 Charles County(24017)
 Frederick County(24021)
 Montgomery County (24031)
 Prince George's County(24033)
 Arlington County (51013)
 Fairfax County (51059)
 Loudoun County (51107)
 Prince William County (51153)
 Alexandria City (51510)
 Fairfax City (51600)
 Falls Church City (51610)
 Manassas City (51683)
 Manassas Park City (51685)

 Modifications: 02-12-19 LH Adjust weights using Calibration from Steven's projections 
						 	so that occupied units match COG 2015 HH estimation.
                02-17-19 LH Readjust weights after changes to calibration to move 2 HH w/ GQ=5 out of head of HH
				03-30-19 LH Remove hard coding and merge in contract rent to gross rent ratio for vacant units. 
				04-26-19 LH Change halfway from 30% of income to max_rent or max_ocost.
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( NCHsg )
%DCData_lib( Ipums )

%let date=12312019; 

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

data NC17_limits;
	set NCHsg.NC17_limits;
run;

proc sort data= NC17_limits;
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


	data NCarea_&year._1 ;
	set Ipums.Acs_&year._NC ;
	run;

	proc sort data= NCarea_&year._1;
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




data Housing_needs_baseline_&year._1;

  set NCarea_&year.
        (keep=year serial pernum MET2013 hhwt hhincome numprec UNITSSTR BUILTYR2 bedrooms gq ownershp owncost ownershpd rentgrs valueh county2_char
         where=(pernum=1 and gq in (1,2) and ownershpd in ( 12,13,21,22 )));

		 *adjust all incomes to 2017 $ to match use of 2017 family of 4 income limit in projections (originally based on use of most recent 5-year IPUMS; 
	MID= put(MET2013, 5.);

	if MET2013= 0 then do;
	MID="99999";
	end;

run;

proc sort data= Housing_needs_baseline_&year._1;
by MID;
run;

data Housing_needs_baseline_&year._2;
merge Housing_needs_baseline_&year._1(in=a) NC17_limits;
if a;
by MID;
run;

data Housing_needs_baseline_&year.;
set Housing_needs_baseline_&year._2;
	  if hhincome ~=.n or hhincome ~=9999999 then do; 
		 %dollar_convert( hhincome, hhincome_a, &year., 2017, series=CUUR0000SA0 )
	   end; 

	*create HUD_inc - uses 2017 limits but has categories for 120-200% and 200%+ AMI; 

  %Hud_inc_NCState( hhinc=hhincome_a, hhsize=numprec )  

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
	  if hud_inc =4 then max_rent=HHINCOME_a/12*.25; *avg for all HH hud_inc=4; 
	  if costratio <=.18 and hud_inc = 5 then max_rent=HHINCOME_a/12*.18; *avg for all HH hud_inc=5; 	
		else if hud_inc = 5 then max_rent=HHINCOME_a/12*costratio; *allow 120-200% above average to spend more; 
	  if costratio <=.12 and hud_inc = 6 then max_rent=HHINCOME_a/12*.12; *avg for all HH hud_inc=6; 
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
			if 0 <=rentgrs_a<750 then rentlevel=1;
			if 750 <=rentgrs_a<1200 then rentlevel=2;
			if 1200 <=rentgrs_a<1500 then rentlevel=3;
			if 1500 <=rentgrs_a<2000 then rentlevel=4;
			if 2000 <=rentgrs_a<2500 then rentlevel=5;
			if rentgrs_a >= 2500 then rentlevel=6;

			mrentlevel=.;
			if max_rent<750 then mrentlevel=1;
			if 750 <=max_rent<1200 then mrentlevel=2;
			if 1200 <=max_rent<1500 then mrentlevel=3;
			if 1500 <=max_rent<2000 then mrentlevel=4;
			if 2000 <=max_rent<2500 then mrentlevel=5;
			if max_rent >= 2500 then mrentlevel=6;

		 *rent cost categories now used in targets that provide a set of categories useable for renters and owners combined; 
			/*need to discuss for NC*/
			allcostlevel=.;
			if rentgrs_a<800 then allcostlevel=1;
			if 800 <=rentgrs_a<1300 then allcostlevel=2;
			if 1300 <=rentgrs_a<1800 then allcostlevel=3;
			if 1800 <=rentgrs_a<2500 then allcostlevel=4;
			if 2500 <=rentgrs_a<3500 then allcostlevel=5;
			if rentgrs_a >= 3500 then allcostlevel=6; 

			mallcostlevel=.;

			*for desired cost for current housing needs is current payment if not cost-burdened
			or income-based payment if cost-burdened;

			if costburden=1 then do; 

				if max_rent<800 then mallcostlevel=1;
				if 800 <=max_rent<1300 then mallcostlevel=2;
				if 1300 <=max_rent<1800 then mallcostlevel=3;
				if 1800 <=max_rent<2500 then mallcostlevel=4;
				if 2500 <=max_rent<3500 then mallcostlevel=5;
				if max_rent >= 3500 then mallcostlevel=6;

			end; 

			else if costburden=0 then do;

				if rentgrs_a<800 then mallcostlevel=1;
				if 800 <=rentgrs_a<1300 then mallcostlevel=2;
				if 1300 <=rentgrs_a<1800 then mallcostlevel=3;
				if 1800 <=rentgrs_a<2500 then mallcostlevel=4;
				if 2500 <=rentgrs_a<3500 then mallcostlevel=5;
				if rentgrs_a >= 3500 then mallcostlevel=6;

			end; 


	end;

	
	  		
		
  	else if ownershpd in ( 12,13 ) then do;

	    ****** Owner units ******;
	    
	    Tenure = 2;

		*create maximum desired or affordable owner costs based on HUD_Inc categories*; 

		/*need to discuss for NC*/
		if hud_inc in(1 2 3) then max_ocost=HHINCOME_a/12*.3; *under 80% of AMI then pay 30% threshold; 
		if hud_inc =4 then max_ocost=HHINCOME_a/12*.25; *avg for all HH hud_inc=4;
		if costratio <=.18 and hud_inc = 5 then max_ocost=HHINCOME_a/12*.18; *avg for all HH HUD_inc=5; 
			else if hud_inc = 5 then max_ocost=HHINCOME_a/12*costratio; *allow 120-200% above average to pay more; 
		if costratio <=.12 and hud_inc=6 then max_ocost=HHINCOME_a/12*.12; *avg for all HH HUD_inc=6;
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
			if 0 <=total_month<1200 then ownlevel=1;
			if 1200 <=total_month<1800 then ownlevel=2;
			if 1800 <=total_month<2500 then ownlevel=3;
			if 2500 <=total_month<3200 then ownlevel=4;
			if 3200 <=total_month<4200 then ownlevel=5;
			if total_month >= 4200 then ownlevel=6;

		mownlevel=.;
			if max_ocost<1200 then mownlevel=1;
			if 1200 <=max_ocost<1800 then mownlevel=2;
			if 1800 <=max_ocost<2500 then mownlevel=3;
			if 2500 <=max_ocost<3200 then mownlevel=4;
			if 3200 <=max_ocost<4200 then mownlevel=5;
			if max_ocost >= 4200 then mownlevel=6;

        *Leah: this is where it differs from the other program
		 		 *owner cost categories now used in targets that provide a set of categories useable for renters and owners combined; 
			allcostlevel=.;
			if total_month<800 then allcostlevel=1;
			if 800 <=total_month<1300 then allcostlevel=2;
			if 1300 <=total_month<1800 then allcostlevel=3;
			if 1800 <=total_month<2500 then allcostlevel=4;
			if 2500 <=total_month<3500 then allcostlevel=5;
			if total_month >= 3500 then allcostlevel=6; 

				mallcostlevel=.;
			if max_ocost<800 then mallcostlevel=1;
			if 800 <=max_ocost<1300 then mallcostlevel=2;
			if 1300 <=max_ocost<1800 then mallcostlevel=3;
			if 1800 <=max_ocost<2500 then mallcostlevel=4;
			if 2500 <=max_ocost<3500 then mallcostlevel=5;
			if max_ocost >= 3500 then mallcostlevel=6;

  end;

  *add structure of housing variable;
  if UNITSSTR = 00 then structure=5;
if UNITSSTR in (01, 02) then structure=4;
if UNITSSTR in (03, 04) then structure=1;
if UNITSSTR in (05, 06, 07) then structure=2;
if UNITSSTR in (08, 09, 10) then structure=3;
	
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
				  allcostlevel='Housing Cost Categories (tenure combined) based on Current Rent or First-time Buyer Mtg'
				  mallcostlevel='Housing Cost Categories (tenure combined) based on Max affordable-desired Rent-Buyer Mtg'
				  ownlevel = 'Owner Cost Categories based on First-Time HomeBuyer Costs'
				  mownlevel = 'Owner Cost Categories based on Max affordable-desired First-Time HomeBuyer Costs'
              	 structure = 'Housing structure type'
				 structureyear = 'Age of structure'

				;
	
format mownlevel ownlevel ocost. rentlevel mrentlevel rcost. allcostlevel mallcostlevel acost. hud_inc hud_inc. structure structure.; 
run;

data Housing_needs_vacant_&year. Other_vacant_&year. ;

  set NCvacant_&year.(keep=year serial hhwt bedrooms gq vacancy rent valueh county2_char UNITSSTR BUILTYR2);

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
		    if rentgrs_a<750 then affordable_vacant=1;
			else if rentgrs_a>=750 then affordable_vacant=0;

		end;

	  label affordable_vacant = 'Natural affordable vacant rental unit';

		/*create rent level categories*/ 
			/*need to discuss for NC*/
		rentlevel=.;
		if 0 <=rentgrs_a<750 then rentlevel=1;
		if 750 <=rentgrs_a<1200 then rentlevel=2;
		if 1200 <=rentgrs_a<1500 then rentlevel=3;
		if 1500 <=rentgrs_a<2000 then rentlevel=4;
		if 2000 <=rentgrs_a<2500 then rentlevel=5;
		if rentgrs_a >= 2500 then rentlevel=6;

		/*create  categories now used in targets for renter/owner costs combined*/ 
				allcostlevel=.;
				if rentgrs_a<800 then allcostlevel=1;
				if 800 <=rentgrs_a<1300 then allcostlevel=2;
				if 1300 <=rentgrs_a<1800 then allcostlevel=3;
				if 1800 <=rentgrs_a<2500 then allcostlevel=4;
				if 2500 <=rentgrs_a<3500 then allcostlevel=5;
				if rentgrs_a >= 3500 then allcostlevel=6;
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
				if 0 <=total_month<1200 then ownlevel=1;
				if 1200 <=total_month<1800 then ownlevel=2;
				if 1800 <=total_month<2500 then ownlevel=3;
				if 2500 <=total_month<3200 then ownlevel=4;
				if 3200 <=total_month<4200 then ownlevel=5;
				if total_month >= 4200 then ownlevel=6;
			
			/*create  categories now used in targets for renter/owner costs combined*/ 
				allcostlevel=.;
				if total_month<800 then allcostlevel=1;
				if 800 <=total_month<1300 then allcostlevel=2;
				if 1300 <=total_month<1800 then allcostlevel=3;
				if 1800 <=total_month<2500 then allcostlevel=4;
				if 2500 <=total_month<3500 then allcostlevel=5;
				if total_month >= 3500 then allcostlevel=6; 


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
	else if vacancy in (4, 7, 9) then output Other_vacant_&year.; 
	run;

%mend single_year; 

%single_year(2013);
%single_year(2014);
%single_year(2015); 
%single_year(2016);
%single_year(2017);

/*merge single year data and reweight

revised to match Steven's files in https://urbanorg.app.box.com/file/402454379812 (after changing 2 HH = GQ=5 in 2013
 to non head of HH)
*/
data fiveyeartotal1;
set Housing_needs_baseline_2013_3 Housing_needs_baseline_2014_3 Housing_needs_baseline_2015_3 Housing_needs_baseline_2016_3 Housing_needs_baseline_2017_3;
totalpop=0.2;
merge=1;
totpop_wt= totalpop*AFACT2; 
run;

proc univariate data= fiveyeartotal1;
	var  hhincome_a;
	weight hhwt;
	output out= inc_pooled pctlpre= P_ pctlpts= 10 to 100 by 10 ;
run;  /*by nature of this function, the output dataset is named data1, data2, data3...*/

data inc_pooled2;
set inc_pooled;
merge= 1;
run;

data fiveyeartotal2;
	merge fiveyeartotal1(in=a) inc_pooled2;
	if a;
	by merge ;
run;

data fiveyeartotal;
set fiveyeartotal2;
if hhincome_a in ( 9999999, .n ) then inc = .n;
  else do;
 /*assign income category based on each year's HH income quintile*/
		if hhincome_a < P_20 then inc=1;
		if P_20  =< hhincome_a < P_40 then inc=2;
		if P_40  =< hhincome_a < P_60 then inc=3;
		if P_60  =< hhincome_a < P_80 then inc=4;
		if P_80  =< hhincome_a < P_100 then inc=5;
  end;
	    label /*hud_inc = 'HUD Income Limits category for household (2016)'*/
	    inc='Income quintiles statewide not account for HH size';
		format inc inc_cat.;
hhwt_5=hhwt*.2; 
run;

/*export dataset*/
 data NCHsg.fiveyeartotal; 
   set fiveyeartotal;
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

data fiveyeartotal_vacant;
	set Housing_needs_vacant_2013 Housing_needs_vacant_2014 Housing_needs_vacant_2015 Housing_needs_vacant_2016 Housing_needs_vacant_2017;

hhwt_5=hhwt*.2;
run;
/*export dataset*/
 data NCHsg.fiveyeartotal_vacant; 
   set fiveyeartotal_vacant;
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

/*need to account for other vacant units in baseline and future targets for the region to complete picture of the total housing stock*/
data fiveyeartotal_othervacant;
   set other_vacant_2013 other_vacant_2014 other_vacant_2015 other_vacant_2016 other_vacant_2017;

hhwt_5=hhwt*.2;

run;
/*export dataset*/
 data NCHsg.fiveyeartotal_othervacant; 
   set fiveyeartotal_othervacant;
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

proc freq data=fiveyeartotal_othervacant;
by county2_char;
tables vacancy /nopercent norow nocol out=other_vacant;
weight hhwt_5;
*format county2_char county2_char.;
run; 
proc export data=fiveyeartotal_othervacant
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
	data region (drop=_label_ _name_); 
		set ru (in=a) ro (in=b) rr (in=c);
	
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
