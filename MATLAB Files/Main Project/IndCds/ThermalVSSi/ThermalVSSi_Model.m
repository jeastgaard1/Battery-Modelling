function [battery_res] = ThermalVSSi_Model(battery_res,param,options,const)

initalTemp = param.T_amb;
SoC = options.ini.SoC;
U = param.OCV_tot(SoC, 0.5);
dUdT = param.dUdt(SoC, 0.5);
I = 100; % Testing Amp
V = U - I*param.R00(0.5);

%Irreversible Heat Generation
Qirr = I*(V-U);

% Reversible (Entropic) Heat Generation
Qrev = I*initalTemp*dUdT;

% Temperature Differential Equation
battery_res.dTdt = (Qirr + Qrev - param.hA*(initalTemp - param.T_amb)) /  param.ThermCap(0.5);

% SoC differential equation
battery_res.dzdt = -I / param.Qnom;


end

