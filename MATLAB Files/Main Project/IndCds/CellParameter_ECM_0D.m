function [param,const] = CellParameter_ECM_0D(options)
% Physically realistic parameter initialization for Solid Diffusion ECM 0D

%% ============================
%  Physical Constants
%  ============================
const.F = 96485.3329;   % Faraday constant [C/mol]
const.R = 8.3145;       % Gas constant [J/mol/K]

%% ============================
%  Particle Geometry
%  ============================
N = options.seg_particle;     % number of radial shells
R_p = 5e-6;                   % particle radius [m] (typical for graphite/NMC)

% Radial node positions (shell boundaries)
r_edges = linspace(0, R_p, N+1);

% Shell volumes: V = 4/3*pi*(r_outer^3 - r_inner^3)
dV = (4/3)*pi*(r_edges(2:end).^3 - r_edges(1:end-1).^3);

%% ============================
%  Diffusion Parameters
%  ============================
% Typical maximum lithium concentrations:
% Graphite: 31,000–34,000 mol/m^3
% NMC:      48,000–52,000 mol/m^3

% ---- Anode (Graphite) ----
param.ParticleDiffusion.Anode.Cmax = 32000;   % mol/m^3
param.ParticleDiffusion.Anode.Cmin = 500;     % mol/m^3 (almost delithiated)
param.ParticleDiffusion.Anode.CapaFac = 1.0;

% ---- Cathode (NMC) ----
param.ParticleDiffusion.Cathode.Cmax = 50000; % mol/m^3
param.ParticleDiffusion.Cathode.Cmin = 2000;  % mol/m^3
param.ParticleDiffusion.Cathode.CapaFac = 1.0;

%% ============================
%  Temperature‑Dependent Diffusion Time Constant τ
%  ============================
% Arrhenius-type diffusion:
% D(T) = D_ref * exp( -Ea/R * (1/T - 1/T_ref) )
% τ ~ R_p^2 / D

% Typical values:
D_ref_graphite = 1e-14;   % m^2/s at 25°C
D_ref_NMC      = 3e-15;   % m^2/s at 25°C
Ea_graphite    = 35000;   % J/mol
Ea_NMC         = 40000;   % J/mol
T_ref          = 298.15;  % K

% % Temperature scaling
% D_graphite = D_ref_graphite * exp(-Ea_graphite/const.R * (1/T - 1/T_ref));
% D_NMC      = D_ref_NMC      * exp(-Ea_NMC     /const.R * (1/T - 1/T_ref));
% 
% % τ = R_p^2 / D
% param.ParticleDiffusion.Anode.tau   = R_p^2 / D_graphite;
% param.ParticleDiffusion.Cathode.tau = R_p^2 / D_NMC;
% 
% %% ============================
% %  Assign dV
% %  ============================
% param.ParticleDiffusion.Anode.dV   = dV;
% param.ParticleDiffusion.Cathode.dV = dV;

end