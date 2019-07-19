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
    when ("1600") 
      county =37001;
    when ("4800") 
      county =37019;
    when ("2800") 
      county =37035;
    when ("4300") 
      county =37049;
    when ("3500") 
      county =37057;
    when ("3800") 
      county =37085;
    when ("1100") 
      county =37101;
    when ("1400") 
      county =37135;
    when ("4200") 
      county =37147; 
    when ("3600") 
      county =37151; 
	when ("3400") 
      county =37159; 
	when ("4000") 
      county =37191;    

 /*one PUMA contains several counties */
	when ("100") 
      county = 37189;  
	when ("200") 
      county = 37171;  
	when ("300") 
      county = 37157;  
	when ("400") 
      county = 37145;  
	when ("500") 
      county = 37069;  
	when ("600") 
      county = 37083;  
	when ("700") 
      county =37139;  
	when ("800") 
      county =37055;  
	when ("900") 
      county =37127;  
	when ("1000") 
      county =37195;  
	when ("1500") 
      county =37037;  
	when ("1900") 
      county =37059;  
	when ("2000") 
      county =37027;  
	when ("2100") 
      county =37023;  
	when ("2300") 
      county =37115;  
	when ("2400") 
      county =37113;  
	when ("2500") 
      county =37089;  
	when ("2600") 
      county =37161;  
	when ("2700") 
      county =37109;  
	when ("3300") 
      county =37167;  
	when ("3700") 
      county =37123;  
	when ("3900") 
      county =37163;  
	when ("4100") 
      county =37107;  
	when ("4400") 
      county =37031;  
	when ("4600") 
      county =37141;  
	when ("4900") 
      county =37047;  
	when ("5200") 
      county =37093;  
	when ("5300") 
      county =37007;  
	

/*one county contains/overlaps with several PUMAs */
	when ( in ("2201","2202" ) )
      county2 =37021;  
	
	when ("3200") 
      county2 =37025;  

	when ( in ("5001","5001","5003" ) )
      county2 =37051;  

	when ( in ("1301","1302" ) )
      county2 =37063;  

	when ( in ("1801","1802","1803" ) )
      county2 =37067;  

	when ( in ("3001","3002" ) )
      county2 =37071;  


	when ( in ("1701","1702" ) )
      county2 =37081;  

	when ("2900") 
      county2 =37097;  

	when ( in ("3101","3102","3103","3104","3105", "3106","3107","3108","4700") )
      county2 =37119;  


	when ("4500") 
      county2 =37133;  

	when ("5100") 
      county2 =37155;  

	when ("5400") 
      county2 =37179;  

	when ( in ("1201","1202" ,"1203","1204","1205","1206","1207") )
      county2 =37183;  

    otherwise
        ;
  end;
 
%mend assign_NCcounty;



%macro assign_NCcounty2;

  select ( upuma );
  /*one county= one PUMA green in spreadsheet*/
    when ("1600") 
      county =37001;
    when ("4800") 
      county =37019;
    when ("2800") 
      county =37035;
    when ("4300") 
      county =37049;
    when ("3500") 
      county =37057;
    when ("3800") 
      county =37085;
    when ("1100") 
      county =37101;
    when ("1400") 
      county =37135;
    when ("4200") 
      county =37147; 
    when ("3600") 
      county =37151; 
	when ("3400") 
      county =37159; 
	when ("4000") 
      county =37191;    

 /*one PUMA contains several counties */
	when ("100") 
      county2 =100;  
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
	

/*one county contains/overlaps with several PUMAs, blue in spreadsheet */

	when ( in ("2201","2202" ) )
      county2 =37021;  
	
	when ("3200") 
      county2 =37025;  

	when ( in ("5001","5001","5003" ) )
      county2 =37051;  

	when ( in ("1301","1302" ) )
      county2 =37063;  

	when ( in ("1801","1802","1803" ) )
      county2 =37067;  

	when ( in ("3001","3002" ) )
      county2 =37071;  


	when ( in ("1701","1702" ) )
      county2 =37081;  

	when ("2900") 
      county2 =37097;  

	when ( in ("3101","3102","3103","3104","3105", "3106","3107","3108","4700") )
      county2 =37119;  


	when ("4500") 
      county2 =37133;  

	when ("5100") 
      county2 =37155;  

	when ("5400") 
      county2 =37179;  

	when ( in ("1201","1202" ,"1203","1204","1205","1206","1207") )
      county2 =37183;  

    otherwise
        ;
  end;
 
%mend assign_NCcounty2;
