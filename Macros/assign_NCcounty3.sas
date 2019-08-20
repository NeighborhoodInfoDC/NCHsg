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

%macro assign_NCcounty3;

  /*8 counties that contain multiple PUMAs*/
  /*select ( county_char );

    when ("37183") 
      county2 = 37183;
    when ("37063") 
      county2 =37063;
    when ("37081") 
      county2 =37081;
    when ("37067") 
      county2 =37067;
    when ("37021") 
      county2 =37021;
    when ("37071") 
      county2 =37071;
    when ("37119") 
      county2 =37119;
    when ("37051") 
      county2 =37051;
*/
 /*18 counties that contain a single PUMA */
	/*when ("37101") 
      county2 =37101;  
	when ("37135") 
      county2 =37135;  
	when ("37001") 
      county2 =37001;  
	when ("37035") 
      county2 =37035;  
	when ("37097") 
      county2 =37097;  
	when ("37025") 
      county2 =37025;  
	when ("37159") 
      county2 =37159;  
	when ("37057") 
      county2 =37057;  
	when ("37151") 
      county2 =37151;  
	when ("37850") 
      county2 =37085;  
	when ("37191") 
      county2 =37191;  
	when ("37147") 
      county2 =37147;  
	when ("37049") 
      county2 =37049;  
	when ("37133") 
      county2 =37133;  
	when ("37129") 
      county2 =37129;  
	when ("37019") 
      county2 =37019;  
	when ("37155") 
      county2 =37155;  
	when ("37179") 
      county2 =37179;  

    otherwise
        ;
  end;
*/
  /*28 PUMAs that contain multiple counties */

  select ( upuma );

  when ("3700100") 
      county2 = 100;
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

    otherwise
        ;
  end;

 
%mend assign_NCcounty3;
