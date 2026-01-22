function [battery_res] = ThermalModel_ECM_0D(battery_res,param,options,const)


if options.bool.ini==1                                                             %Initilaization
    battery_res.T(1,1)=options.ini.T;
elseif options.bool.Thermal==0 
    battery_res.T(2,1)=options.ini.T;
else
    %Reversible & Irreversible heat; Cooling Power
    %T=T_0 + 1/(m Cp) int(Q_rev + Qirr + Qcool)dt 
    
    battery_res.Q_irr(1,1)=(battery_res.U(1,1) - battery_res.OCV(1,1)).*battery_res.I(1,1);%Irreversible
    battery_res.Q_rev(1,1)=battery_res.T(1,1)*battery_res.I(1,1)*battery_res.Entropy(1,1) ...
        /(const.F*const.z);                                                %Reversible
    battery_res.Q_cooling(1,1)=options.Thermal.coolingPower;               %coolingPower in [W]
    
    battery_res.T(2,1)=battery_res.T(1,1) ...
        + 1/(param.thermal.mcp) ...
        *(battery_res.Q_irr(1,1) ...
        +battery_res.Q_rev(1,1) ...
        +battery_res.Q_cooling(1,1)) ...
        *options.delta_t;
end


end

