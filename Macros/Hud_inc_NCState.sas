/**************************************************************************
 Program:  Hud_inc_NCState.sas
 Library:  NCHsg
 Project:  NeighborhoodInfo DC
 Author:   Yipeng Su
 Created:  12/12/2019
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

 Modifications: Yipeng Su from Hud_inc_RegHSG for NCHsg project.
**************************************************************************/

/** Macro Hud_inc_RegHsg - Start Definition **/

%macro Hud_inc_NCState(hhinc=, hhsize=  );

  ** HUD income categories (<year>) **;

  if &hhinc. in ( 9999999, .n ) then hud_inc = .n;
  else do;

        select ( numprec );
      when ( 1 )
        do;
          if hhincome <= 12450 then hud_inc = 1;
          else if 12450 < hhincome <= 20700 then hud_inc = 2;
          else if 20700 < hhincome <= 33150 then hud_inc = 3;
          else if 33150 < hhincome <= 49680 then hud_inc = 4;
          else if 49680 < hhincome then hud_inc = 5;
        end;
      when ( 2 )
        do;
          if hhincome <= 14200 then hud_inc = 1;
          else if 14200 < hhincome <= 23700 then hud_inc = 2;
          else if 23700 < hhincome <= 37900 then hud_inc = 3;
          else if 37900 < hhincome <= 56880 then hud_inc = 4;
          else if 56880 < hhincome then hud_inc = 5;
        end;
      when ( 3 )
        do;
          if hhincome <= 16000 then hud_inc = 1;
          else if 16000 < hhincome <= 26650 then hud_inc = 2;
          else if 26650 < hhincome <= 42600 then hud_inc = 3;
          else if 42600 < hhincome <= 63960 then hud_inc = 4;
          else if 63960 < hhincome then hud_inc = 5;
        end;
      when ( 4 )
        do;
          if hhincome <= 17750 then hud_inc = 1;
          else if 17750 < hhincome <= 29600 then hud_inc = 2;
          else if 29600 < hhincome <= 47350 then hud_inc = 3;
          else if 47350 < hhincome <= 71040 then hud_inc = 4;
          else if 71040 < hhincome then hud_inc = 5;
        end;
      when ( 5 )
        do;
          if hhincome <= 19200 then hud_inc = 1;
          else if 19200 < hhincome <= 31950 then hud_inc = 2;
          else if 31950 < hhincome <= 51150 then hud_inc = 3;
          else if 51150 < hhincome <= 76680 then hud_inc = 4;
          else if 76680 < hhincome then hud_inc = 5;
        end;
      when ( 6 )
        do;
          if hhincome <= 20600 then hud_inc = 1;
          else if 20600 < hhincome <= 34350 then hud_inc = 2;
          else if 34350 < hhincome <= 54950 then hud_inc = 3;
          else if 54950 < hhincome <= 82440 then hud_inc = 4;
          else if 82440 < hhincome then hud_inc = 5;
        end;
      when ( 7 )
        do;
          if hhincome <= 22000 then hud_inc = 1;
          else if 22000 < hhincome <= 36700 then hud_inc = 2;
          else if 36700 < hhincome <= 58750 then hud_inc = 3;
          else if 58750 < hhincome <= 88080 then hud_inc = 4;
          else if 88080 < hhincome then hud_inc = 5;
        end;
      otherwise
        do;
          if hhincome <= 23450 then hud_inc = 1;
          else if 23450 < hhincome <= 39050 then hud_inc = 2;
          else if 39050 < hhincome <= 62500 then hud_inc = 3;
          else if 62500 < hhincome <= 93720 then hud_inc = 4;
          else if 93720 < hhincome then hud_inc = 5;
        end;
    end;

  end;

  label hud_inc = "HUD income categories";
  
%mend Hud_inc_NCState;

/** End Macro Definition **/


