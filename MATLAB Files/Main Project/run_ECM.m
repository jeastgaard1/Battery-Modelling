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
if options.bool.ini == 1
    battery_res.T.T_lowC(1,1) = options.ini.T;
    battery_res.T.T_midC(1,1) = options.ini.T;
    battery_res.T.T_highC(1,1) = options.ini.T;
    battery_res.V00 = 1;
end

battery_res.Aging.SoH_R(1,1)=1; %Set inital SoH values
battery_res.Aging.SoH_C(1,1)=1; %Set inital SoH values

%% Solve for Volume expansion vs SoC
for w = 1:length(options.wtSi)
    [param]=ECM_Parameter_ECM_VolThev(data_save, options, w,options.cRates(2));
    for step = 1:length(param.NMC_OCV(:,1))
        [data_save] = Volume_Expansion(data_save, param, options, step, w );
        
    end
end

%% ODE for Terminal Voltage
for cr = 1:length(options.cRates)
    figure; hold on;
    for w = 1:length(options.wtSi) % Loop through different Si%
        % Creating new parameters every time with different cell (wt%) and
        % C-Rates for simulation. Redundant/expensive but simple solution.  
        %options.bool.ini = 1; 
        [param]=ECM_Parameter_ECM_VolThev(data_save,options, w, options.cRates(cr));
        
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
            [battery_res,options] = Battery_Model_ECM_VolThev(battery_res,param,options,k); %Cell ECM Model
            
            % Calcuate volumetric capacitry for the first C-Rate after
            % first run has been completed.
            if cr == 1 && k == 1
                battery_res.vol_cap = Volumetric_Capacity_Model(param, options);
            end
            
            % After every model generation, data will need to be saved so
            % that it can be plotted later.
            [data_save] = SaveData(battery_res, data_save, options, k, w, cr);
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

%% ═══════════════════════════════════════════════════════════════════════
%% PLOT CURRENT DISTRIBUTION FOR ALL C-RATES 
%% ═══════════════════════════════════════════════════════════════════════
figure('Position', [100, 100, 1200, 400]);
set(gcf, 'Color', 'w');

