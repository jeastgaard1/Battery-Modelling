function dx = ECM_RC_ode(t, U_RC, param )
U_RC1 = U_RC(1);
U_RC2 = U_RC(2);

% RC Dynamics
if t <= param.time_mid
    dU_RC1 = -U_RC1 / (param.R1(t) * param.C1(t)) + param.DCH_I / param.C1(t);
    dU_RC2 = -U_RC2 / (param.R2(t) * param.C2(t)) + param.DCH_I / param.C2(t);
else
    dU_RC1 = -U_RC1 / (param.R1(t) * param.C1(t)) + param.CH_I / param.C1(t);
    dU_RC2 = -U_RC2 / (param.R2(t) * param.C2(t)) + param.CH_I / param.C2(t);
end


dx = [dU_RC1; dU_RC2];
end