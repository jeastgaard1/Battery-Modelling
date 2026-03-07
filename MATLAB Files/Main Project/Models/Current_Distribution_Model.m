function [battery_res] = Current_Distribution_Model(param, options, t_sim)
%% ═══════════════════════════════════════════════════════════════════════
%% CURRENT DISTRIBUTION ANALYSIS (ECM + BUTLER-VOLMER)
%% ═══════════════════════════════════════════════════════════════════════
% This function calculates the current distribution between Silicon and
% Graphite in a composite anode using ECM overpotential and Butler-Volmer
% kinetics.

%% Extract material properties from options structure
s_Si = options.materials.s_Si;
s_G = options.materials.s_G;

%% Get current configuration
wtSi = param.anode.wtSi;    % Silicon weight fraction [%]
wtG = options.materials.w_IM;          % Graphite weight fraction [%]

%% Physical constants (from options.constants)
F = options.constants.F;           % Faraday constant [C/mol]
R_gas = options.constants.R_gas;   % Gas constant [J/(mol·K)]
T = options.ini.T;                 % Temperature [K]

%% Material properties (convert to g/m³)
rho_Si_cd = options.materials.rho_Si * 1e6;
rho_G_cd = options.materials.rho_G * 1e6;

%% Kinetic parameters (from options.kinetics)
i0_Si_ref = options.kinetics.i0_Si;     % Silicon exchange current density [A/m²]
i0_G_ref = options.kinetics.i0_G;       % Graphite exchange current density [A/m²]
alpha = options.kinetics.alpha;         % Charge transfer coefficient

%% Particle sizes (from options.particles)
r_Si = options.particles.r_Si;       % Silicon particle radius [m]
r_G = options.particles.r_G;         % Graphite particle radius [m]

%% Electrode porosity (from options.electrode)
epsilon_cd = options.electrode.epsilon;  % Electrode porosity [-]

%% Fixed total capacity (from options.anode)
Q_total_fixed = options.anode.Qa;  % Total capacity [Ah]

% Composite specific capacity
Q_composite = wtSi * s_Si + wtG * s_G;  % [mAh/g]

% Calculate mass needed for target capacity
m_total = Q_total_fixed * 1000 / Q_composite;  % [g]

%% Calculate volumes and surface areas 
% Volumes
V_Si = wtSi * m_total / rho_Si_cd;
V_G = wtG * m_total / rho_G_cd;
V_total = V_Si + V_G;         % [m³]

% Specific surface areas per unit volume
a_Si = 3 / (rho_Si_cd * r_Si);  % [m²/m³]
a_G = 3 / (rho_G_cd * r_G);     % [m²/m³]

% Active surface areas (accounting for volume fraction and porosity)
a_s_Si = a_Si * (V_Si / V_total) * (1 - epsilon_cd);  % [m²/m³]
a_s_G = a_G * (V_G / V_total) * (1 - epsilon_cd);     % [m²/m³]

%% Get current from param (using discharge current)
I_total = abs(param.DCH_I);  % Total current [A] (use abs to get magnitude)

%% Number of time steps
n_time = length(t_sim);

%% Initialize storage arrays
I_Si_all = zeros(n_time, 1);
I_G_all = zeros(n_time, 1);
j_Si_all = zeros(n_time, 1);
j_G_all = zeros(n_time, 1);
R_total_all = zeros(n_time, 1);
eta_all = zeros(n_time, 1);
SOC_all = zeros(n_time, 1);

%% Calculate for all time steps
time_span_param = 1:length(param.GrSi_SoC);

%% Solve for current distribution at each SOC point
for k = 1:n_time
    % Get current SOC
    SOC_now = param.za(t_sim(k));
    SOC_all(k) = SOC_now;
    
    % Get time-dependent resistance
    t_ecm = interp1(param.GrSi_SoC, time_span_param, SOC_now, 'linear', 'extrap');
    R_total = param.Rtot(t_ecm);  % [Ohm]
    eta_now = I_total * R_total;  % [V]s
  
    % Store for output
    R_total_all(k) = R_total;
    eta_all(k) = eta_now;
    
    % SOC-dependent exchange current densities 
    c_factor = sqrt(SOC_now  * (1 - SOC_now) + 0.01);
    i0_Si_eff = i0_Si_ref * c_factor;
    i0_G_eff = i0_G_ref * c_factor;
    
    % Butler-Volmer (matching original working code)
    BV_term = exp(alpha * F * eta_now / (R_gas * T)) - ...
              exp(-(1 - alpha) * F * eta_now / (R_gas * T));
    
    j_Si = i0_Si_eff * BV_term;  % [A/m²]
    j_G = i0_G_eff * BV_term;    % [A/m²]
    
    j_Si_all(k) = j_Si;
    j_G_all(k) = j_G;

    % Total currents 
    I_Si = j_Si * a_s_Si * V_total;  % [A/m²] × [m²/m³] × [m³] = [A]
    I_G = j_G * a_s_G * V_total;     % [A/m²] × [m²/m³] × [m³] = [A]
    
    % Normalize to ensure total current is conserved
    scale = I_total / (I_Si + I_G);
    I_Si = I_Si * scale;
    I_G = I_G * scale;
    
    I_Si_all(k) = I_Si;
    I_G_all(k) = I_G;
end

%% Calculate derived quantities
wtSi_current = (I_Si_all ./ (I_Si_all + I_G_all)) * 100;
wtG_current = (I_G_all ./ (I_Si_all + I_G_all)) * 100;

%% Store results
battery_res.I_Si = I_Si_all;
battery_res.I_G = I_G_all;
battery_res.j_Si = j_Si_all;
battery_res.j_G = j_G_all;
battery_res.I_tot = I_total;
end