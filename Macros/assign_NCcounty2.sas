/**************************************************************************
 Program:  assign_NCcounty2.sas
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

%macro assign_NCcounty2;

  select ( upuma );
  /*one county= one PUMA green in spreadsheet*/
    when ("3701600") 
      county2 =37001;
    when ("3704800") 
      county2 =37019;
    when ("3702800") 
      county2 =37035;
    when ("3704300") 
      county2 =37049;
    when ("3703500") 
      county2 =37057;
    when ("3703800") 
      county2 =37085;
    when ("3701100") 
      county2 =37101;
    when ("3701400") 
      county2 =37135;
    when ("3704200") 
      county2 =37147; 
    when ("3703600") 
      county2 =37151; 
	when ("3703400") 
      county2 =37159; 
	when ("3704000") 
      county2 =37191;    

 /*one PUMA contains several counties, orange in spreadsheet */
	when ("3700100") 
      county2 =100;  
	when ("3700200") 
      county2 =200;  
	when ("3700300") 
      county2 =300;  
	when ("3700400") 
      county2 =400;  
	when ("3700500") 
      county2 =500;  
	when ("3700600") 
      county2 =600;  
	when ("3700700") 
      county2 =700;  
	when ("3700800") 
      county2 =800;  
	when ("3700900") 
      county2 =900;  
	when ("3701000") 
      county2 =1000;  
	when ("3701500") 
      county2 =1500;  
	when ("3701900") 
      county2 =1900;  
	when ("3702000") 
      county2 =2000;  
	when ("3702100") 
      county2 =2100;  
	when ("3702300") 
      county2 =2300;  
	when ("3702400") 
      county2 =2400;  
	when ("3702500") 
      county2 =2500;  
	when ("3702600") 
      county2 =2600;  
	when ("3702700") 
      county2 =2700;  
	when ("3703300") 
      county2 =3300;  
	when ("3703700") 
      county2 =3700;  
	when ("3703900") 
      county2 =3900;  
	when ("3704100") 
      county2 =4100;  
	when ("3704400") 
      county2 =4400;  
	when ("3704600") 
      county2 =4600;  
	when ("3704900") 
      county2 =4900;  
	when ("3705200") 
      county2 =5200;  
	when ("3705300") 
      county2 =5300;  
	
/*one county contains/overlaps with several PUMAs, blue in spreadsheet */

	when ("3702201","3702202" ) 
      county2 =37021;  
	
	when ("3703200") 
      county2 =37025;  

	when  ("3705001","3705002","3705003" ) 
      county2 =37051;  

	when  ("3701301","3701302" ) 
      county2 =37063;  

	when  ("3701801","3701802","3701803" ) 
      county2 =37067;  

	when  ("3703001","3703002" ) 
      county2 =37071;  

	when  ("3701701","3701702", "3701703", "3701704" ) 
      county2 =37081;  

	when ("3702900") 
      county2 =37097;  

	when ("3703101","3703102","3703103","3703104","3703105", "3703106","3703107","3703108") 
      county2 =37119;  

	when ("3704700") 
      county2 =37129;  

	when ("3704500") 
      county2 =37133;  

	when ("3705100") 
      county2 =37155;  

	when ("3705400") 
      county2 =37179;  

	when  ("3701201","3701202" ,"3701203","3701204","3701205","3701206","3701207","3701208") 
      county2 =37183;  

    otherwise
        ;
  end;
 
%mend assign_NCcounty2;
