%##########################################################################
%General points
%Electro-chemical / Electrical:
%Full Cell ECM: OCV + R + RC_1 + RC2 + RC3
%Single Point for whole Cell

%Thermal:
%Irreversible Heat
%Reversible Heat
%Cooling

%Mechanical:
%Single Particle -> Solid Diffusion
%Reversible Expansion
%Rheological Model: noch nicht implementiert

%Aging: noch nicht implementiert
%SoHR & SoHC, Weighted Amperehour model

%Parametrization ##########################################################
%Based on Samsung 50S

%Structure ################################################################

%run main file: "run_ECM"
% -options:         loads all set options
% -cell parameters: loads parametrization & data of considered cell
%
%%
clear
clc
% This code allows MATLAB to find all the required files.
addpath(genpath('Models'));

[options,msg]=options_ECM_VolThev %Loads all settings

[param]=ECM_Parameter_ECM_VolThev(options,0,0); %Loads cell parameter with 0% Si
[battery_res,data_save]=structure_ECM_2RC_VolThev(options);%Loads final strucutre for results

battery_res.Aging.SoH_R(1,1)=1; %Set inital SoH values
battery_res.Aging.SoH_C(1,1)=1; %Set inital SoH values



%% To be implimented later on. This will be the main simulation center.
% for i=1:options.data.steps
%     [battery_res,msg,options] = Battery_Model_ECM_VolThev(battery_res,param,msg,options,const); %Cell ECM Model
% 
%     if msg.interupt.Umin==1 || msg.interupt.Umax==1 %Stop simulation
%         break;
%     end
% 
%     [data_save] = SaveData(battery_res,data_save,options,i); %Save Data
% 
% end

%% ODE for Terminal Voltage
for cr = 1:length(options.cRates)
    figure; hold on;
    for w = 1:length(options.wtSi) % Loop through different Si%
        % Creating new parameters every time with different cell (wt%) and
        % C-Rates for simulation.
        [param]=ECM_Parameter_ECM_VolThev(options,options.wtSi(w),options.cRates(cr));
    
        fprintf("Running with Si wt%% = %.2f'\n", param.anode.wtSi);
        
        % Set up ODE equation
        x0 = [0; 0];
        ode_function = @(t,x) ECM_RC_ode(t, x, param);
        [t_sim, u_sim] = ode45(ode_function, options.time_span, x0); %ode15s is used for stiff simulation if we want to exagerate values.
        % Compute terminal voltage
        V_sim = zeros(size(t_sim));
        for k = 1:numel(t_sim)
            V_sim(k) = ECM_term_volt(t_sim(k), u_sim(k,:).', param);
        end
    
        % Plot
        plot(options.time_vec, V_sim, 'LineWidth', 2, ...
             'DisplayName', sprintf('Si wt%% = %.2f', options.wtSi(w)));
    
    end
    xlabel('Time [min]');
    ylabel('Terminal Voltage [V]');
    title(sprintf('GrSi ECM Simulation with differnt Si.-wt%% ( C-Rate of %.1f)',options.cRates(cr)));
    grid on;
    legend('show');
end
% %% Plot data ###############################################################
% figure
% subplot(1,3,1)
% plot(data_save.time,data_save.U,'--*','color',[0 0 0],'linewidth',1.5)
% hold on
% plot(data_save.time,data_save.OCV,'color',[0.9 0.9 0.9],'linewidth',1.5)
% plot(data_save.time,data_save.OCV+data_save.ECM.U_RC1,'color',[0.7 0.7 0.7],'linewidth',1.5)
% plot(data_save.time,data_save.OCV+data_save.ECM.U_RC1+data_save.ECM.U_RC2,'color',[0.5 0.5 0.5],'linewidth',1.5)
% plot(data_save.time,data_save.OCV+data_save.ECM.U_RC1+data_save.ECM.U_RC2+data_save.ECM.U_RC3,'color',[0.3 0.3 0.3],'linewidth',1.5)
% grid on
% grid minor
% xlabel('Time [s]')
% ylabel('U [V]')
% 
% subplot(1,3,2)
% plot(data_save.time,data_save.I,'color',[1 0 0],'linewidth',1.5)
% grid on
% grid minor
% xlabel('Time [s]')
% ylabel('I [A]')
% 
% subplot(1,3,3)
% plot(data_save.time,data_save.P,'color',[0 0 1],'linewidth',1.5)
% hold on
% grid on
% grid minor
% xlabel('Time [s]')
% ylabel('P [W]')
% 
% %% Plot Partcile v2 Li concentration three thickness points, one segment
% %Anode
% aufloesung=100;
% time_step=1999;
% [p,t]=meshgrid(linspace(-pi,pi,aufloesung),linspace(0,pi,options.seg_particle));
% X=cos(p).*t;
% Y=sin(p).*t;
% 
% Z=zeros(options.seg_particle,aufloesung);
% for i=1:aufloesung
%     Z(:,i)=data_save.Particle.c_Li_Cathode(time_step,:);
% end
% Eval.Li_Distribution.Anode.x=X;
% Eval.Li_Distribution.Anode.y=Y;
% Eval.Li_Distribution.Anode.Li=Z;
% figure
% surf(Eval.Li_Distribution.Anode.x,Eval.Li_Distribution.Anode.y,Eval.Li_Distribution.Anode.Li,'EdgeColor','none')
% colorbar('southoutside');
% %caxis([Eval.Li_Distribution.Anode.legendmin Eval.Li_Distribution.Anode.legendmax])
% axis off