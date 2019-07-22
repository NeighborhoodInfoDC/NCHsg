/**************************************************************************
 Program:  Hud_inc_NCHsg.sas
 Library:  NCHsg
 Project:  NeighborhoodInfo DC
 Author:   Yipeng Su
 Created:  7/18/2019
 Version:  SAS 9.2
 Environment:  Windows
 
 Description:  Autocall macro to calculate HUD income categories for
 IPUMS data, variable HUD_INC.
 
 Values:
 1  =  <=30% AMI (extremely low)
 2  =  31-50% AMI (very low)
 3  =  51-80% AMI (low)
 4  =  81-120% AMI (middle)
 5  =  120-200% AMI (high)
 6  =  >=200% (extremely high)
 -99  =  N/A (income not reported)

 Modifications: Yipeng Su from Hud_inc_2016 for NCHsg project.
**************************************************************************/

/** Macro Hud_inc_RegHsg - Start Definition **/

%macro Hud_inc_NCHsg(hhinc=, hhsize=  );

  ** HUD income categories (<year>) **;

  if &hhinc. in ( 9999999, .n ) then hud_inc = .n;
  else do;

    select ( &hhsize. );
      when ( 1 )
        do; 
          if &hhinc. <= l50_1/1.67 then hud_inc = 1; 
          else if l50_1/1.67 < &hhinc. <= l50_1 then hud_inc = 2;
          else if l50_1 < &hhinc. <= l80_1 then hud_inc = 3;
          else if l80_1 < &hhinc. <= l50_1* 2.4 then hud_inc = 4;
          else if l50_1* 2.4 < &hhinc. <= l50_1* 4 then hud_inc = 5;
		  else if l50_1* 4 < &hhinc.  then hud_inc=6;
        end;
      when ( 2 )
        do;
          if &hhinc. <= l50_2/1.67 then hud_inc = 1;
          else if l50_2/1.67 < &hhinc. <= l50_2 then hud_inc = 2;
          else if l50_2 < &hhinc. <= l80_2 then hud_inc = 3;
          else if l80_2 < &hhinc. <= l50_2* 2.4 then hud_inc = 4;
          else if l50_2* 2.4 < &hhinc. <= l50_2* 4 then hud_inc = 5;
		  else if l50_2* 4 < &hhinc.  then hud_inc=6;
        end;
      when ( 3 )
        do;
          if &hhinc. <= l50_3/1.67 then hud_inc = 1;
          else if l50_3/1.67 < &hhinc. <= l50_3 then hud_inc = 2;
          else if l50_3 < &hhinc. <= l80_3 then hud_inc = 3;
          else if l80_3 < &hhinc. <= l50_3* 2.4 then hud_inc = 4;
          else if l50_3* 2.4 < &hhinc. <= l50_3* 4 then hud_inc = 5;
		  else if l50_3* 4 < &hhinc.  then hud_inc=6;
        end;
      when ( 4 )
        do;
          if &hhinc. <= l50_4/1.67 then hud_inc = 1;
          else if l50_4/1.67 < &hhinc. <= l50_4 then hud_inc = 2;
          else if l50_4 < &hhinc. <= l80_4 then hud_inc = 3;
          else if l80_4 < &hhinc. <= l50_4* 2.4 then hud_inc = 4;
          else if l50_4* 2.4 < &hhinc. <= l50_4* 4 then hud_inc = 5;
		  else if l50_4* 4 <&hhinc.  then hud_inc=6;
        end;
      when ( 5 )
        do;
          if &hhinc. <= l50_5/1.67 then hud_inc = 1;
          else if l50_5/1.67 < &hhinc. <= l50_5 then hud_inc = 2;
          else if l50_5 < &hhinc. <= l80_5 then hud_inc = 3;
          else if l80_5 < &hhinc. <= l50_5* 2.4 then hud_inc = 4;
          else if l50_5* 2.4 < &hhinc. <= l50_5* 4 then hud_inc = 5;
		  else if l50_5* 4 <&hhinc.  then hud_inc=6;
        end;
      when ( 6 )
        do;
          if &hhinc. <= l50_6/1.67 then hud_inc = 1;
          else if l50_6/1.67 < &hhinc. <= l50_6 then hud_inc = 2;
          else if l50_6 < &hhinc. <= l80_6 then hud_inc = 3;
          else if l80_6 < &hhinc. <= l50_6* 2.4 then hud_inc = 4;
          else if l50_6* 2.4 < &hhinc. <= l50_6* 4 then hud_inc = 5;
		  else if l50_6* 4 <&hhinc.  then hud_inc=6;
        end;
      when ( 7 )
        do;
          if &hhinc. <= l50_7/1.67 then hud_inc = 1;
          else if l50_7/1.67 < &hhinc. <= l50_7 then hud_inc = 2;
          else if l50_7 < &hhinc. <= l80_7 then hud_inc = 3;
          else if l80_7 < &hhinc. <= l50_7* 2.4 then hud_inc = 4;
          else if l50_7* 2.4 < &hhinc. <= l50_7* 4 then hud_inc = 5;
		  else if l50_7* 4 <&hhinc.  then hud_inc=6;
        end;
      otherwise
        do;
          if &hhinc. <= l50_8/1.67 then hud_inc = 1;
          else if l50_8/1.67 < &hhinc. <= l50_8 then hud_inc = 2;
          else if l50_8 < &hhinc. <= l80_8 then hud_inc = 3;
          else if l80_8 < &hhinc. <= l50_8* 2.4 then hud_inc = 4;
          else if l50_8* 2.4 < &hhinc. <= l50_8* 4 then hud_inc = 5;
		  else if l50_8* 4 <&hhinc.  then hud_inc=6;
        end; 
    end;

  end;

  label hud_inc = "HUD income categories";
  
%mend Hud_inc_NCHsg;

/** End Macro Definition **/





