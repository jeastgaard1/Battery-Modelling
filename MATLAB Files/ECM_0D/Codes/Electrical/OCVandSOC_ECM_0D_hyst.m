function [battery_res,msg] = OCVandSOC_ECM_0D_hyst(battery_res,param,msg,options)

%Self Discharge ###########################################################
battery_res.I_self(1,1)=0;

%SoC ######################################################################
if options.bool.ini==1                                                     %Initialization
    tempValue=1;
    %Cell #################################################################
    battery_res.SoC(1,1)=options.ini.SoC;                                  %Start SoC
else                                                                       %Current Intergation
    battery_res.SoC(2,1)= battery_res.SoC(1,1) ...
        +(battery_res.I(1,1)+battery_res.I_self(1,1))*options.delta_t ...
        ./(param.Cell.C(1,1)*battery_res.Aging.SoH_C(1,1)*3600*options.Electrical.C_fac);
    tempValue=2;
end

%OCV ######################################################################
if options.bool.ini==1
    battery_res.OCV_DCH(tempValue,1)=interp1(param.fit.OCV.DCH.SoC,param.fit.OCV.DCH.U,battery_res.SoC(tempValue,1)); 
    battery_res.OCV_CH(tempValue,1)=interp1(param.fit.OCV.CH.SoC,param.fit.OCV.CH.U,battery_res.SoC(tempValue,1));
else
    battery_res.OCV_DCH(tempValue,1)=interp1(param.fit.OCV.DCH.SoC,param.fit.OCV.DCH.U,battery_res.SoC(tempValue,1));                                                       %Charge
    battery_res.OCV_CH(tempValue,1)=interp1(param.fit.OCV.CH.SoC,param.fit.OCV.CH.U,battery_res.SoC(tempValue,1)); 
end

battery_res.OCV_mean(tempValue,1)=(battery_res.OCV_DCH(tempValue,1)+battery_res.OCV_CH(tempValue,1))/2; 
battery_res.H(tempValue,1)=abs(battery_res.OCV_DCH(tempValue,1)-battery_res.OCV_CH(tempValue,1))/2;
battery_res.tau_hyst(tempValue,1)=10;%not fitted right now

%Hysteresis ###############################################################
if options.bool.ini==1 
    if battery_res.P(1,1)<0%Discharge
        battery_res.h(tempValue,1)=1; %Start @Ch curve
    else
        battery_res.h(tempValue,1)=-1; %Start @Dch curve
    end
else
    if battery_res.P(1,1)<0%Discharge
        battery_res.h(tempValue,1)=1-(1-battery_res.h(1,1))*exp(-options.delta_t/battery_res.tau_hyst(tempValue,1)); 
    else
        battery_res.h(tempValue,1)=-1+(1+battery_res.h(1,1))*exp(-options.delta_t/battery_res.tau_hyst(tempValue,1)); 
    end
end
battery_res.OCV(tempValue,1)=battery_res.OCV_mean(tempValue,1)+battery_res.H(tempValue,1)*battery_res.h(tempValue,1);

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

