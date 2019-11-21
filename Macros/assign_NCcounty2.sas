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
      county2 =1900;  
	when ("37025") 
      county2 =3300;  
	when ("37159") 
      county2 =37159;  
	when ("37057") 
      county2 =37057;  
	when ("37151") 
      county2 =37151;  
	when ("37085") 
      county2 =37085;  
	when ("37191") 
      county2 =37191;  
	when ("37147") 
      county2 =37147;  
	when ("37049") 
      county2 =37049;  
	when ("37133") 
      county2 =4100;  
	when ("37129") 
      county2 =4600;  
	when ("37019") 
      county2 =37019;  
	when ("37155") 
      county2 =4900;  
	when ("37179") 
      county2 =5300;  

    otherwise
        ;
  end;

  /*28 PUMAs that contain multiple counties 
    will be created in assign_NCcounty3 */
 
%mend assign_NCcounty2;
