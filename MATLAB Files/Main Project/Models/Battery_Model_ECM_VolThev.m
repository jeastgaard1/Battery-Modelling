function [battery_res,options] = Battery_Model_ECM_VolThev(battery_res,param,options,step)

if options.bool.ini==1 %function called first time -> Cell states will be initialized
    %Time #################################################################
    battery_res.time(1,1)=0; %set time to 0
    
    % options.bool.ini=0; %Initilization done
else %calculation base on last value
    %time #####################################################
    battery_res.time(1,1)= step;                    %Time Variable

    [battery_res] = ThermalVSSi_Model(battery_res,param,options);
    
    [battery_res] = Current_Distribution_Model(battery_res, param, options, step);
end


end
