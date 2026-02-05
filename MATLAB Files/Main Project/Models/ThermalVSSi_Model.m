function [battery_res] = ThermalVSSi_Model(battery_res,param,options,timeStep,SiW,cRate,U_term)

switch cRate
    case 1
        T_rate = 'T_lowC';
    case 2
        T_rate = 'T_midC';
    otherwise
        T_rate = 'T_highC';
end

% Initialize temperature at start and when discharge changes to charge.
if ~isfield(battery_res.T, T_rate) || isempty(battery_res.T.(T_rate)) ...
        || timeStep == param.time_mid || timeStep == 1
    battery_res.T.(T_rate)(1,1) = options.ini.T;
end


% === State variables ===
T = battery_res.T.(T_rate)(1,1);

SoC = max(0,min(1,param.za(timeStep)));
battery_res.SoC(1,1) = SoC;

w = options.wtSi(SiW);

% === OCV and entropic coefficient ===
Uocv = param.OCV_tot(SoC, w);
dUdT = param.dUdt(SoC, w);

% === Current calculated in ECM ===
I = param.I(timeStep);

% === Nonlinear convection ===
hA = options.anode.hA * (1 + 0.02*(T - options.env.T_amb));

% === Thermal mass ===
Cth = param.thermal.mcp(w);

% === Irreversible heat ===
Qirr = I^2 * param.Rtot(timeStep);

% === Reversible heat ===
Qrev = I * T * dUdT;

% === Total heat balance ===
battery_res.dTdt = (Qirr + Qrev - hA*(T - options.env.T_amb)) / Cth;

% === Update temperature using timestep ===
battery_res.T.(T_rate)(1,1) = T + battery_res.dTdt * options.data.dt;

% === SoC differential equation ===
battery_res.dzdt = -I / (options.anode.Qa);

% Suggestion from TA was to -->
% Check lithiation stages ->phase changes for Gr batteries.
end