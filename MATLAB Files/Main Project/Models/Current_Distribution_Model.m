function [battery_res] = Current_Distribution_Model(battery_res, param, options, timeStep)
%% ═══════════════════════════════════════════════════════════════════════
%% CURRENT DISTRIBUTION ANALYSIS (ECM + BUTLER-VOLMER)
%% ═══════════════════════════════════════════════════════════════════════
% This function calculates the current distribution between Silicon and
% Graphite in a composite anode using TIME-DEPENDENT OVERPOTENTIAL via ECM (R_tot * I) and Butler-Volmer
% kinetics.


%% Extract material properties from options structure
s_Si = options.materials.s_Si;
s_G = options.materials.s_G;
w_IM      = options.materials.w_IM;

%% ── Weight fractions ────────────────────────────────────────────────────

frac_Si = param.anode.wtSi;          % [-]  e.g. 0.15

% Adjust graphite fraction for inactive material
wtSi_pct = frac_Si * 100;
wtG_pct  = 100 - wtSi_pct - w_IM;
if wtG_pct < 0
    warning('Invalid composition: wtG < 0 for wtSi = %.1f wt-%%', wtSi_pct);
    return;
end
frac_G_adj = wtG_pct / 100;   % adjusted graphite fraction (excl. IM)

%% ── Physical constants ──────────────────────────────────────────────────
F     = options.constants.F;         % Faraday constant [C/mol]
R_gas = options.constants.R_gas;     % Gas constant [J/(mol·K)]
T     = options.ini.T;               % Temperature [K]

%% ── Densities (g/cm³ → g/m³) ───────────────────────────────────────────
rho_Si_m3 = options.materials.rho_Si * 1e6;            % [g/m³]
rho_G_m3  = options.materials.rho_G  * 1e6;            % [g/m³]

%% ── Kinetic parameters ──────────────────────────────────────────────────
i0_Si_ref = options.kinetics.i0_Si;      % Si exchange current density [A/m²]
i0_G_ref  = options.kinetics.i0_G;       % G  exchange current density [A/m²]
alpha = options.kinetics.alpha;      % Charge transfer coefficient [-]

%% ── Particle radii ──────────────────────────────────────────────────────
r_Si = options.particles.r_Si;       % [m]
r_G  = options.particles.r_G;        % [m]

%% ── Electrode porosity ──────────────────────────────────────────────────
epsilon = options.electrode.epsilon; % [-]

%% ── Mass & volume from fixed total capacity ─────────────────────────────
Q_total_fixed = options.anode.Qa;                             % [Ah]
Q_composite   = frac_Si * s_Si + frac_G_adj * s_G;           % [mAh/g]
m_total       = Q_total_fixed * 1000 / Q_composite;           % [g]

V_Si    = frac_Si    * m_total / rho_Si_m3;                   % [m³]
V_G     = frac_G_adj * m_total / rho_G_m3;                    % [m³]
V_total = V_Si + V_G;                                         % [m³]

%% ── Active surface areas ────────────────────────────────────────────────
% Spherical particles: a = 3 / (rho * r)
a_Si   = 3 / (rho_Si_m3 * r_Si);                           % [m²/m³]
a_G    = 3 / (rho_G_m3  * r_G);                            % [m²/m³]

% Active surface areas (accounting for volume fraction and porosity)
a_s_Si = a_Si * (V_Si / V_total) * (1 - epsilon);          % [m²/m³]
a_s_G  = a_G  * (V_G  / V_total) * (1 - epsilon);          % [m²/m³]

%% ── Total current ───────────────────────────────────────────────────────
I_total = abs(param.DCH_I);                                % [A]

%% ══════════════════════════════════════════════════════════════════════
%% Butler-Volmer calculation
%% ══════════════════════════════════════════════════════════════════════
% Get current SOC from interpolation function
SOC_now = param.za(timeStep);

% Map SOC back to the ECM parameter time index
time_span_param = 1:length(param.GrSi_SoC);
t_ecm   = interp1(param.GrSi_SoC, time_span_param, SOC_now, 'linear', 'extrap');
R_total = param.Rtot(t_ecm);       % [Ohm]  — ECM total resistance at this SOC
eta_now = I_total * R_total;       % [V]    — overpotential at this timestep

%% ── SOC-dependent exchange current densities ────────────────────────────
c_factor  = sqrt(SOC_now * (1 - SOC_now) + 0.01);
i0_Si_eff = i0_Si_ref * c_factor;
i0_G_eff  = i0_G_ref  * c_factor;

%% ── Butler-Volmer ───────────────────────────────────────────────────────
BV_term = exp( alpha       * F * eta_now / (R_gas * T)) - ...
          exp(-(1 - alpha) * F * eta_now / (R_gas * T));

j_Si = i0_Si_eff * BV_term;        % [A/m²]
j_G  = i0_G_eff  * BV_term;        % [A/m²]

%% ── Raw currents ────────────────────────────────────────────────────────
I_Si_raw = j_Si * a_s_Si * V_total; % [A]
I_G_raw  = j_G  * a_s_G  * V_total; % [A]

%% ── Normalize to conserve total current ────────────────────────────────
scale   = I_total / (I_Si_raw + I_G_raw);
I_Si    = I_Si_raw * scale;          % [A]
I_G     = I_G_raw  * scale;          % [A]

%% ── Current fractions ───────────────────────────────────────────────────
f_Si = I_Si / I_total;               % [-]
f_G  = I_G  / I_total;               % [-]

%% ── Store into battery_res ──────────────────────────────────────────────
battery_res.current_dist.I_Si    = I_Si;     % [A]
battery_res.current_dist.I_G     = I_G;      % [A]
battery_res.current_dist.j_Si    = j_Si;     % [A/m²]
battery_res.current_dist.j_G     = j_G;      % [A/m²]
battery_res.current_dist.frac_Si = f_Si;     % [-]
battery_res.current_dist.frac_G  = f_G;      % [-]
battery_res.current_dist.wtSi    = frac_Si;  % [-]
battery_res.current_dist.I_total = I_total;  % [A]
battery_res.current_dist.eta     = eta_now;   % [V]
battery_res.current_dist.R_total = R_total;   % [Ohm]
battery_res.current_dist.SOC     = SOC_now;   % [-]
end

