function [battery_res] = Current_Distribution_Model(battery_res, param, options, timeStep)
%% ═══════════════════════════════════════════════════════════════════════
%% CURRENT DISTRIBUTION ANALYSIS (ECM + BUTLER-VOLMER)
%% ═══════════════════════════════════════════════════════════════════════
% This function calculates the current distribution between Silicon and
% Graphite in a composite anode using ECM overpotential and Butler-Volmer
% kinetics.

if timeStep ~= 1
    return;
end

%% Extract material properties from options structure
rho_Si = options.materials.rho_Si;
rho_G = options.materials.rho_G;
s_Si = options.materials.s_Si;
s_G = options.materials.s_G;
w_IM = options.materials.w_IM;

%% ── Weight fractions ────────────────────────────────────────────────────
% param.anode.wtSi is a fraction (e.g. 0.15), w_IM is in percent (e.g. 5)
% Mirror original code: work in percent space, then convert to fractions
wtSi   = param.anode.wtSi * 100;     % fraction → percent  (e.g. 0.15 → 15)
wtG    = 100 - wtSi - w_IM;          % graphite percent     (e.g. 100-15-5 = 80)

if wtG < 0
    warning('Current_Distribution_Model: invalid composition — wtG < 0 for wtSi = %.1f wt-%%', wtSi);
    return;
end

frac_Si = wtSi / 100;                % back to fraction (e.g. 0.15)
frac_G  = wtG  / 100;                % back to fraction (e.g. 0.80)

%% ── Physical constants ──────────────────────────────────────────────────
F     = options.constants.F;         % Faraday constant [C/mol]
R_gas = options.constants.R_gas;     % Gas constant [J/(mol·K)]
T     = options.ini.T;               % Temperature [K]

%% ── Densities (g/cm³ → g/m³) ───────────────────────────────────────────
rho_Si_m3 = rho_Si * 1e6;            % [g/m³]
rho_G_m3  = rho_G  * 1e6;            % [g/m³]

%% ── Kinetic parameters ──────────────────────────────────────────────────
i0_Si = options.kinetics.i0_Si;      % Si exchange current density [A/m²]
i0_G  = options.kinetics.i0_G;       % G  exchange current density [A/m²]
alpha = options.kinetics.alpha;      % Charge transfer coefficient [-]

%% ── Particle radii ──────────────────────────────────────────────────────
r_Si = options.particles.r_Si;       % [m]
r_G  = options.particles.r_G;        % [m]

%% ── Electrode porosity ──────────────────────────────────────────────────
epsilon = options.electrode.epsilon; % [-]

%% ── Mass & volume from fixed total capacity ─────────────────────────────
Q_total_fixed = options.anode.Qa;                          % [Ah]
Q_composite   = frac_Si * s_Si + frac_G * s_G;            % [mAh/g]
m_total       = Q_total_fixed * 1000 / Q_composite;        % [g]

V_Si    = frac_Si * m_total / rho_Si_m3;                   % [m³]
V_G     = frac_G  * m_total / rho_G_m3;                    % [m³]
V_total = V_Si + V_G;                                      % [m³]

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
%% SINGLE Butler-Volmer calculation
%% ══════════════════════════════════════════════════════════════════════
% eta_ref is arbitrary — BV_term is identical for both materials and
% cancels completely when normalizing. Using eta = 1 V as reference.
eta_ref = 1;  % [V]

BV_term = exp( alpha       * F * eta_ref / (R_gas * T)) - ...
          exp(-(1 - alpha) * F * eta_ref / (R_gas * T));

j_Si = i0_Si * BV_term;             % [A/m²]
j_G  = i0_G  * BV_term;             % [A/m²]

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

end

