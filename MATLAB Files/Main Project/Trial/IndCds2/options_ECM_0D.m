function [options,msg] = options_ECM_0D

%% options:
%Cell type ################################################################
options.cell='GrSi'; % Cell Type

% Bools ###################################################################
options.bool.ini=1; %Do not change this value: 1 means that the set inital values will be used running the battery model the first time

%Initial Values ###########################################################
options.ini.T=297.15; % [°K]
options.ini.SoC=0.95;% [-] 0-1

%% Si content
% Si wt.-% options, this will be used later. x6 total
options.wSi=[0,0.2,0.4,0.6,0.8,1];
%Aging ####################################################################
options.ini.SoH_R=1; % [-] 0-1 with 1 being healthy
options.ini.SoH_C=1; % [-] 0-1

%Thermal Model ############################################################
% This might be used later, but is currently not being used.
options.Thermal.coolingPower=0; %[W]

%Time Step ################################################################
options.delta_t=60; %[s]
options.time_steps = 2000; % # of times steps in the provided data.

%% Save Structure
options.Save.Cell={'U';'T';'SoC';'OCV'};

% Error MSG ###############################################################
% Unknown what the point of the error messages are for at this point. Will
% leave it as originally placed.
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

