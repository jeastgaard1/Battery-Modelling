function [data_save] = Volume_Expansion(data_save, param, options, step, w)

%% Material densities [g/cm³] — standard crystallographic values
rho_Si = options.materials.rho_Si;   % silicon, diamond cubic
rho_Gr = options.materials.rho_G;   % graphite

% Needs to be called after ThermalVSSi has calculated SoC.
data_save.dV_Si(step, w) = silicon_expansion(param.GrSi_SoC(step));
data_save.dV_Gr(step, w) = graphite_expansion(param.GrSi_SoC(step));

wtSi = param.anode.wtSi;

phi_Si = (wtSi / rho_Si) / (wtSi / rho_Si + (1 - wtSi) / rho_Gr);

data_save.VV0(step, w) = 1 + phi_Si .* data_save.dV_Si(step, w) + (1 - phi_Si) .* data_save.dV_Gr(step, w);

end


function dV = graphite_expansion(z)
%GRAPHITE_EXPANSION  Fractional volume change of graphite vs SOC.
%
%  All numbers derived from crystal structure:
%
%    Graphite (hexagonal layered):
%      Interlayer d-spacing:  d0  = 3.354 Angstrom
%    LiC6 (fully lithiated):
%      Interlayer d-spacing:  dLi = 3.706 Angstrom
%    In-plane a,b axes do not change => expansion is c-axis only.
%
%    Maximum expansion:
%      alpha = (dLi - d0) / d0 = (3.706 - 3.354) / 3.354 = 0.1049
%
%  Staging model (from d-spacing formula d_n = d0 + (1/n)(dLi - d0)):
%
%    Stage n  |  d_avg [A]  |  dV/V0 = (dLi-d0)/(n*d0)
%    ---------|-------------|---------------------------
%       4     |   3.442     |  2.62%
%       3     |   3.471     |  3.50%
%       2     |   3.530     |  5.25%
%       1     |   3.706     |  10.49%
%
%  Incremental volume jumps between stages:
%    empty -> stage 3:   3.50%   (grouped low-SOC transitions)
%    stage 3 -> stage 2: 1.75%
%    stage 2 -> stage 1: 5.24%
%
%  These jumps give the sigmoid weights: w_i = step_i / alpha

    d0  = 3.354;   % Angstrom — graphite interlayer spacing
    dLi = 3.706;   % Angstrom — LiC6 interlayer spacing

    alpha = (dLi - d0) / d0;   % = 0.1049  (max expansion)

    % Volume levels at each stage from d-spacing formula
    dV_stage3 = (dLi - d0) / (3 * d0);   % = 0.0350
    dV_stage2 = (dLi - d0) / (2 * d0);   % = 0.0525
    dV_stage1 = (dLi - d0) / (1 * d0);   % = 0.1049

    % Incremental steps -> sigmoid weights (derived, not fitted)
    step1 = dV_stage3;                    % empty -> stage 3  = 0.0350
    step2 = dV_stage2 - dV_stage3;        % stage 3 -> 2      = 0.0175
    step3 = dV_stage1 - dV_stage2;        % stage 2 -> 1      = 0.0524

    w1 = step1 / alpha;   % = 0.334
    w2 = step2 / alpha;   % = 0.167
    w3 = step3 / alpha;   % = 0.499

    % Sigmoid: smooth approximation of discrete phase transitions
    %   sigma(z, z0, s) = 1 / (1 + exp(-(z - z0)/s))
    %   z0 = SOC at transition centre  (from graphite phase diagram)
    %   s  = transition width           (thermal broadening)
    S = @(z, z0, s) 1 ./ (1 + exp(-(z - z0) ./ s));

    z1 = 0.12;  s1 = 0.04;   % dilute -> stage 3
    z2 = 0.50;  s2 = 0.06;   % stage 3 -> 2
    z3 = 0.90;  s3 = 0.04;   % stage 2 -> 1

    raw = w1*S(z,z1,s1) + w2*S(z,z2,s2) + w3*S(z,z3,s3);

    % Normalise so that dV(0) = 0  and  dV(1) = alpha  exactly
    r0 = w1*S(0,z1,s1) + w2*S(0,z2,s2) + w3*S(0,z3,s3);
    r1 = w1*S(1,z1,s1) + w2*S(1,z2,s2) + w3*S(1,z3,s3);

    dV = alpha * (raw - r0) / (r1 - r0);
end

function dV = silicon_expansion(z)
%SILICON_EXPANSION  Fractional volume change of silicon vs SOC.
%
%  All numbers derived from crystal structure unit cells:
%
%    Si (diamond cubic):
%      Lattice parameter a = 5.431 Angstrom
%      8 atoms per unit cell
%      Volume per Si atom: V_Si = a^3 / 8 = 20.02 A^3
%
%    Li15Si4 (BCC, fully lithiated):
%      Lattice parameter a = 10.63 Angstrom
%      4 formula units per cell = 16 Si atoms
%      Volume per Si atom: V_Li = a^3 / 16 = 75.10 A^3
%
%    Maximum expansion:
%      alpha = (V_Li - V_Si) / V_Si = (75.10 - 20.02) / 20.02 = 2.752
%
%  Two-stage lithiation process:
%    Stage 1 (z ~ 0.30): amorphous a-LixSi alloying
%      Li diffuses into Si, forms disordered alloy. ~40% of total.
%    Stage 2 (z ~ 0.75): crystalline c-Li15Si4 nucleation
%      Amorphous phase crystallises at high Li content. ~60% of total.
%
%  Sigmoid widths are broader than graphite (s = 0.08-0.10) because
%  amorphous transitions have no sharp crystallographic boundaries.

    a_Si = 5.431;    % Angstrom — Si lattice parameter
    a_Li = 10.63;    % Angstrom — Li15Si4 lattice parameter

    V_Si  = a_Si^3 / 8;     % = 20.02 A^3/atom
    V_Li  = a_Li^3 / 16;    % = 75.10 A^3/atom
    alpha = (V_Li - V_Si) / V_Si;   % = 2.752

    S = @(z, z0, s) 1 ./ (1 + exp(-(z - z0) ./ s));

    w1 = 0.40;  z1 = 0.30;  s1 = 0.10;   % amorphous a-LixSi
    w2 = 0.60;  z2 = 0.75;  s2 = 0.08;   % crystalline c-Li15Si4

    raw = w1*S(z,z1,s1) + w2*S(z,z2,s2);

    r0 = w1*S(0,z1,s1) + w2*S(0,z2,s2);
    r1 = w1*S(1,z1,s1) + w2*S(1,z2,s2);

    dV = alpha * (raw - r0) / (r1 - r0);
end