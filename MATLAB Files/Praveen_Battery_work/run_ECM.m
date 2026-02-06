%##########################################################################
%
% General points
% === Electro-chemical ===============================
% Full Cell ECM: OCV + R(Si_t) + RC1(Si_t) + RC2(Si_t)
% Expansion based on GrSi anode
% ====================================================
%
% === Thermal: ===
% Irreversible Heat
% Reversible Heat
% Cooling
% =================
%
% === Mechanical: ====
% Reversible Expansion
% ====================
%
% === Parametrization =======================
% <TODO> Still need to parameratize based on
% a specific cell type that is chosen.
% ===========================================
% 
% === Structure====================================================
% run main file: "run_ECM"
% -options:         loads all set options
% -cell parameters: loads parametrization & data of considered cell
% =================================================================
%%

clear
clc

% This code allows MATLAB to find all the required files.
addpath(genpath('Models'));
addpath(genpath('Electrical'));

[options,msg] = options_ECM_VolThev; % Loads all settings

% [param] = ECM_Parameter_ECM_VolThev(options, 0, 0); % Loads cell parameter with 0 % Si
[battery_res, data_save] = structure_ECM_2RC_VolThev(options);% Loads final strucutre for results

% Setting initial values
battery_res.T.T_lowC(1,1) = options.ini.T;
battery_res.T.T_midC(1,1) = options.ini.T;
battery_res.T.T_highC(1,1) = options.ini.T;

battery_res.Aging.SoH_R(1,1)=1; %Set inital SoH values
battery_res.Aging.SoH_C(1,1)=1; %Set inital SoH values

%% ODE for Terminal Voltage
for cr = 1:length(options.cRates)
    figure; hold on;
    for w = 1:length(options.wtSi) % Loop through different Si%
        % Creating new parameters every time with different cell (wt%) and
        % C-Rates for simulation. Redundant/expensive but simple solution.        
        [param]=ECM_Parameter_ECM_VolThev(options,options.wtSi(w),options.cRates(cr));
        fprintf("Running with Si wt%% = %.2f'\n", param.anode.wtSi);
        
        % Set up ODE equation
        x0 = [0; 0];
        ode_function = @(t,x) ECM_RC_ode(t, x, param);
        %ode15s is used for stiff simulation if we want to exagerate values.
        % ode45 is used for non-stiff simulation (but slower sim time).
        [t_sim, u_sim] = ode15s(ode_function, options.time_span, x0); 
        % Compute terminal voltage
        V_sim = zeros(size(t_sim));
        
        for k = 1:numel(t_sim)
            V_sim(k) = ECM_term_volt(t_sim(k), u_sim(k,:).', param);
            % This Battery_Model is where all models will be called each loop.
            % [battery_res,msg,options] = Battery_Model_ECM_VolThev(battery_res,param,msg,options,const); %Cell ECM Model
            [battery_res] = ThermalVSSi_Model(battery_res,param,options,k,w,cr);
            
            % After every model generation, data will need to be saved so
            % that it can be plotted later.
            [data_save] = SaveData(battery_res,data_save,options,k,w,cr); %Save Data
            battery_res.time(1,1) = k;
        end
    
        % Plot
        plot(t_sim, V_sim, 'LineWidth', 2, ...
             'DisplayName', sprintf('Si wt%% = %.2f', options.wtSi(w)));
    
    end
    xlabel('Time [min]');
    ylabel('Terminal Voltage [V]');
    title(sprintf('GrSi ECM Simulation with differnt Si.-wt%% ( C-Rate of %.1f)',options.cRates(cr)));
    grid on;                         
    legend('show');
end
%% Plot Save_Data
% Same as above, we need to plot different wt% for each C-Rate.
for cr = 1:length(options.cRates)

    figure; hold on; grid on;

    % Time vector for discharge/charge for plotting
    t_sim_DCH = data_save.time(1:param.time_mid - 1,1);
    t_sim_CH = data_save.time(param.time_mid : options.data.steps,1);

    % Colors for wt% curves
    cmap = [
        0.85 0.33 0.10;   % orange
        0.93 0.69 0.13;   % yellow-gold
        0.49 0.18 0.56;   % purple
        0.47 0.67 0.19;   % olive green
        0.64 0.08 0.18    % dark red
    ];

    % Temperature axis (left)
    yyaxis left;
    subplot(1,2,1);
    hold on;

    for w = 1:length(options.wtSi)
        plot(t_sim_DCH, ...
             data_save.T.(options.Save.T{cr})(1:param.time_mid - 1,w), ...
             'Color', cmap(w,:), ...
             'LineWidth', 1.5, ...
             'DisplayName', sprintf('Si wt%% = %.2f', options.wtSi(w)));        
    end

    % SoC axis (right)
    yyaxis right

    plot(t_sim_DCH, data_save.SoC(1 : param.time_mid - 1,1), ...
         'Color', [0 0.45 0.70], ...   % strong blue
         'LineWidth', 2, ...
         'DisplayName', 'SoC');
    xlim([min(t_sim_DCH) max(t_sim_DCH)])
    ylabel('State of Charge [-]');
    ylabel('Temperature [K]');
    xlabel('Time [min]');
    title(sprintf('Thermal & SoC Evolution at %.1fC Discharge', options.cRates(cr)));
    legend('Location','best');

    % Temperature axis (left)
    yyaxis left;
    subplot(1,2,2);
    hold on;
    for w = 1:length(options.wtSi)
        plot(t_sim_CH, ...
             data_save.T.(options.Save.T{cr})(param.time_mid : options.data.steps,w), ...
             'Color', cmap(w,:), ...
             'LineWidth', 1.5, ...
             'DisplayName', sprintf('Si wt%% = %.2f', options.wtSi(w)));
    end
    ylabel('Temperature [K]')
   

    % SoC axis (right)
    yyaxis right
    plot(t_sim_CH, data_save.SoC(param.time_mid : options.data.steps,1), ...
         'Color', [0 0.45 0.70], ...   % strong blue
         'LineWidth', 2, ...
         'DisplayName', 'SoC');
    xlim([min(t_sim_CH) max(t_sim_CH)])
    ylabel('State of Charge [-]');
    ylim([0 1]);
    xlabel('Time [min]');
    title(sprintf('Thermal & SoC Evolution at %.1fC Charge', options.cRates(cr)));
    legend('Location','best');
end