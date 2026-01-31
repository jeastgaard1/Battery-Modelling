function [param,const] = CellParameter_ECM_0D(options)

%Based on Pulse Data:
load('Potential_Gr_Si_NMC.mat')
% The data provided just provides voltage measurments.
% OCV and SoC provided.
%% Constants ##############################################################
const.F=9.648533212e4; %[As/mol]
const.z=1; %Charge Number for Li-Ionen -> 1
const.R=8.314462; %[J/mol K]
%% Personal Input ########################################################
param.T_amb = 300; % [K]
% Nominal Capacity
param.Qnom = 2500; %mAh

% Effective heat capacity of the electrode composite.
param.ThermCap = @(w) 800*(1-w) + 700*w; % Gr 800J/kgK, Si 700J/kgK

% Heat transfer Coefficient * Surface Area (smaller hA = cell retains heat)
param.hA = 0.5;

% Ohmic Resistance of the cell
% Will look at different models for this later, this is just a demo value
param.R00 = @(w) 0.02 + 0.03 * w; % Higher R, more irreversible heat and SEI thickening.

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

%% Capacity ###############################################################
% Above is a nominal cap being used, leaving this here for later
% implimentation.
param.Cell.C=5; %[Ah]
%% Thermal ################################################################
param.thermal.m=72e-3;  %cell mass [kg]

param.thermal.mcp= @(w) param.thermal.m * param.ThermCap(w); %thermla mass [J/K]


end

