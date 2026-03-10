%##########################################################################
% ECM_Parameter_ECM_VolThev:
%   Author: Joshua Eastgaard
%   Purpose: Calculate all required values for the SiGr - NMC Volume 
%            Coupled 2RC Thevenin model. Needs to be recalculated for each
%            wtSi% and C-rate. Returned structure should be available for
%            any models that require it. Paramaterized values are also
%            held here so that other models can calculate values at a given
%            time step in the provided data.
%   Params: 
%       - data_save: save structure that holds pre-calculated volume data.
%       - options: data structure holding various consts and data.
%       - wtSi: Index to determine current wtSi%. Index references options.
%       - cRate: Numerical value that sets the paramaterized C-Rate.
%%

function [param] = ECM_Parameter_ECM_VolThev(...
    data_save, options, wtSi, cRate)

% Retrieve given data in param
load('Potential_Gr_Si_NMC.mat')

% We now want to join the data since we have to discharge then charge up
% again.
param.NMC_OCV = [ param.potentials.HC.DCH.NMC_OCV(:,1);...
    param.potentials.HC.CH.NMC_OCV(:,1) ];
param.NMC_SoC = [ param.potentials.HC.DCH.NMC_SoC(:,1);...
    param.potentials.HC.CH.NMC_SoC(:,1) ];

param.GrSi_OCV = [ param.potentials.HC.DCH.GrSi_OCV(:,1);...
    param.potentials.HC.CH.GrSi_OCV(:,1) ];
param.GrSi_SoC = [ param.potentials.HC.DCH.GrSi_SoC(:,1);...
    param.potentials.HC.CH.GrSi_SoC(:,1) ];

%% Fix data so there are no duplicated OCV values for SOC values
[SoC_unique_GrSi, ~, group] = unique(param.GrSi_SoC, 'stable');
OCV_unique_GrSi = accumarray(group, param.GrSi_OCV, [], @mean );

[SoC_unique_NMC, ~, group] = unique(param.NMC_SoC, 'stable');
OCV_unique_NMC = accumarray(group, param.NMC_OCV, [], @mean );

param.GrSi_SoC = SoC_unique_GrSi;
param.GrSi_OCV = OCV_unique_GrSi;

param.NMC_SoC = SoC_unique_NMC;
param.NMC_OCV = OCV_unique_NMC;

% Fix time to the new length due to removed repeated values.
% *** NOTE: It is possible that options is not being updated properly and
% cannot be references in other models. ***
options.data.steps = length(param.NMC_OCV(:,1));
options.time_span = 1:1:options.data.steps;

%% Initial values
param.anode.wtSi = options.wtSi(wtSi);
param.cRate = cRate;
param.time_mid = find(param.GrSi_SoC == 0, 1);

% Defined start volume based on the mass and density. Different based
% on the different wtSi.
param.V0 = (options.anode.m * 1000) / ... [cm³]
    ((options.materials.rho_Si * wtSi) + ...
    (options.materials.rho_G * (1-wtSi)));
% fprintf("Found Half time: %.0f [m]\n",param.time_mid);

%% ECM Functions

% Slope of linear SoC in given data. Can be changed if we later determine
% current was not constant. Units are corrected to per minute using dt. *2
% is used because we have doubled the max/min in the data.
param.DCH_Sa = (-1/(options.data.dt*2))... % Correcting for provided data
            * ( param.potentials.HC.DCH.GrSi_SoC(param.time_mid,1)...
            - param.potentials.HC.DCH.GrSi_SoC(1,1)) / ...
            (param.time_mid); %#ok<NODEF> <- error suppresion

disp("The DCH Sa is " + param.DCH_Sa);

param.CH_Sa = (-1/(options.data.dt*2)) * ... % Correcting for provided data
            (param.potentials.HC.CH.GrSi_SoC(param.time_mid,1)...
            - param.potentials.HC.CH.GrSi_SoC(1,1)) / ...
            (param.time_mid);

%% Current Calculation
% Current (const) assumed at this time. 3600 = seconds, 60 = minutes, 1 =
% hours.
param.DCH_I = cRate * param.DCH_Sa *...
    ( options.anode.Qa * 3600 / options.anode.na );
param.CH_I = cRate * param.CH_Sa * ...
    ( options.anode.Qa * 3600 / options.anode.na );

param.I = @(t) (t>param.time_mid)*param.CH_I + ...
    (t<=param.time_mid)*param.DCH_I;

% Keep this print statment so that users know code is moving.
fprintf("Discharge Current: %.3f[mA]\nInput Current:%.3f[mA]\n",...
    param.DCH_I*1000,param.CH_I*1000);

%% Lithiation of Anode and Cathode
param.za = @(t) interp1(options.time_span,...
                    param.GrSi_SoC,...
                    t, 'linear', 'extrap');
param.zc = @(t) interp1(options.time_span,...
                    param.NMC_SoC,...
                    t, 'linear', 'extrap');

%% OCV as a interpolated value.
param.OCV_anode = @(t) interp1( ...
    param.GrSi_SoC(:,1), ...
    param.GrSi_OCV(:,1), ...
    max(0, min(1, param.za(t))), ...   % clamp SoC
    'pchip');

param.OCV_cathode = @(t) interp1( ...
    param.NMC_SoC(:,1), ...
    param.NMC_OCV(:,1), ...
    max(0, min(1, param.zc(t))), ...   % clamp SoC
    'pchip');

% Dimensionless Max volumetric strain
param.anode.aSi = 3 * param.anode.wtSi;

% Volume strain / expantion
param.Volexp = @(t) interp1(options.time_span,...
                    data_save.VV0(:,wtSi) ,...
                    t, 'linear', 'extrap');

% Volume-dependent resistance and RC
param.R0 = @(t) options.ECM.R0 * (1 + options.ECM.kR0 * param.Volexp(t) );

param.R1 = @(t) options.ECM.R1 * (1 + options.ECM.kR1 * param.Volexp(t) );
param.R2 = @(t) options.ECM.R2 * (1 + options.ECM.kR2 * param.Volexp(t) );

param.Rtot = @(t) param.R0(t) + param.R1(t) + param.R2(t);

param.C1 = @(t) options.ECM.C1 * (1 + options.ECM.kC1 * param.Volexp(t) );
param.C2 = @(t) options.ECM.C2 * (1 + options.ECM.kC2 * param.Volexp(t) );

% Cell voltage
param.UCell = @(t) param.OCV_cathode(t) - param.OCV_anode(t);

% Effective heat capacity of the electrode composite.
param.ThermCap = @(w) 690*(1-w) + 700*w; % Gr 800J/kgK, Si 700J/kgK

% Entropic coefficient of graphite
% const. value sourced from data set. Reference in report.
% Sin offers some realistic curvatures, will show as repoeated
% random variation.
param.dUdT_Gr = @(c) -1.4e-4*(0.8 + 0.2*sin(pi*c));

% Entropic coefficient of silicon
param.dUdT_Si = @(c) 3.2e-4*(0.8 + 0.2*sin(pi*c));

% Weighted micture of entropic coefficients
param.dUdT = @(c,w) w*param.dUdT_Si(c) + (1-w)*param.dUdT_Gr(c);

% Thermal mass [J/K]
param.thermal.mcp= @(w) options.anode.m * param.ThermCap(w);
end

