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
          if hhincome <= ELI_1 then hud_inc = 1;
          else if ELI_1 < hhincome <= l50_1 then hud_inc = 2;
          else if l50_1 < hhincome <= l80_1 then hud_inc = 3;
          else if l80_1 < hhincome <= l50_1*2.4 then hud_inc = 4;
          else if l50_1*2.4 < hhincome <= l50_1*4 then hud_inc = 5;
		  else if l50_1*4 < hhincome then hud_inc = 6;
        end;
      when ( 2 )
        do;
          if hhincome <= ELI_2 then hud_inc = 1;
          else if ELI_2 < hhincome <= l50_2 then hud_inc = 2;
          else if l50_2 < hhincome <= l80_2 then hud_inc = 3;
          else if l80_2 < hhincome <= l50_2*2.4 then hud_inc = 4;
          else if l50_2*2.4 < hhincome<= l50_2*4 then hud_inc = 5;
		  else if l50_2*4 < hhincome then hud_inc = 6;
        end;
      when ( 3 )
        do;
          if hhincome <= ELI_3 then hud_inc = 1;
          else if ELI_3 < hhincome <= l50_3 then hud_inc = 2;
          else if l50_3 < hhincome <= l80_3 then hud_inc = 3;
          else if l80_3 < hhincome <= l50_3*2.4 then hud_inc = 4;
          else if l50_3*2.4 < hhincome<= l50_3*4 then hud_inc = 5;
		  else if l50_3*4 < hhincome then hud_inc = 6;
        end;
      when ( 4 )
        do;
          if hhincome <= ELI_4 then hud_inc = 1;
          else if ELI_4 < hhincome <= l50_4 then hud_inc = 2;
          else if l50_4 < hhincome <= l80_4 then hud_inc = 3;
          else if l80_4 < hhincome <= l50_4*2.4 then hud_inc = 4;
          else if l50_4*2.4 < hhincome<= l50_4*4 then hud_inc = 5;
		  else if l50_4*4 < hhincome then hud_inc = 6;
        end;
      when ( 5 )
        do;
          if hhincome <= ELI_5 then hud_inc = 1;
          else if ELI_5 < hhincome <= l50_5 then hud_inc = 2;
          else if l50_5 < hhincome <= l80_5 then hud_inc = 3;
          else if l80_5 < hhincome <= l50_5*2.4 then hud_inc = 4;
          else if l50_5*2.4 < hhincome<= l50_5*4 then hud_inc = 5;
		  else if l50_5*4 < hhincome then hud_inc = 6;
        end;
      when ( 6 )
        do;
          if hhincome <= ELI_6 then hud_inc = 1;
          else if ELI_6 < hhincome <= l50_6 then hud_inc = 2;
          else if l50_6 < hhincome <= l80_6 then hud_inc = 3;
          else if l80_6 < hhincome <= l50_6*2.4 then hud_inc = 4;
          else if l50_6*2.4 < hhincome<= l50_6*4 then hud_inc = 5;
		  else if l50_6*4 < hhincome then hud_inc = 6;
        end;
      when ( 7 )
        do;
          if hhincome <= ELI_7 then hud_inc = 1;
          else if ELI_7 < hhincome <= l50_7 then hud_inc = 2;
          else if l50_7 < hhincome <= l80_7 then hud_inc = 3;
          else if l80_7 < hhincome <= l50_7*2.4 then hud_inc = 4;
          else if l50_7*2.4 < hhincome<= l50_7*4 then hud_inc = 5;
		  else if l50_7*4 < hhincome then hud_inc = 6;
        end;
      otherwise
        do;
          if hhincome <= ELI_8 then hud_inc = 1;
          else if ELI_8 < hhincome <= l50_8 then hud_inc = 2;
          else if l50_8 < hhincome <= l80_8 then hud_inc = 3;
          else if l80_8 < hhincome <= l50_8*2.4 then hud_inc = 4;
          else if l50_8*2.4 < hhincome<= l50_8*4 then hud_inc = 5;
		  else if l50_8*4 < hhincome then hud_inc = 6;
        end;
    end;

  end;

  label hud_inc = "HUD income categories";
  
%mend Hud_inc_NCState;

/** End Macro Definition **/


