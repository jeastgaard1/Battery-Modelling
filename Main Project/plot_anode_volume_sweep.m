%% plot_anode_volume_sweep.m
clear; clc; close all;

%% 1) Build options
[options, msg] = options_ECM_VolThev;

%% 2) Choose 4 variations each
wtSi_list = options.wtSi;
eps0_list = [0.25 0.35 0.45 0.55];
cRate = 1.0;

%% 3) Porosity mapping parameters
use_pore_closure = true;   % keep Option 1 (no negative swelling)
eps_min = 0.05;
gamma   = 1.0;

%% 4) Get SOC trajectory from your ECM param function
param0 = ECM_Parameter_ECM_VolThev(options, wtSi_list(1), cRate);

N = numel(param0.NMC_OCV);
t = 1:N;

za = arrayfun(param0.za, t);
za = max(0, min(1, za));   % clamp into [0,1]

%% 5) Helper function handle (matches localVnorm signature)
Vnorm_from = @(z, wtSi, eps0) localVnorm(z, wtSi, eps0, eps_min, gamma, use_pore_closure);

%% (A) For each wtSi: vary porosity
for i = 1:numel(wtSi_list)
    wtSi = wtSi_list(i);

    figure('Name', sprintf('VVsSOC_wtSi=%.2f', wtSi));
    hold on; grid on;

    for j = 1:numel(eps0_list)
        eps0 = eps0_list(j);
        Vnorm = Vnorm_from(za, wtSi, eps0);
        plot(za, Vnorm, 'LineWidth', 2);
    end

    xlabel('Anode SOC z_a [-]');
    ylabel('Normalized anode volume V/V_0 [-]');
    title(sprintf('Anode V/V0 vs SOC | wtSi=%.2f (SiGr mixture)', wtSi));
    legend(compose('\\epsilon_0=%.2f', eps0_list), 'Location', 'best');
end

%% (B) For each porosity: vary wtSi
for j = 1:numel(eps0_list)
    eps0 = eps0_list(j);

    figure('Name', sprintf('VVsSOC_eps0=%.2f', eps0));
    hold on; grid on;

    for i = 1:numel(wtSi_list)
        wtSi = wtSi_list(i);
        Vnorm = Vnorm_from(za, wtSi, eps0);
        plot(za, Vnorm, 'LineWidth', 2);
    end

    xlabel('Anode SOC z_a [-]');
    ylabel('Normalized anode volume V/V_0 [-]');
    title(sprintf('Anode V/V0 vs SOC | Porosity \\epsilon_0=%.2f', eps0));
    legend(compose('wtSi=%.2f', wtSi_list), 'Location', 'best');
end

%% (C) One "cycle" plot vs time index
wtSi_demo = wtSi_list(end);
eps0_demo = eps0_list(2);

Vcycle = Vnorm_from(za, wtSi_demo, eps0_demo);

figure('Name', 'VVsTime_cycle');
plot(t, Vcycle, 'LineWidth', 2); grid on;
xlabel('time index t [-]');
ylabel('Normalized anode volume V/V_0 [-]');
title(sprintf('Expansion then contraction | wtSi=%.2f, \\epsilon_0=%.2f', wtSi_demo, eps0_demo));

%% ---------- local function (staged sigmoid swelling) ----------
function Vnorm = localVnorm(z, wtSi, eps0, eps_min, gamma, use_pore_closure)
    z = max(0, min(1, z));

    S = @(z,z0,s) 1 ./ (1 + exp(-(z - z0)./s));

    % Graphite-like staged swelling
    A_Gr = 0.030;
    g1 = 0.60 * S(z, 0.28, 0.04);
    g2 = 0.40 * S(z, 0.82, 0.06);
    dV_Gr = A_Gr * (g1 + g2);

    % Silicon-like staged swelling
    A_Si = 0.30;
    s1 = 0.30 * S(z, 0.30, 0.05);
    s2 = 0.70 * S(z, 0.88, 0.05);
    dV_Si = A_Si * (s1 + s2);

    % SiGr mixture
    dV_mix = (1 - wtSi).*dV_Gr + wtSi.*dV_Si;

    % Porosity mapping
    phi_s = max(0, 1 - eps0);
    dV_solid = phi_s * gamma .* dV_mix;

    % Allow some visible swelling before pores fully collapse
    k_vis = 0.25;

    if use_pore_closure
        buffer = max(0, eps0 - eps_min);
        dV_ext = k_vis*dV_solid + max(0, (1-k_vis)*dV_solid - buffer);
    else
        dV_ext = dV_solid;
    end

    Vnorm = 1 + max(0, dV_ext);   % Option 1: never below baseline
end
