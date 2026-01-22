function [battery_res] = Overvoltage_ECM_0D(battery_res,options)

if options.bool.ini==1                                                     %Initialization
    tempValue=1;
else
    tempValue=2;
end

if options.bool.EIS==0
    %% Determine Overvoltages #################################################
    if tempValue==1                                                                    %Initialization
        battery_res.ECM.U_RC1(tempValue,1)=0;                                                  % Relaxed State all dynamic voltages zeros
        battery_res.ECM.U_RC2(tempValue,1)=0;                                                  % Relaxed State all dynamic voltages zeros
        battery_res.ECM.U_RC3(tempValue,1)=0;                                                  % Relaxed State all dynamic voltages zeros
    else
        
        %RC1
        battery_res.ECM.U_RC1(tempValue,1)= ...
            (battery_res.ECM.U_RC1(tempValue-1,1) - battery_res.I(tempValue-1,1).*battery_res.ECM.R_RC1(tempValue,1)) ...
            .*exp(-options.delta_t./battery_res.ECM.tau_RC1(tempValue,1)) ...
            +battery_res.I(tempValue-1,1).*battery_res.ECM.R_RC1(tempValue,1);
        
        %RC2
        battery_res.ECM.U_RC2(tempValue,1)= ...
            (battery_res.ECM.U_RC2(tempValue-1,1) - battery_res.I(tempValue-1,1).*battery_res.ECM.R_RC2(tempValue,1)) ...
            .*exp(-options.delta_t./battery_res.ECM.tau_RC2(tempValue,1)) ...
            +battery_res.I(tempValue-1,1).*battery_res.ECM.R_RC2(tempValue,1);
        
        %RC3
        battery_res.ECM.U_RC3(tempValue,1)= ...
            (battery_res.ECM.U_RC3(tempValue-1,1) - battery_res.I(tempValue-1,1).*battery_res.ECM.R_RC3(tempValue,1)) ...
            .*exp(-options.delta_t./battery_res.ECM.tau_RC3(tempValue,1)) ...
            +battery_res.I(tempValue-1,1).*battery_res.ECM.R_RC3(tempValue,1);
    end
    
    %% Add to volatge source ##################################################
    
    battery_res.ECM.Usc(tempValue,1)= ...
        battery_res.OCV(tempValue,1) ...
        +battery_res.ECM.U_RC1(tempValue,1) ...
        +battery_res.ECM.U_RC2(tempValue,1) ...
        +battery_res.ECM.U_RC3(tempValue,1) ...
        ;
