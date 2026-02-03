clear
clc
% This code allows MATLAB to find all the required files.
addpath(genpath('Models'));

[options,msg]=options_ECM_VolThev %Loads all settings

[param]=ECM_Parameter_ECM_VolThev(options,0,0); %Loads cell parameter with 0% Si
[battery_res,data_save]=structure_ECM_2RC_VolThev(options);%Loads final strucutre for results

battery_res.Aging.SoH_R(1,1)=1; %Set inital SoH values
battery_res.Aging.SoH_C(1,1)=1; %Set inital SoH values

SoC = 0.95

[dl_th_anode,dl_th_cathode] = [zeros(options.init_width,options.init_height, options.init_thickness),zeros(options.init_width,options.init_height, options.init_thickness)]
boundarycondition = 0; %0 for fixed, 1 for free


[dL_int_anode] = AnodeIntercalationExpansion (options,param,SoC) %removed ,sort
[dL_int_cathode] = CathodeIntercalationExpansion(options,param,SoC) %removed ,sort
[dL_total_anode, dL_total_cathode, dL_total] = TotalExpansion(options,dL_th_anode, dL_int_anode, dL_th_cathode, dL_int_cathode,dL_th_CC_Cathode, dL_th_CC_Anode, dL_th_Separator,param)

[sigma_cell,epsilon_separator,epsilon_BufferLayer,epsilon_anode,epsilon_cathode] = MechForces(deltaL_total, options, param)

