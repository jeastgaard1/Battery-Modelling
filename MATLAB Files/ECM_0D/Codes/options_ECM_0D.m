function [options,msg] = options_ECM_0D

%% options:
%Cell type ################################################################
options.cell='Sam_50S'; % Cell Type

% Bools ###################################################################
options.bool.ini=1; %Do not change this value: 1 means that the set inital values will be used running the battery model the first time
options.bool.Aging=0;
options.bool.Thermal=1;
options.bool.cruise=0;
options.bool.EIS=0; %Use EIS (1) or Pulse (0) data for parametrization

% Cell configuration ######################################################
options.cell_con.p=1; % number of parallel-connected cells
options.cell_con.s=1; % number of seriel-connected cells

%Initial Values ###########################################################
options.ini.T=20; % [°C]
options.ini.SoC=0.95;% [-] 0-1

%Aging ####################################################################
options.ini.SoH_R=1; % [-] 0-1
options.ini.SoH_C=1; % [-] 0-1

%Electrical Model #########################################################
% FAC  = Factor
options.Electrical.R_fac=1.2;
options.Electrical.RC1_fac=1.2;
options.Electrical.RC2_fac=1.2;
options.Electrical.RC3_fac=1.15;
options.Electrical.C_fac=1;

options.Electrical.tau_RC1_fac=1;
options.Electrical.tau_RC2_fac=1;
options.Electrical.tau_RC3_fac=1;
%Solid Diffusion ##########################################################
options.seg_particle=15; %Particle discretization (number of shells)
% For more information on the number of shells, look at lecture notes.
%In case of EIS Data:
% These are just lists of string values so that we can reference the values
% later.
options.Names_ECM={'tau_1';'R_1';'tau_2';'R_2';'tau_3';'R_3';'tau_4';'R_4';'tau_5';'R_5' ...
    ;'tau_6';'R_6';'tau_7';'R_7';'tau_8';'R_8';'tau_9';'R_9' ...
    };
options.Names_ECM_U={'U_1';'U_2';'U_3';'U_4';'U_5';'U_6';'U_7';'U_8';'U_9'};
options.Names_Elements={'Zarc1';'Zarc2';'WarBurg'};

%Thermal Model ############################################################
options.Thermal.coolingPower=0; %[W]

%Time Step ################################################################
options.delta_t=1e-0; %[s]

% Do not change this part #################################################
%TransferData #############################################################
% This cannot be changed as it is connected to the provided data stucture.
options.Transfer.Cell={'I';'U';'T';'SoC';'OCV';'Entropy';'P_control';'P';'h'};
options.Transfer.ECM={'Usc';'R';'R_RC1';'tau_RC1';'R_RC2';'tau_RC2';'R_RC3';'tau_RC3';'U_RC1';'U_RC2';'U_RC3'};
options.Transfer.Particle={'c_Li_Anode';'c_Li_Cathode'};

options.Save.Cell={'I';'U';'T';'SoC';'OCV';'Entropy';'P_control';'P'};
options.Save.ECM={'Usc';'R';'R_RC1';'tau_RC1';'R_RC2';'tau_RC2';'R_RC3';'tau_RC3';'U_RC1';'U_RC2';'U_RC3'};
options.Save.Particle={'c_Li_Anode';'c_Li_Cathode'};

% Error MSG ###############################################################
msg.error.T=0;
msg.error.Tmax=0;
msg.error.I=0;
msg.error.OCV=0;
msg.error.SOC=0;

msg.error.R_RC1=0;
msg.error.R_RC2=0;
msg.error.R_RC3=0;

msg.error.tau_RC1=0;
msg.error.tau_RC2=0;
msg.error.tau_RC3=0;

msg.interupt.Umin=0;
msg.interupt.Umax=0;
end

