/**************************************************************************
 Program:  assign_NCcounty2.sas
 Library:  NCHsg
 Project:  NCHsg
 Author:   YIPENG SU
 Created:  7/18/2019
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 
 Description: Assign county based on 2010 PUMAS for ACS IPUMS data for the North Carolina region:

 Crosswalk between PUMA and crosswalk are specific to the project, assign_NCcounty2 assigns counties that contain one or multiple PUMAs

 Modifications: YS modified the origial program in Reghsg 7/16/19
**************************************************************************/

%macro assign_NCcounty2;

  select ( county_char );
  /*8 counties that contain multiple PUMAs*/
    when ("37183") 
      county2 = "1201 to 1208";
    when ("37063") 
      county2 ="1301 to 1302";
    when ("37081") 
      county2 ="1701 to 1704";
    when ("37067") 
      county2 ="1801 to 1803";
    when ("37021") 
      county2 ="2201 or 2202";
    when ("37071") 
      county2 ="3001 to 3003";
    when ("37119") 
      county2 ="3101 to 3108";
    when ("37051") 
      county2 ="5001 to 5003";

 /*18 counties that contain a single PUMA */
	when ("37101") 
      county2 ="1100";  
	when ("37135") 
      county2 ="1400";  
	when ("37001") 
      county2 ="1600";  
	when ("37035") 
      county2 ="2800";  
	when ("37097") 
      county2 ="1900 or 2900";  
	when ("37025") 
      county2 ="3200 or 3300";  
	when ("37159") 
      county2 ="3400";  
	when ("37057") 
      county2 ="3500";  
	when ("37151") 
      county2 ="3600";  
	when ("37085") 
      county2 ="3800";  
	when ("37191") 
      county2 ="4000";  
	when ("37147") 
      county2 ="4200";  
	when ("37049") 
      county2 ="4300";  
	when ("37133") 
      county2 ="4100 or 4500" ;  
	when ("37129") 
      county2 ="4600 or 4700";  
	when ("37019") 
      county2 ="4800";  
	when ("37155") 
      county2 ="4900 or 5100";  
	when ("37179") 
      county2 ="5300 or 5400";  

    otherwise
        ;
  end;

 
%mend assign_NCcounty2;
