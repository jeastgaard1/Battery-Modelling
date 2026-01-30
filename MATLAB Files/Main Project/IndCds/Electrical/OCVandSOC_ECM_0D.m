function [battery_res,msg] = OCVandSOC_ECM_0D(battery_res,param,msg,options)


%SoC ######################################################################
if options.bool.ini==1                                                     %Initialization
    tempValue=1;
    %Cell #################################################################
    battery_res.SoC(1,1)=options.ini.SoC;                                  %Start SoC
else                                                                       %Current Intergation
    battery_res.SoC(2,1)= battery_res.SoC(1,1) ...
        +battery_res.I(1,1)*options.delta_t ...
        ./(param.Cell.C(1,1)*battery_res.Aging.SoH_C(1,1)*3600*options.Electrical.C_fac);
    tempValue=2;
end

%OCV ######################################################################
if options.bool.ini==1  
    if battery_res.P(1,1)<0                                                 %Discharge
        battery_res.OCV(1,1)=interp1(param.potentials.HC.DCH.GrSi_SoC,param.potentials.HC.DCH.GrSi_OCV,battery_res.SoC(1,1));
    else                                                                   %Charge
        battery_res.OCV(1,1)=interp1(param.potentials.HC.CH.GrSi_SoC,param.potentials.HC.CH.GrSi_OCV,battery_res.SoC(1,1));
    end
else
    if battery_res.P(1,1)<0                                           %Discharge
        battery_res.OCV(2,1)=interp1(param.potentials.HC.DCH.GrSi_SoC,param.potentials.HC.DCH.GrSi_OCV,battery_res.SoC(2,1));
    else                                                                   %Charge
        battery_res.OCV(2,1)=interp1(param.potentials.HC.CH.GrSi_SoC,param.potentials.HC.CH.GrSi_OCV,battery_res.SoC(2,1));
    end
end

%Check SoC and OCV ########################################################
if         battery_res.SoC(tempValue,1)<0 ...                                         %Saves different failures in msg
        || battery_res.SoC(tempValue,1)>1                                             %Makes it much easlier to find bugs :)
           msg.error.SOC=1;
end
if         isnan(battery_res.SoC(tempValue,1))>0 ...
        || isnan(battery_res.SoC(tempValue,1))>0
    msg.error.SOC=1;
end
if         isnan(battery_res.OCV(tempValue,1))>0
    msg.error.OCV=1;
end

end

