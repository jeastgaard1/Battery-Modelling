function U_term = ECM_term_volt(t,U_RC, param)

U_RC1 = U_RC(1);
U_RC2 = U_RC(2);

U_term = param.UCell(t) - param.I * param.R0(t) - U_RC1 - U_RC2;
end