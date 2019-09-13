/**************************************************************************
 Program:  assign_NCcounty2.sas
 Library:  NCHsg
 Project:  NCHsg
 Author:   YIPENG SU
 Created:  7/18/2019
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 
 Description: Assign county based on 2010 PUMAS for ACS IPUMS data for the North Carolina region:

 Crosswalk between PUMA and crosswalk are specific to the project, assign_NCcounty3 assigns geography to 
 PUMAs that contains multiple counties

 Modifications: YS modified the origial program in Reghsg 7/16/19
**************************************************************************/

%macro assign_NCcounty3;

  /*8 counties that contain multiple PUMAs*/
 /*18 counties that contain a single PUMA */
/*were created in assign_NCcounty2*/
	
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
