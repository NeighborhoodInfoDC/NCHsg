/**************************************************************************
 Program:  assign_NCcounty.sas
 Library:  NCHsg
 Project:  NCHsg
 Author:   YIPENG SU
 Created:  7/18/2019
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 
 Description: Assign county based on 2010 PUMAS for ACS IPUMS data for the North Carolina region:

 Crosswalk between PUMA and crosswalk are specific to the project, county is for merging in income limit 
 and county2 is the geography category that the projection is in. (county level summary in most cases),
 spreadsheet in NCHsg/Raw/PUMA county crosswalk

 Modifications: YS modified the origial program in Reghsg 7/16/19
**************************************************************************/

%macro assign_NCcounty;

  select ( upuma );
  /*one county= one PUMA*/
    when ("3701600") 
      county =37001;
    when ("3704800") 
      county =37019;
    when ("3702800") 
      county =37035;
    when ("3704300") 
      county =37049;
    when ("3703500") 
      county =37057;
    when ("3703800") 
      county =37085;
    when ("3701100") 
      county =37101;
    when ("3701400") 
      county =37135;
    when ("3704200") 
      county =37147; 
    when ("3703600") 
      county =37151; 
	when ("3703400") 
      county =37159; 
	when ("3704000") 
      county =37191;    

 /*one PUMA contains several counties */
	when ("3700100") 
      county = 37189;  
	when ("3700200") 
      county = 37171;  
	when ("3700300") 
      county = 37157;  
	when ("3700400") 
      county = 37145;  
	when ("3700500") 
      county = 37069;  
	when ("3700600") 
      county = 37083;  
	when ("3700700") 
      county =37139;  
	when ("3700800") 
      county =37055;  
	when ("3700900") 
      county =37127;  
	when ("3701000") 
      county =37195;  
	when ("3701500") 
      county =37037;  
	when ("3701900") 
      county =37059;  
	when ("3702000") 
      county =37027;  
	when ("3702100") 
      county =37023;  
	when ("3702300") 
      county =37115;  
	when ("3702400") 
      county =37113;  
	when ("3702500") 
      county =37089;  
	when ("3702600") 
      county =37161;  
	when ("3702700") 
      county =37109;  
	when ("3703300") 
      county =37167;  
	when ("3703700") 
      county =37123;  
	when ("3703900") 
      county =37163;  
	when ("3704100") 
      county =37107;  
	when ("3704400") 
      county =37031;  
	when ("3704600") 
      county =37141;  
	when ("3704900") 
      county =37047;  
	when ("3705200") 
      county =37093;  
	when ("3705300") 
      county =37007;  
	

/*one county contains/overlaps with several PUMAs */
	when ( in ("37002201","3702202" ) 
      county =37021;  
	
	when ("3703200") 
      county =37025;  

	when  ("3705001","3705001","3705003" ) 
      county =37051;  

	when  ("3701301","3701302" ) 
      county =37063;  

	when ("3701801","3701802","3701803" ) 
      county =37067;  

	when ("3703001","3703002" ) 
      county =37071;  


	when ("3701701","3701702" ) 
      county =37081;  

	when ("3702900") 
      county =37097;  

	when ("3703101","3703102","3703103","3703104","3703105", "3703106","3703107","3703108","3704700")
      county =37119;  


	when ("3704500") 
      county =37133;  

	when ("3705100") 
      county =37155;  

	when ("3705400") 
      county =37179;  

	when ("3701201","3701202" ,"3701203","3701204","3701205","3701206","3701207") 
      county =37183;  

    otherwise
        ;
  end;
 
%mend assign_NCcounty;

