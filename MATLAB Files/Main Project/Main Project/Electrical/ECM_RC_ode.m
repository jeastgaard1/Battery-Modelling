function dx = ECM_RC_ode(t, U_RC, param )
U_RC1 = U_RC(1);
U_RC2 = U_RC(2);

I = param.I(t);

% RC Dynamics
dU_RC1 = -U_RC1 / (param.R1(t) * param.C1(t)) + I / param.C1(t);
dU_RC2 = -U_RC2 / (param.R2(t) * param.C2(t)) + I / param.C2(t);

dx = [dU_RC1; dU_RC2];
end