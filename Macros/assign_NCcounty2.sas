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

  select ( county_char );
  /*8 counties that contain multiple PUMAs*/
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

 /*18 counties that contain a single PUMA */
	when ("37101") 
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


  select ( upuma );
  /*28 PUMAs that contain multiple counties */
  when ("100") 
      county2 = 100;
    when ("200") 
      county2 =200;
    when ("300") 
      county2 =300;
    when ("400") 
      county2 =400;
    when ("500") 
      county2 =500;
    when ("600") 
      county2 =600;
    when ("700") 
      county2 =700;
    when ("800") 
      county2 =800;
	when ("900") 
      county2 =900;
	when ("1000") 
      county2 =1000;
	when ("1500") 
      county2 =1500;
	when ("1900") 
      county2 =1900;
	when ("2000") 
      county2 =2000;
	when ("2100") 
      county2 =2100;
	when ("2300") 
      county2 =2300;
	when ("2400") 
      county2 =2400;
	when ("2500") 
      county2 =2500;
	when ("2600") 
      county2 =2600;
	when ("2700") 
      county2 =2700;
	when ("3300") 
      county2 =3300;
	when ("3700") 
      county2 =3700;
	when ("3900") 
      county2 =3900;
	when ("4100") 
      county2 =4100;
	when ("4400") 
      county2 =4400;
	when ("4600") 
      county2 =4600;
	when ("4900") 
      county2 =4900;
	when ("5200") 
      county2 =5200;
	when ("5300") 
      county2 =5300;

    otherwise
        ;
  end;

 
%mend assign_NCcounty2;
