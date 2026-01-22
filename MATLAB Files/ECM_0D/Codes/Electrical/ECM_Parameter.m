function [res,msg] = ECM_Parameter(res,param,options,i,msg)
%Actual Status:
%T=constant -> interp1
%Only cell values -> no sep,anode, cathode

% ECM Parameter ###########################################################
%EIS Charge=Discharge
%if battery_res.Cell.I(tempValue,1)>0 % Charge

%Zarc 1 & 2
for ii=1:2
    for iii=1:length(options.Names_ECM(:,1))
        battery_res.ECM.(options.Names_Elements{ii,:}).(options.Names_ECM{iii,:})(tempValue,1)= ...
            interp1(param.fit.ECM.SoC,param.fit.ECM.(options.Names_Elements{ii,:}).(options.Names_ECM{iii,:}),battery_res.Cell.SoC(tempValue,1));
        if battery_res.ECM.(options.Names_Elements{ii,:}).(options.Names_ECM{iii,:})(tempValue,1)<0 ...
                || battery_res.ECM.(options.Names_Elements{ii,:}).(options.Names_ECM{iii,:})(tempValue,1)==0 ...
                || isnan(battery_res.ECM.(options.Names_Elements{ii,:}).(options.Names_ECM{iii,:})(tempValue,1))>0
            msg.error.ECM.Zarc=1;
            battery_res.ECM.(options.Names_Elements{ii,:}).(options.Names_ECM{iii,:})(tempValue,1)=battery_res.ECM.(options.Names_Elements{ii,:}).(options.Names_ECM{iii,:})(tempValue,1).*floor(1-battery_res.ECM.(options.Names_Elements{ii,:}).(options.Names_ECM{iii,:})(tempValue,1)./abs(battery_res.ECM.(options.Names_Elements{ii,:}).(options.Names_ECM{iii,:})(tempValue,1)*1.05)) ...
                +floor(1-battery_res.ECM.(options.Names_Elements{ii,:}).(options.Names_ECM{iii,:})(tempValue,1)./abs(battery_res.ECM.(options.Names_Elements{ii,:}).(options.Names_ECM{iii,:})(tempValue,1)*1.05))*1e-3;
        end
    end
end

%WarBurg
for ii=3:3
    for iii=1:6
        battery_res.ECM.(options.Names_Elements{ii,:}).(options.Names_ECM{iii,:})(tempValue,1)= ...
            interp1(param.fit.ECM.SoC,param.fit.ECM.(options.Names_Elements{ii,:}).(options.Names_ECM{iii,:}),battery_res.Cell.SoC(tempValue,1));
        if battery_res.ECM.(options.Names_Elements{ii,:}).(options.Names_ECM{iii,:})(tempValue,1)<0 ...
                || battery_res.ECM.(options.Names_Elements{ii,:}).(options.Names_ECM{iii,:})(tempValue,1)==0 ...
                || isnan(battery_res.ECM.(options.Names_Elements{ii,:}).(options.Names_ECM{iii,:})(tempValue,1))>0
            msg.error.ECM.WarBurg=1;
            battery_res.ECM.(options.Names_Elements{ii,:}).(options.Names_ECM{iii,:})(tempValue,1)=battery_res.ECM.(options.Names_Elements{ii,:}).(options.Names_ECM{iii,:})(tempValue,1).*floor(1-battery_res.ECM.(options.Names_Elements{ii,:}).(options.Names_ECM{iii,:})(tempValue,1)./abs(battery_res.ECM.(options.Names_Elements{ii,:}).(options.Names_ECM{iii,:})(tempValue,1)*1.05)) ...
                +floor(1-battery_res.ECM.(options.Names_Elements{ii,:}).(options.Names_ECM{iii,:})(tempValue,1)./abs(battery_res.ECM.(options.Names_Elements{ii,:}).(options.Names_ECM{iii,:})(tempValue,1)*1.05))*1e-3;
        end
    end
end

%R0
battery_res.ECM.R(tempValue,1)=interp1(param.fit.ECM.SoC,param.fit.ECM.R0,battery_res.Cell.SoC(tempValue,1));
if battery_res.ECM.R(tempValue,1)<0 ...
        || battery_res.ECM.R(tempValue,1)==0 ...
        || isnan(battery_res.ECM.R(tempValue,1))>0
    msg.error.ECM.R=1;
    battery_res.ECM.R(tempValue,1)=battery_res.ECM.R(tempValue,1).*floor(battery_res.ECM.R(tempValue,1)./abs(battery_res.ECM.R(tempValue,1)*1.05)) ...
        +floor(1-battery_res.ECM.R(tempValue,1)./abs(rbattery_res.ECM.R(tempValue,1)*1.05))*1e-3;
end

end

