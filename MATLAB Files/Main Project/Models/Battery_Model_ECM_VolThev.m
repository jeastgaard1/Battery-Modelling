function [battery_res,options] = Battery_Model_ECM_VolThev(battery_res,param,options,step)

if options.bool.ini==1 %function called first time -> Cell states will be initialized
    %Time #################################################################
    battery_res.time(1,1)=0; %set time to 0
    
    options.bool.ini=0; %Initilization done
else %calculation base on last value
    %time #####################################################
    battery_res.time(1,1)= step;                    %Time Variable

    [battery_res] = ThermalVSSi_Model(battery_res,param,options);
    % Transfer_Data ########################################################
    % Data in raw 2 is moved to 1, raw 2 is set to 0
    % We will keep this in case our equations call for previous values.
    % [battery_res]=TransferData_ECM_0D(battery_res,options); 
end


end
