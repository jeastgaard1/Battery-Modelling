clear
clc
% This code allows MATLAB to find all the required files.
addpath(genpath('IndCds'));

[options,msg]=options_ECM_0D;                      %Loads all settings: here you can set initial values, e.g. SoC
[param,const]=CellParameter_ECM_0D(options);       %Loads cell parameter
[battery_res,data_save]=structure_ECM_0D(options);% Loads final strucutre for results


%% Currenly not using, but keeping in here for now
battery_res.Aging.SoH_R(1,1)=1; %Set inital SoH values
battery_res.Aging.SoH_C(1,1)=1; %Set inital SoH values

%% Simulation Loop for 6 different wt%
for SiW = 1:6
    % Set the initial temperature.
    battery_res.T(1,1) = options.ini.T;
    % Time loop for x steps that are in options. Starts at 3, i.e. 3-2002
    for i=1:options.time_steps
        if i<100 %Taxi-out
            power=-10;
        elseif i<200
            power=-20;
        elseif i<1500
            power=-30;
        elseif i<2000
            power=30;
        else
            break;
        end
        [battery_res] = ThermalVSSi_Model(battery_res,param,options,i,SiW);
        
        if msg.interupt.Umin==1 || msg.interupt.Umax==1 %Stop simulation
            break;
        end
        
        [data_save] = SaveData(battery_res,data_save,options,i,SiW); %Save Data
        battery_res.time(1,1) = i;
        
    end
end
%% Plot data ###############################################################
figure
subplot(1,3,1)
idx = 1:7;
% --- Left axis: Temperature ---
yyaxis left
plot(data_save.time(:,1), data_save.T(:,:), 'color', [1 0 0], 'linewidth', 0.5)
ylabel('Temp [K]')
grid on

% --- Right axis: SoC ---
yyaxis right
plot(data_save.time(:,1), data_save.SoC(:,1), 'color', [0 0 1], 'linewidth', 0.8)
ylabel('SoC [-]')

xlabel('Time [min]')

subplot(1,3,2)
plot(data_save.time(idx,1), data_save.T(idx,:), 'color', [1 0 0], 'linewidth', 1.5)
grid on
grid minor
ylabel('Temp [K]')
xlabel('Time [min]')


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