else % EIS Data ###########################################################
    if tempValue==1
        for ii=1:length(options.Names_Elements(:,1))
            battery_res.ECM.(options.Names_Elements{ii,:}).U(tempValue,1)=0;
        end
        %Zarc1 & 2
        for ii=1:2
            for iii=1:length(options.Names_ECM_U(:,1))
                battery_res.ECM.(options.Names_Elements{ii,:}).(options.Names_ECM_U{iii,:})(tempValue,1)= ...
                    0;
            end
        end
        
        %Warburg
        for ii=3:3
            for iii=1:3
                battery_res.ECM.(options.Names_Elements{ii,:}).(options.Names_ECM_U{iii,:})(tempValue,1)= ...
                    0;
            end
        end
    else
        %Zarc1 & 2
        for ii=1:2
            battery_res.ECM.(options.Names_Elements{ii,:}).U(tempValue,1)=0;
            for iii=1:length(options.Names_ECM_U(:,1))
                battery_res.ECM.(options.Names_Elements{ii,:}).(options.Names_ECM_U{iii,:})(tempValue,1)= ...
                    (battery_res.ECM.(options.Names_Elements{ii,:}).(options.Names_ECM_U{iii,:})(tempValue-1,1) - battery_res.I(tempValue-1,1).*battery_res.ECM.(options.Names_Elements{ii,:}).(options.Names_ECM{iii*2,:})(tempValue,1) ) ...
                    .*exp(-options.delta_t./battery_res.ECM.(options.Names_Elements{ii,:}).(options.Names_ECM{(iii*2)-1,:})(tempValue,1)) ...
                    +battery_res.I(tempValue-1,1).*battery_res.ECM.(options.Names_Elements{ii,:}).(options.Names_ECM{iii*2,:})(tempValue,1);
                
                battery_res.ECM.(options.Names_Elements{ii,:}).U(tempValue,1)=battery_res.ECM.(options.Names_Elements{ii,:}).U(tempValue,1) ...
                    +battery_res.ECM.(options.Names_Elements{ii,:}).(options.Names_ECM_U{iii,:})(tempValue,1);
            end
        end
        
        %WarBurg
        for ii=3:3
            battery_res.ECM.(options.Names_Elements{ii,:}).U(tempValue,1)=0;
            for iii=1:3
                battery_res.ECM.(options.Names_Elements{ii,:}).(options.Names_ECM_U{iii,:})(tempValue,1)= ...
                    (battery_res.ECM.(options.Names_Elements{ii,:}).(options.Names_ECM_U{iii,:})(tempValue-1,1) - battery_res.I(tempValue-1,1).*battery_res.ECM.(options.Names_Elements{ii,:}).(options.Names_ECM{iii*2,:})(tempValue,1) ) ...
                    .*exp(-options.delta_t./battery_res.ECM.(options.Names_Elements{ii,:}).(options.Names_ECM{(iii*2)-1,:})(tempValue,1)) ...
                    +battery_res.I(tempValue-1,1).*battery_res.ECM.(options.Names_Elements{ii,:}).(options.Names_ECM{iii*2,:})(tempValue,1);
                
                battery_res.ECM.(options.Names_Elements{ii,:}).U(tempValue,1)=battery_res.ECM.(options.Names_Elements{ii,:}).U(tempValue,1) ...
                    +battery_res.ECM.(options.Names_Elements{ii,:}).(options.Names_ECM_U{iii,:})(tempValue,1);
            end
        end
    end
    
    battery_res.ECM.Usc(tempValue,1)=battery_res.OCV(tempValue,1);
    for ii=1:length(options.Names_Elements(:,1))
        battery_res.ECM.Usc(tempValue,1)=battery_res.ECM.Usc(tempValue,1)+res.ECM.(options.Names_Elements{ii,:}).U(tempValue,1);
    end
end

%% Determine Cell Current #################################################
% P = U * I
% U = Usc + R*I
% P = Usc*I + R*I^2
% R * I^2 + Usc * I - P = 0
% I = -Usc/(2R) + sqrt( Usc^2 + 4 R * P )/2R

% Determine I based on this function:
battery_res.I(tempValue,1)=-battery_res.ECM.Usc(tempValue,1)/(2*battery_res.ECM.R(tempValue,1)) ...
    +sqrt( battery_res.ECM.Usc(tempValue,1)^2 + 4*battery_res.ECM.R(tempValue,1)*battery_res.P(tempValue,1))/(2*battery_res.ECM.R(tempValue,1));

% Determine ohmic loss and cell voltage:
battery_res.ECM.U_R(tempValue,1)=battery_res.I(tempValue,1)*battery_res.ECM.R(tempValue,1);
battery_res.U(tempValue,1)=battery_res.ECM.Usc(tempValue,1)+battery_res.ECM.U_R(tempValue,1);
battery_res.P_control(tempValue,1)=battery_res.U(tempValue,1)*battery_res.I(tempValue,1);

%Determine Charge Throughput:
if options.bool.ini==1
    battery_res.Q(1,1)=abs(battery_res.I(tempValue,1))*options.delta_t;
else
    battery_res.Q(1,1)=battery_res.Q(1,1)+abs(battery_res.I(tempValue,1))*options.delta_t;
end

end

