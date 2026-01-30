function [param,const] = CellParameter_ECM_0D(options)

%Based on Pulse Data:
load('Potential_Gr_Si_NMC.mat')

%% Constants ##############################################################
const.F=9.648533212e4; %[As/mol]
const.z=1; %Charge Number for Li-Ionen -> 1
const.R=8.314462; %[J/mol K]
%% Personal Input ########################################################
%Si wt.-% options
param.wSi={0,0.2,0.4,0.6,0.8,1};
param.T_amb = 300;
% Nominal Capacity
param.Qnom = 2500; %mAh

% Effective heat capacity of the electrode composite.
param.ThermCap = @(w) 800*(1-w) + 700*w; % Gr 800J/kgK, Si 700J/kgK

% Heat transfer Coefficient * Surface Area (smaller hA = cell retains heat)
param.hA = 5;

% Ohmic Resistance of the cell
% Will look at different models for this later, this is just a demo value
param.R00 = @(w) 0.01 + 0.02 * w; % Higher R, more irreversible heat and SEI thickening.

% Placeholder OCV curve for Gr
param.OCV_Gr = @(z) 0.1 + 0.9*z;

% Placeholder OCV curve for Si
param.OCV_Si = @(z) 0.2 + 0.7*z;

% Placeholder weighted sum of Si and Gr OCV
param.OCV_tot = @(z,w) w*param.OCV_Si(z) + (1-w)*param.OCV_Gr(z);

% Entropic coefficient of graphite
param.dUdt_Gr = @(c) 1e-4*sin(pi*c);

% Entropic coefficient of silicon
param.dUdt_Si = @(c) 2e-4*sin(pi*c);

% Weighted micture of entropic coefficients
param.dUdt = @(c,w) w*param.dUdt_Si(c) + (1-w)*param.dUdt_Gr(c);

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

