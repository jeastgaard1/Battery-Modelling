% Function that determines the terminal voltage of the volume dependant 2RC
% Thevian model.
function U_term = ECM_term_volt(t, U_RC, param)
% U_RC is desinged to be calculated through ODE45 using MATLAB.
U_RC1 = U_RC(1);
U_RC2 = U_RC(2);

if t <= param.time_mid
    U_term = param.UCell(t) - param.DCH_I * param.R0(t) - U_RC1 - U_RC2;
else
    U_term = param.UCell(t) - param.CH_I * param.R0(t) - U_RC1 - U_RC2;
end

end