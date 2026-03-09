function [options,msg] = options_ECM_VolThev

%% Simulation options
options.data.steps = 4008; % Based on given data.
options.total_time = 120; % minutes
options.time_vec = linspace(...
    0,options.total_time,...
    options.data.steps);
options.time_span = 1:1:options.data.steps;
options.data.dt = 3600/(options.data.steps/2); % time change per step.

%% Save Structure
options.Save.Cell={'U';'SoC';'OCV';'j_Si';'j_Gr';'I_Si';'I_Gr';'I_tot'};
options.Save.T = {'T_lowC';'T_midC';'T_highC'};

%% Model options
%Cell type ################################################################
options.cell='GrSiNMC 21700class cell'; % Cell Type
options.wtSi = [0.15 0.3 0.45 0.6 0.75];
options.cRates = [0.1 1 3];
%% ECM Variables
% Based on GrSiNMC 21700class cell
options.ECM.R0 = 8e-3; % Base resistance for intial element
options.ECM.R1 = 2.5e-3; % Base resistance for first RC element
options.ECM.R2 = 5e-3; % Base resistance for second RC element
options.ECM.C1 = 300; % Base capacitance for first RC element
options.ECM.C2 = 600; % Base capacitance for second RC element

options.ECM.kR0 = 0.5; % Sensitivity of R0 to Si strain.
options.ECM.kR1 = 0.3; % Sensitivity of R1 to Si strain.
options.ECM.kR2 = 0.2; % Sensitivity of R2 to Si strain.
options.ECM.kC1 = 0.2; % Sensitivity of C1 to Si strain.
options.ECM.kC2 = 0.1; % Sensitivity of C2 to Si strain.

% Anode Values
options.anode.Qa = 5.5; % Ah Nominal Q
options.anode.na = 1.0; % Dimensionless Coulumb efficiency
options.anode.hA = 0.3; % Heat transfer Coefficient * Surface Area (smaller hA = cell retains heat)
options.anode.m = 0.3;  % cell mass [kg]

%% Material Properties for Electrode Design Analysis
% Densities [g/cm³]
options.materials.rho_Si = 2.3;      % Silicon density
options.materials.rho_G = 2.24;      % Graphite density
options.materials.rho_IM = 1.1;      % Inactive materials density

% Specific Capacities [mAh/g]
options.materials.s_Si = 3600;       % Silicon specific capacity
options.materials.s_G = 330;         % Graphite specific capacity
options.materials.s_IM = 0;          % Inactive materials (no capacity)

% Expansion Factors [vol-%]
options.materials.e_Si = 280;        % Silicon expansion
options.materials.e_G = 10;          % Graphite expansion (assumed negligible)
options.materials.e_IM = 0;          % Inactive materials expansion

% Weight Fractions [wt-%]
options.materials.w_IM = 0.05;          % Inactive materials weight fraction

% Particle sizes [m]
options.particles.r_Si = 100e-9;      % Silicon particle radius (100 nm)
options.particles.r_G = 10e-6;        % Graphite particle radius (10 m)

% Electrode properties
options.electrode.epsilon = 0.35;     % Porosity

% Kinetic parameters
options.kinetics.i0_Si = 0.5;         % Silicon exchange current density [A/m²]
options.kinetics.i0_G = 35;           % Graphite exchange current density [A/m²]
options.kinetics.alpha = 0.5;         % Charge transfer coefficient

% Physical constants
options.constants.F = 96485;          % Faraday constant [C/mol]
options.constants.R_gas = 8.314;      % Gas constant [J/(mol·K)]

% Initial / Enviroment Values ###########################################################
options.ini.T=297; % [°K]
options.ini.SoC=0.95;% [-] 0-1
options.env.T_amb = 297; % Ambient Temperature

% Bools ###################################################################
options.bool.ini=1; %Do not change this value: 1 means that the set inital values will be used running the battery model the first time
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

%% Mechanical & Geometric Parameters
options.mech.BoundaryCondition = 'fixed'; % 'fixed' or 'free' (free is recommended for realistic stress)
options.mech.d0_anode = 65e-6;           % [m]
options.mech.d0_cathode = 55e-6;         % [m]
options.mech.d0_sep = 12e-6;             % [m]
options.mech.Area = 0.012;               % [m^2]

% Material Stiffness (Young's Moduli in Pa)
options.mech.E_anode = 12e9; 
options.mech.E_cathode = 25e9; 
options.mech.E_sep = 1.2e9; 

% Particle Properties
options.mech.R_p = 5e-6;                 % [m]
options.mech.D_s = 1e-14;                % [m^2/s]
options.mech.Omega = 3.497e-6;           % [m^3/mol]
options.mech.nu = 0.3;                   % Poisson ratio
options.mech.rho_avg = 2000;             % [kg/m^3] average density
options.mech.Capacity_theo = 372 * 3600; % [As/kg] Graphite theoretical

%% Solid Diffusion ##########################################################
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

% options.Save.Cell={'I';'U';'T';'SoC';'OCV';'Entropy';'P_control';'P'};
% options.Save.ECM={'Usc';'R';'R_RC1';'tau_RC1';'R_RC2';'tau_RC2';'R_RC3';'tau_RC3';'U_RC1';'U_RC2';'U_RC3'};
% options.Save.Particle={'c_Li_Anode';'c_Li_Cathode'};

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