for cr = 1:length(options.cRates)
    subplot(1, length(options.cRates), cr);

    % data_save.current_dist.I_Si is (n_time x n_wtSi x n_cRates)
    % All time rows are identical (time-invariant), so take row 1
    n_rows        = size(data_save.current_dist.I_Si, 1);
    snap_row      = max(2, round(n_rows / 2));
    I_Si_snapshot = squeeze(data_save.current_dist.I_Si(snap_row, :, cr)) * 1000;  % [mA]
    I_G_snapshot  = squeeze(data_save.current_dist.I_G(snap_row, :, cr))  * 1000;  % [mA]

    b = bar([I_G_snapshot; I_Si_snapshot]', 'grouped');
    b(1).FaceColor = [0.47 0.67 0.19];  % Graphite
    b(2).FaceColor = [0.85 0.33 0.10];  % Silicon

    set(gca, 'XTickLabel', arrayfun(@(x) sprintf('%.0f%%', x*100), options.wtSi, 'UniformOutput', false));
    xlabel('Si Content [wt-%]', 'FontSize', 11, 'FontWeight', 'bold');
    ylabel('Current [mA]',      'FontSize', 11, 'FontWeight', 'bold');
    title(sprintf('C-Rate %.1f', options.cRates(cr)), 'FontSize', 12, 'FontWeight', 'bold');

    if cr == 1
        legend('Graphite', 'Silicon', 'Location', 'best');
    end
    grid on;
end

sgtitle('Current Distribution vs Silicon Content', 'FontSize', 16, 'FontWeight', 'bold');

%% ═══════════════════════════════════════════════════════════════════════
%% PLOT VOLUMETRIC CAPACITY CASE STUDIES 
%% ═══════════════════════════════════════════════════════════════════════
% fprintf('\n');
% fprintf('═══════════════════════════════════════════════════════════════\n');
% fprintf('  PLOTTING VOLUMETRIC CAPACITY CASE STUDIES\n');
% fprintf('═══════════════════════════════════════════════════════════════\n\n');

%Extract data for FIRST C-rate only 
%data_save.vol_cap is now a struct
wtSi_array    = data_save.vol_cap.wtSi;
G_A_array     = data_save.vol_cap.G_A;
V_A_case1     = data_save.vol_cap.case1.V_A;
P_A_req_case1 = data_save.vol_cap.case1.P_A_required;
%% ═══════════════════════════════════════════════════════════════════════
%% FIGURE 1: CASE STUDY 1 - Zero Expansion (E=0 & P_ALi=0)
%% ═══════════════════════════════════════════════════════════════════════
figure('Position', [100, 100, 1200, 700]);
set(gcf, 'Color', 'w');

% Left Y-axis: Volumetric and Gravimetric Capacity
yyaxis left;
hold on; grid on; box on;

% Plot Volumetric Capacity (Red)
plot(wtSi_array, V_A_case1, '-', 'LineWidth', 3, ...
     'Color', [0.85 0.33 0.10], 'DisplayName', 'V_A (Si/Graphite)');

% Plot Gravimetric Capacity (Green)
plot(wtSi_array, G_A_array, '-', 'LineWidth', 3, ...
     'Color', [0.47 0.67 0.19], 'DisplayName', 'G_A (Si/Graphite)');

ylabel('Specific Capacity V_A in mAh/cm^3 & G_A in mAh/g', ...
       'FontSize', 12, 'FontWeight', 'bold');
ylim([0, 3500]);
set(gca, 'YColor', 'k');

% Right Y-axis: Initial Porosity
yyaxis right;
hold on;

% Plot Required Porosity (Blue)
plot(wtSi_array, P_A_req_case1, '-', 'LineWidth', 3, ...
     'Color', [0.00 0.45 0.74], 'DisplayName', 'P_A (Si/Graphite)');

% Mark P_A = 30% intersection (black square)
P_A_target = 30;
idx_30 = find(P_A_req_case1 >= P_A_target, 1, 'first');
if ~isempty(idx_30)
    plot(wtSi_array(idx_30), P_A_target, 'ks', ...
         'MarkerSize', 12, 'MarkerFaceColor', 'k', 'DisplayName', 'data1');
    
    % Vertical dashed line at this Si%
    xline(wtSi_array(idx_30), '--k', 'LineWidth', 1.5);
    
    % Horizontal dashed line at P_A = 30%
    yline(P_A_target, '--k', 'LineWidth', 1.5);
end

ylabel('Initial electrode porosity P_A (vol-%)', ...
       'FontSize', 12, 'FontWeight', 'bold');
ylim([0, 100]);
set(gca, 'YColor', [0.00 0.45 0.74]);

% X-axis
xlabel('Silicon w_{Si} amount (wt-%)', 'FontSize', 12, 'FontWeight', 'bold');
xlim([0, 100]);

% Title
title('Case-Study 1: Zero Expansion (E=0 & P_{ALi}=0)', ...
      'FontSize', 14, 'FontWeight', 'bold');

% Legend
legend('Location', 'northwest', 'FontSize', 11);
set(gca, 'FontSize', 11, 'LineWidth', 1.5);

%fprintf('✓ Case Study 1 plot created\n');

%% ═══════════════════════════════════════════════════════════════════════
%% FIGURE 2: CASE STUDY 2 - Constant Porosity (P_A = P_ALi)
%% ═══════════════════════════════════════════════════════════════════════

% Define porosity levels to plot
porosity_levels = [0, 10, 20, 30, 40];  % vol-%
n_porosity = length(porosity_levels);

% Colors for different porosities (from blue to green)
colors_porosity = [
    0.00 0.45 0.74;   % Blue - 0%
    0.85 0.33 0.10;   % Red - 10%
    0.93 0.69 0.13;   % Orange - 20%
    0.49 0.18 0.56;   % Purple - 30%
    0.47 0.67 0.19;   % Green - 40%
];

% Extract V_A for each porosity level (already calculated in model!)
E_case2       = data_save.vol_cap.case2.E;
V_A_case2_all = data_save.vol_cap.case2.V_A_array;

figure('Position', [150, 150, 1400, 700]);
set(gcf, 'Color', 'w');

% Left Y-axis: Volumetric Capacity
yyaxis left;
hold on; grid on; box on;

% Plot V_A for each porosity level
for p = 1:n_porosity
    plot(wtSi_array, V_A_case2_all(:, p), '-', 'LineWidth', 3, ...
         'Color', colors_porosity(p, :), ...
         'DisplayName', sprintf('Porosity %d%%', porosity_levels(p)));
end

ylabel('Volumetric capacity V_A (mAh/cm^3)', ...
       'FontSize', 12, 'FontWeight', 'bold');
ylim([0, 2400]);
set(gca, 'YColor', 'k');

% Right Y-axis: Expansion Tolerance
yyaxis right;
hold on;

% Plot Expansion (thick blue line)
plot(wtSi_array, E_case2, '-', 'LineWidth', 4, ...
     'Color', [0.00 0.45 0.74], 'DisplayName', 'Expansion tolerance factor');

ylabel('Expansion Tolerance E (vol-%)', ...
       'FontSize', 12, 'FontWeight', 'bold');
ylim([0, 250]);
set(gca, 'YColor', [0.00 0.45 0.74]);

% X-axis
xlabel('Silicon w_{Si} amount (wt-%)', 'FontSize', 12, 'FontWeight', 'bold');
xlim([0, 100]);

% Title
title('Case-Study 2: Constant Porosity (P_A = P_{ALi})', ...
      'FontSize', 14, 'FontWeight', 'bold');

% Legend
legend('Location', 'northwest', 'FontSize', 11);
set(gca, 'FontSize', 11, 'LineWidth', 1.5);

%fprintf('✓ Case Study 2 plot created\n');
%fprintf('✓ All volumetric capacity case study plots complete!\n\n');

%% Plot Save_Data
% Same as above, we need to plot different wt% for each C-Rate.
for cr = 1:length(options.cRates)

    figure; hold on; grid on;
    tiledlayout(2,2);
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
    nexttile;
    hold on;
    % Temperature axis (left)
    yyaxis left;
    
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

    nexttile;
    hold on;
    % Temperature axis (left)
    yyaxis left;
    
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
%% ----- Volume expansion Plot ------%%
figure;
plot(data_save.SoC(1 : length(param.NMC_OCV(:,1)), 1), data_save.VV0, 'LineWidth', 2);
grid on;
xlabel('SOC [-]');
ylabel('V/V_0 [-]');
title('Anode V/V_0 vs SOC — effect of Si content (math model)');
legend(compose('wt_{Si} = %.0f%%', options.wtSi*100), 'Location', 'NorthWest');