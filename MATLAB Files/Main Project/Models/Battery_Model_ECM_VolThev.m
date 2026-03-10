function [battery_res,options] = Battery_Model_ECM_VolThev(battery_res,param,options,step)

if options.bool.ini==1 %function called first time -> Cell states will be initialized
    %Time #################################################################
    battery_res.time(1,1)=0; %set time to 0
    
    %Temperature ##########################################################
    [battery_res]=ThermalModel_ECM_0D(battery_res,param,options,const);
    
    %SoC ##################################################################
    [battery_res,msg] = OCVandSOC_ECM_0D(battery_res,param,msg,options); 
    %[battery_res,msg] = OCVandSOC_ECM_0D_hyst(battery_res,param,msg,options); 
    
    %ECM Parameter ############################################
    [battery_res,msg] = ECM_Parameter_ECM_0D(battery_res,param,options,msg);        %Set ECM Parameter R, 1-2 RC
    
    options.bool.ini=0; %Initilization done
else %calculation base on last value
    %time #####################################################
    battery_res.time(1,1)= step;                    %Time Variable
    battery_res.SoC(1,1) = max(0,min(1,param.za(step)));
    
    [battery_res] = ThermalVSSi_Model(battery_res,param,options);
    
    [battery_res] = Current_Distribution_Model(battery_res, param, options, step);

    
    
    % Set the RC R's
    battery_res.ECM.R = param.R0(step);
    battery_res.ECM.R_RC1 = param.R1(step);
    battery_res.ECM.R_RC2 = param.R2(step);

end


end
