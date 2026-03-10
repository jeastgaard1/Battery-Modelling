function [battery_res,options] = Battery_Model_ECM_VolThev(battery_res,param,options,step)

    battery_res.time(1,1)= step; %Time Variable for all models
    battery_res.SoC(1,1) = max(0,min(1,param.za(step)));
    
    % Set the RC R's so every model has access.
    battery_res.ECM.R = param.R0(step);
    battery_res.ECM.R_RC1 = param.R1(step);
    battery_res.ECM.R_RC2 = param.R2(step);
    
    [battery_res] = ThermalVSSi_Model(battery_res,param,options);
    
    [battery_res] = Current_Distribution_Model(battery_res, param, options, step);
    
    

end
