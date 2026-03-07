% This ECM currently assumes instantantanious volume expansion so we do not
% include the calculations with a time constant.
function [param] = ECM_Parameter_ECM_VolThev(options, wtSi, cRate)

% Retrieve given data in param
load('Potential_Gr_Si_NMC.mat')

% We now want to join the data since we have to discharge then charge up
% again.
param.NMC_OCV = [ param.potentials.HC.DCH.NMC_OCV(:,1);param.potentials.HC.CH.NMC_OCV(:,1) ];
param.NMC_SoC = [ param.potentials.HC.DCH.NMC_SoC(:,1); param.potentials.HC.CH.NMC_SoC(:,1) ];

param.GrSi_OCV = [ param.potentials.HC.DCH.GrSi_OCV(:,1); param.potentials.HC.CH.GrSi_OCV(:,1) ];
param.GrSi_SoC = [ param.potentials.HC.DCH.GrSi_SoC(:,1); param.potentials.HC.CH.GrSi_SoC(:,1) ];
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
options.data.steps = length(param.NMC_OCV(:,1));
options.time_span = 1:1:options.data.steps;

%% Initial values
param.anode.wtSi = wtSi;
param.cRate = cRate;
param.time_mid = find(param.GrSi_SoC == 0, 1);

fprintf("Found Half time: %.0f [m]\n",param.time_mid);
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
param.DCH_I = cRate * param.DCH_Sa * ( options.anode.Qa * 3600 / options.anode.na );
param.CH_I = cRate * param.CH_Sa * ( options.anode.Qa * 3600 / options.anode.na );

param.I = @(t) (t>param.time_mid)*param.CH_I + (t<=param.time_mid)*param.DCH_I;
% param.I = @(t) (t*0 +1 )*param.DCH_I;


fprintf("Discharge Current: %.3f[mA]\nInput Current:%.3f[mA]\n",param.DCH_I*1000,param.CH_I*1000);

%% Lithiation of Anode and Cathode
param.za = @(t) interp1(options.time_span,...
                    param.GrSi_SoC,...
                    t, 'linear', 'extrap');
param.zc = @(t) interp1(options.time_span,...
                    param.NMC_SoC,...
                    t, 'linear', 'extrap');

%% OCV as a interpolated
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

param.anode.aSi = 3 * param.anode.wtSi; % Dimensionless Max volumetric strain

% Volume strain / expantion
param.Volexp = @(t) param.anode.aSi * param.za(t); 

% Volume-dependent resistance and RC
param.R0 = @(t) options.ECM.R0 * (1 + options.ECM.kR0 * param.Volexp(t) );

param.R1 = @(t) options.ECM.R1 * (1 + options.ECM.kR1 * param.Volexp(t) );
param.R2 = @(t) options.ECM.R2 * (1 + options.ECM.kR2 * param.Volexp(t) );

param.Rtot = @(t) param.R0(t) + param.R1(t) + param.R2(t);

param.C1 = @(t) options.ECM.C1 * (1 + options.ECM.kC1 * param.Volexp(t) );
param.C2 = @(t) options.ECM.C2 * (1 + options.ECM.kC2 * param.Volexp(t) );

% Cell voltage
param.UCell = @(t) param.OCV_cathode(t) - param.OCV_anode(t);

%% Thermal Parameters
% These will need to be changed for the merge/integration into the ECM
% Ohmic Resistance of the cell

% Effective heat capacity of the electrode composite.
param.ThermCap = @(w) 800*(1-w) + 700*w; % Gr 800J/kgK, Si 700J/kgK

% Will look at different models for this later, this is just a demo value
param.R00 = @(w) 0.02 + 0.03 * w; % Higher R, more irreversible heat and SEI thickening.

% Placeholder OCV curve for Gr
param.OCV_Gr = @(z) 0.1 + 0.9*z;

% Placeholder OCV curve for Si
param.OCV_Si = @(z) 0.2 + 0.7*z;

% Placeholder weighted sum of Si and Gr OCV
param.OCV_tot = @(z,w) w*param.OCV_Si(z) + (1-w)*param.OCV_Gr(z);

% Entropic coefficient of graphite
param.dUdt_Gr = @(c) 8e-6*sin(pi*c);

% Entropic coefficient of silicon
param.dUdt_Si = @(c) 2e-5*sin(pi*c);

% Weighted micture of entropic coefficients
param.dUdt = @(c,w) w*param.dUdt_Si(c) + (1-w)*param.dUdt_Gr(c);

% Capacity ###############################################################
% Above is a nominal cap being used, leaving this here for later
% implimentation.

param.thermal.mcp= @(w) options.anode.m * param.ThermCap(w); %thermla mass [J/K]
end

