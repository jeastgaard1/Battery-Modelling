function [battery_res,msg,options] = Battery_Model_ECM_VolThev(battery_res,param,msg,options,const)

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
    battery_res.time(2,1)=battery_res.time(1,1) + options.delta_t;                      %Time Variable
    
    %Temperature ##########################################################
    [battery_res]=ThermalModel_ECM_0D(battery_res,param,options,const);
    
    %SoC ##################################################################
    [battery_res,msg] = OCVandSOC_ECM_0D(battery_res,param,msg,options);
    
    %ECM Parameter ############################################
    [battery_res,msg] = ECM_Parameter_ECM_0D(battery_res,param,options,msg);        %Set ECM Parameter R, 1-3 RC
        
    %Interupt Simulation ##################################################
    % These lines test if the battery is fully charged/discharged.
    if battery_res.U<2.5
        msg.interupt.Umin=1;
    elseif battery_res.U>4.2
        msg.interupt.Umax=1;
    end
    
    % Transfer_Data ########################################################
    % Data in raw 2 is moved to 1, raw 2 is set to 0
    % We will keep this in case our equations call for previous values.
    [battery_res]=TransferData_ECM_0D(battery_res,options); 
end


end

%% Things to add later
    %SoH ##################################################################
    %[battery_res]=Aging_ECM_0D(battery_res,options);