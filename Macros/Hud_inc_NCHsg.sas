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
          if &hhinc. <= I30_1 then hud_inc = 1;
          else if I30_1 < &hhinc. <= I50_1 then hud_inc = 2;
          else if I50_1 < &hhinc. <= I80_1 then hud_inc = 3;
          else if I80_1 < &hhinc. <= I80_1* 1.5 then hud_inc = 4;
          else if I80_1* 1.5 < &hhinc. <= I80_1* 2.5 then hud_inc = 5;
		  else if I80_1* 2.5 <&hhinc.  then hud_inc=6;
        end;
      when ( 2 )
        do;
          if &hhinc. <= I30_2 then hud_inc = 1;
          else if I30_2 < &hhinc. <= I50_2 then hud_inc = 2;
          else if I50_2 < &hhinc. <= I80_2 then hud_inc = 3;
          else if I80_2 < &hhinc. <= I80_2* 1.5 then hud_inc = 4;
          else if I80_2* 1.5 < &hhinc. <= I80_2* 2.5 then hud_inc = 5;
		  else if I80_2* 2.5 <&hhinc.  then hud_inc=6;
        end;
      when ( 3 )
        do;
          if &hhinc. <= I30_3 then hud_inc = 1;
          else if I30_3 < &hhinc. <= I50_3 then hud_inc = 2;
          else if I50_3 < &hhinc. <= I80_3 then hud_inc = 3;
          else if I80_3 < &hhinc. <= I80_3* 1.5 then hud_inc = 4;
          else if I80_3* 1.5 < &hhinc. <= I80_3* 2.5 then hud_inc = 5;
		  else if I80_3* 2.5 <&hhinc.  then hud_inc=6;
        end;
      when ( 4 )
        do;
          if &hhinc. <= I30_4 then hud_inc = 1;
          else if I30_4 < &hhinc. <= I50_4 then hud_inc = 2;
          else if I50_4 < &hhinc. <= I80_4 then hud_inc = 3;
          else if I80_4 < &hhinc. <= I80_4* 1.5 then hud_inc = 4;
          else if I80_4* 1.5 < &hhinc. <= I80_4* 2.5 then hud_inc = 5;
		  else if I80_4* 2.5 <&hhinc.  then hud_inc=6;
        end;
      when ( 5 )
        do;
          if &hhinc. <= I30_5 then hud_inc = 1;
          else if I30_5 < &hhinc. <= I50_5 then hud_inc = 2;
          else if I50_5 < &hhinc. <= I80_5 then hud_inc = 3;
          else if I80_5 < &hhinc. <= I80_5* 1.5 then hud_inc = 4;
          else if I80_5* 1.5 < &hhinc. <= I80_5* 2.5 then hud_inc = 5;
		  else if I80_5* 2.5 <&hhinc.  then hud_inc=6;
        end;
      when ( 6 )
        do;
          if &hhinc. <= I30_6 then hud_inc = 1;
          else if I30_6 < &hhinc. <= I50_6 then hud_inc = 2;
          else if I50_6 < &hhinc. <= I80_6 then hud_inc = 3;
          else if I80_6 < &hhinc. <= I80_6* 1.5 then hud_inc = 4;
          else if I80_6* 1.5 < &hhinc. <= I80_6* 2.5 then hud_inc = 5;
		  else if I80_6* 2.5 <&hhinc.  then hud_inc=6;
        end;
      when ( 7 )
        do;
          if &hhinc. <= I30_7 then hud_inc = 1;
          else if I30_7 < &hhinc. <= I50_7 then hud_inc = 2;
          else if I50_7 < &hhinc. <= I80_7 then hud_inc = 3;
          else if I80_7 < &hhinc. <= I80_7* 1.5 then hud_inc = 4;
          else if I80_7* 1.5 < &hhinc. <= I80_7* 2.5 then hud_inc = 5;
		  else if I80_7* 2.5 <&hhinc.  then hud_inc=6;
        end;
      otherwise
        do;
          if &hhinc. <= I30_8 then hud_inc = 1;
          else if I30_8 < &hhinc. <= I50_8 then hud_inc = 2;
          else if I50_8 < &hhinc. <= I80_8 then hud_inc = 3;
          else if I80_8 < &hhinc. <= I80_8* 1.5 then hud_inc = 4;
          else if I80_8* 1.5 < &hhinc. <= I80_8* 2.5 then hud_inc = 5;
		  else if I80_8* 2.5 <&hhinc.  then hud_inc=6;
        end;
    end;

  end;

  label hud_inc = "HUD income categories";
  
%mend Hud_inc_NCHsg;

/** End Macro Definition **/





