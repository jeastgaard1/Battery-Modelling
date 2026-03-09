function [battery_res] = ThermalVSSi_Model(battery_res,param,options)

switch param.cRate
    case 0.1
        C_rate = 'lowC';
    case 1
        C_rate = 'midC';
    otherwise
        C_rate = 'highC';
end
T_rate = "T_" + C_rate;
TVE_rate = "TVE_" + C_rate;

timeStep = battery_res.time(1,1);

% Initialize temperature at start and when discharge changes to charge.
if ~isfield(battery_res.T, T_rate) || isempty(battery_res.T.(T_rate)) ...
        || timeStep == param.time_mid || timeStep == 1
    battery_res.T.(T_rate)(1,1) = options.ini.T;
end


% === State variables ===
T = battery_res.T.(T_rate)(1,1);

SoC = battery_res.SoC(1,1);

wtSi = param.anode.wtSi;

% === OCV and entropic coefficient ===
Uocv = param.OCV_tot(SoC, wtSi);
dUdT = param.dUdt(SoC, wtSi);

% === Current calculated in ECM ===
I = param.I(timeStep);

% === Nonlinear convection ===
hA = options.anode.hA * (1 + 0.02*(T - options.env.T_amb));

% === Thermal mass ===
Cth = param.thermal.mcp(wtSi);

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


therm_strain_L = options.materials.alpha_L*...
    (battery_res.T.(T_rate)(1,1) - options.env.T_amb);
% Thermal volumetric strain assuming isotropic expansion.
therm_strain_V = 3 * therm_strain_L;

battery_res.TVE.(TVE_rate) = therm_strain_V;

end