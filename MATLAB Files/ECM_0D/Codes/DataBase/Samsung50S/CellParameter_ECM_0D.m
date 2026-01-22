function [param,const] = CellParameter_ECM_0D(options)

%Based on Pulse Data:
load('PulseFit_Samsung_50S_ECM_R_3RC.mat')

%% Constants ##############################################################
const.F=9.648533212e4; %[As/mol]
const.z=1; %Charge Number for Li-Ionen -> 1
const.R=8.314462; %[J/mol K]

%% Geometric Values #######################################################
%Not yet necessary

%% Capacity ###############################################################
param.Cell.C=5; %[Ah]
%% Thermal ################################################################
param.thermal.m=72e-3;  %cell mass [kg]
param.thermal.cp=1000; %cell heat capacity [J/kgK]
param.thermal.mcp=param.thermal.m*param.thermal.cp; %thermla mass [J/K]

%% Solid Diffusion ########################################################
param.ParticleDiffusion.Anode.Cmax=2.4108e4; %Max Concentration (100% SoC)
param.ParticleDiffusion.Anode.Cmin=186.55; %Min Concentration (0% SoC)
param.ParticleDiffusion.Anode.R = 7e-6; % particle radius [m]
param.ParticleDiffusion.Anode.D = 3.9e-14; % solid diffusivity, [m^2/s]

param.ParticleDiffusion.Cathode.R = 3e-6;    % particle radius [m]
param.ParticleDiffusion.Cathode.Cmax = 4.82e4; % [mol/m^3] %fully charged
param.ParticleDiffusion.Cathode.Cmin = 2.1725e4; %fully discharged
param.ParticleDiffusion.Cathode.D = 5.387e-15;    % solid diffusivity, [m^2/s]

%Calaculated Values #######################################################
param.ParticleDiffusion.Anode.dR = param.ParticleDiffusion.Anode.R/options.seg_particle; %width of each "shell"
param.ParticleDiffusion.Anode.Sa = 4*pi*(param.ParticleDiffusion.Anode.R*(1:options.seg_particle)/options.seg_particle).^2; % outer surface area of each shell
param.ParticleDiffusion.Anode.dV = (4/3)*pi*((param.ParticleDiffusion.Anode.R*(1:options.seg_particle)/options.seg_particle).^3 ...
    -(param.ParticleDiffusion.Anode.R*(0:options.seg_particle-1)/options.seg_particle).^3); % vol. of ea. shell
param.ParticleDiffusion.Anode.VolumeParticle=(4/3)*pi*(param.ParticleDiffusion.Anode.R*(1:options.seg_particle)/options.seg_particle).^3;

param.ParticleDiffusion.Cathode.dR = param.ParticleDiffusion.Cathode.R/options.seg_particle; %width of each "shell"
param.ParticleDiffusion.Cathode.Sa = 4*pi*(param.ParticleDiffusion.Cathode.R*(1:options.seg_particle)/options.seg_particle).^2; % outer surface area of each shell
param.ParticleDiffusion.Cathode.dV = (4/3)*pi*((param.ParticleDiffusion.Cathode.R*(1:options.seg_particle)/options.seg_particle).^3 ...
    -(param.ParticleDiffusion.Cathode.R*(0:options.seg_particle-1)/options.seg_particle).^3); % vol. of ea. shell
param.ParticleDiffusion.Cathode.VolumeParticle=(4/3)*pi*(param.ParticleDiffusion.Cathode.R*(1:options.seg_particle)/options.seg_particle).^3;

param.ParticleDiffusion.Anode.tau=param.ParticleDiffusion.Anode.dV(1:options.seg_particle-1) ...
    *param.ParticleDiffusion.Anode.dR./(2*param.ParticleDiffusion.Anode.D ...
    *param.ParticleDiffusion.Anode.Sa(1:options.seg_particle-1))/10;

param.ParticleDiffusion.Cathode.tau=param.ParticleDiffusion.Cathode.dV(1:options.seg_particle-1) ...
    *param.ParticleDiffusion.Cathode.dR./(2*param.ParticleDiffusion.Cathode.D ...
    *param.ParticleDiffusion.Cathode.Sa(1:options.seg_particle-1))/10;

param.ParticleDiffusion.Anode.CapaFac=(4/3)*pi*param.ParticleDiffusion.Anode.R^3 ...
    *(param.ParticleDiffusion.Anode.Cmax-param.ParticleDiffusion.Anode.Cmin)*const.F/(param.Cell.C*3600); %Capa of a single particle [Ah]

param.ParticleDiffusion.Cathode.CapaFac=(4/3)*pi*param.ParticleDiffusion.Cathode.R^3 ...
    *(param.ParticleDiffusion.Cathode.Cmax-param.ParticleDiffusion.Cathode.Cmin)*const.F/(param.Cell.C*3600); %Capa of a single particle [Ah]

end

