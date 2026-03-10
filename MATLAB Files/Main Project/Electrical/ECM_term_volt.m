%##########################################################################
% ECM_RC_ode:
%   Author: Joshua Eastgaard
%   Purpose: Function that determines the terminal voltage of the volume
%            dependant 2RC Thevian model.
%   Params: 
%       - t: Current time step
%       - U_RC: Array holding calculated RC voltages
%       - param: 2RC Thev param model holding calculations and params.
%%

function U_term = ECM_term_volt(t, U_RC, param)
% U_RC is desinged to be calculated through ODE45 using MATLAB.
U_RC1 = U_RC(1);
U_RC2 = U_RC(2);

I = param.I(t);

U_term = param.UCell(t) - I * param.R0(t) - U_RC1 - U_RC2;


end