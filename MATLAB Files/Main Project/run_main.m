clear; clc;

[options, msg] = options_ECM_VolThev;

wtSi  = 0.10;
cRate = 1.0;

param = ECM_Parameter_ECM_VolThev(options, wtSi, cRate);

disp("OK: options + param created");
