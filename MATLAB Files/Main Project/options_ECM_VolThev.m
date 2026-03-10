%##########################################################################
% options_ECM_VolThev:
%   Author: Joshua Eastgaard
%   Purpose: Store all the required constants and data structures for the
%            running models. One location to change any required values.
%   Params: (none)
%%
function [options] = options_ECM_VolThev

%% Simulation options
options.data.steps = 4008; % Based on given data.
options.total_time = 120; % minutes, i.e. CH and DCH took 2 hours.
options.time_vec = linspace(...
    0,options.total_time,...
    options.data.steps);
options.time_span = 1:1:options.data.steps;
options.data.dt = 3600/(options.data.steps/2); % time change per step.

%% Save Structure
options.Save.Cell={'U';'SoC';'OCV';'j_Si';'j_Gr';'I_Si';'I_Gr';'I_tot'};
options.Save.T = {'T_lowC';'T_midC';'T_highC'};
options.Save.ECM = {'R';'R_RC1';'R_RC2'};
options.Save.TVE = {'TVE_lowC';'TVE_midC';'TVE_highC'};

%% Model options
%Cell type ################################################################
options.cell='GrSiNMC 21700class cell'; % Cell Type
options.wtSi = [0.15 0.3 0.45 0.6 0.75];
options.cRates = [0.1 1 3];
%% ECM Variables
% Based on GrSi-NMC 21700 class cell
options.ECM.R0 = 1.2e-3; % Base resistance for intial element
options.ECM.R1 = 4e-3; % Base resistance for first RC element
options.ECM.R2 = 8e-3; % Base resistance for second RC element
options.ECM.C1 = 350; % Base capacitance for first RC element
options.ECM.C2 = 1000; % Base capacitance for second RC element

options.ECM.kR0 = 0.9; % Sensitivity of R0 to Si strain.
options.ECM.kR1 = 0.8; % Sensitivity of R1 to Si strain.
options.ECM.kR2 = 0.5; % Sensitivity of R2 to Si strain.
options.ECM.kC1 = 0.4; % Sensitivity of C1 to Si strain.
options.ECM.kC2 = 0.2; % Sensitivity of C2 to Si strain.

% Anode Values
options.anode.Qa = 5; % Ah Nominal Q
options.anode.na = 1.0; % Dimensionless Coulumb efficiency
options.anode.hA = 0.3; % Heat transfer Coefficient * 
                        % Surface Area (smaller hA = cell retains heat)
options.anode.m = 0.3;  % cell mass [kg]

%% Material Properties for Electrode Design Analysis
% Densities [g/cm�]
options.materials.rho_Si = 2.329;      % Silicon density
options.materials.rho_G = 2.26;      % Graphite density
options.materials.rho_IM = 1.1;      % Inactive materials density

% Specific Capacities [mAh/g]
options.materials.s_Si = 3600;       % Silicon specific capacity
options.materials.s_G = 330;         % Graphite specific capacity
options.materials.s_IM = 0;          % Inactive materials (no capacity)

% Entropic Coefficients 
options.materials.dUdT_Si = 3.2e-4;  % Si is positive, not cool
options.materials.dUdT_Gr = -1.4e-4; % Negative for Gr (cool right?)

% Expansion Factors [vol-%]
options.materials.e_Si = 280;      % Silicon expansion based on literature
options.materials.e_G = 10;        % Graphite expansion based on literature
options.materials.e_IM = 0;        % Inactive materials expansion
options.materials.alpha_L = 3e-6;  % Linear thermal expansion coef. [1/K]

% Weight Fractions [wt-%]
options.materials.w_IM = 0.05;     % Inactive materials weight fraction

% Particle sizes [m]
options.particles.r_Si = 100e-9;      % Silicon particle radius (100 nm)
options.particles.r_G = 10e-6;        % Graphite particle radius (10 m)

% Electrode properties
options.electrode.epsilon = 0.35;     % Porosity

% Kinetic parameters
options.kinetics.i0_Si = 0.5;   % Silicon exchange current density [A/m�]
options.kinetics.i0_G = 35;     % Graphite exchange current density [A/m�]
options.kinetics.alpha = 0.5;   % Charge transfer coefficient

% Physical constants
options.constants.F = 96485;          % Faraday constant [C/mol]
options.constants.R_gas = 8.314;      % Gas constant [J/(mol�K)]

% Initial / Enviroment Values #############################################
options.ini.T=297; % [�K]
options.ini.SoC=0.95;% [-] 0-1
options.env.T_amb = 297; % Ambient Temperature

% Bools ###################################################################
options.bool.ini=1; %Do not change this value
options.bool.Aging=0;
options.bool.Thermal=0;
options.bool.cruise=0;
options.bool.EIS=0; %Use EIS (1) or Pulse (0) data for parametrization

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

%% Mechanical Model Parameters
options.mech.d0_anode = 80e-6;    % Initial anode thickness [m]
options.mech.d0_cathode = 70e-6;  % Initial cathode thickness [m]
options.mech.d0_sep = 15e-6;      % Separator thickness [m]
options.mech.Area = 0.05;         % Electrode area [m^2]

options.mech.E_anode = 12e9;      % Anode Young's Modulus [Pa]
options.mech.E_cathode = 25e9;    % Cathode Young's Modulus [Pa]
options.mech.E_sep = 0.5e9;       % Separator Young's Modulus [Pa]
options.mech.nu = 0.3;            % Poisson's ratio

% Particle properties for micro-scale stress
options.mech.D_s = 1e-16;         % Si Diffusion coefficient [m^2/s]
options.mech.R_p = options.particles.r_Si; % Use defined radius
options.mech.Omega = 1.2e-5;      % Si Partial molar volume [m^3/mol]
% 'fixed' (for stack stress) or 'free
options.mech.BoundaryCondition = 'fixed'; 

%Time Step ################################################################
options.delta_t=1e-0; %[s]
end

