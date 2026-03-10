%##########################################################################
%
% General points
% === Electro-chemical ===============================
% Full Cell ECM: OCV + R(Si_th) + RC1(Si_th) + RC2(Si_th)
% Expansion (Si_th) based on GrSi anode
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
% Parameterization and cell structure was created based on a
% GrSi-NMC 21700 class cell. Values have been stored in options
% and altered throughout different itterations.
% ===========================================
% 
% === Structure ====================================================
% run main file: "run_ECM"
% -options:         loads all set options for the cell
% -cell parameters: loads parametrization & data of considered cell
%                   depending on different stages of the cells life.
% =================================================================
%%

clear
clc

% This code allows MATLAB to find all the required files.
addpath(genpath('Models'));
addpath(genpath('Electrical'));

% Loads all settings in options file.
[options] = options_ECM_VolThev;

% Loads final strucutre for results and temp results.
[battery_res, data_save] = structure_ECM_2RC_VolThev(options);

% Setting initial values required for start of simulations.
if options.bool.ini == 1
    battery_res.T.T_lowC(1,1) = options.ini.T;
    battery_res.T.T_midC(1,1) = options.ini.T;
    battery_res.T.T_highC(1,1) = options.ini.T;
    battery_res.V00 = 1; % Need to have a starting V/V0.
    % SoH has not been implimented here, but left for further imp.
    battery_res.Aging.SoH_R(1,1)=1; %Set inital SoH values
    battery_res.Aging.SoH_C(1,1)=1; %Set inital SoH values
end
 
%% Solve for Volume expansion vs SoC and save date with x5 wtSi%s.
for w = 1:length(options.wtSi)
    [param]=ECM_Parameter_ECM_VolThev(...
        data_save, options, w,options.cRates(2));
    for step = 1:length(param.NMC_OCV(:,1))
        [data_save] = Volume_Expansion(...
            data_save, param, options, step, w );
    end
end

%% Volumetric Capacity sweep(fine wtSi grid,independent of ECM simulation)
% -------------------------------------------------------------------------
% Purpose:
%   Compute volumetric capacity (Cases 1, 2, 3) across a fine Si wt-%
%   sweep from 5% to 95%. This is independent of the ECM simulation which
%   only runs for the 5 compositions in options.wtSi.
wtSi_sweep = (0.05:0.05:0.95);  % 19 compositions: 5% to 95% in steps of 5%
data_save_vc = data_save;       % Safe copy — protects original ECM data

for w = 1:length(wtSi_sweep)

    % Set wtSi as scalar for this iteration so ECM_Parameter always
    % indexes at position 1 — avoids out-of-bounds error
    options_vc       = options;
    options_vc.wtSi  = wtSi_sweep(w);  % e.g. 0.05 at w=1, 0.10 at w=2 ...

    % Build param for this single composition
    % (index=1 since wtSi is scalar)
    [param_vc] = ECM_Parameter_ECM_VolThev(...
        data_save_vc, options_vc, 1, options.cRates(2));

    % Compute SOC-dependent volume expansion for this composition
    % Results stored in data_save_vc.dV_Si(:,w) and data_save_vc.dV_Gr(:,w)
    for step = 1:length(param_vc.NMC_OCV(:,1))
        [data_save_vc] = Volume_Expansion(...
            data_save_vc, param_vc, options_vc, step, w);
    end

    % Compute volumetric capacity using actual expansion at full lithiation
    % dV_Si(end,w) and dV_Gr(end,w) give the SOC=1 (fully lithiated) values
    % Results accumulated into data_save_vc.vol_cap at index w
    [battery_res.vol_cap, data_save_vc] = Volumetric_Capacity_Model(...
        param_vc, options_vc, data_save_vc, w);
end
% After loop: data_save_vc.vol_cap.wtSi = [5, 10, 15, ..., 95]
% Ready for Case 1, 2, 3 plots using the full Si wt-% design space

%% ODE for Terminal Voltage and Other model Simulations
for cr = 1:length(options.cRates)
    figure; hold on;
    for w = 1:length(options.wtSi) % Loop through different Si%
        % Creating new parameters every time with different cell (wt%) and
        % C-Rates for simulation. Redundant/expensive but simple solution.

        [param]=ECM_Parameter_ECM_VolThev(...
            data_save,options, w, options.cRates(cr));
        
        % Set up ODE equation for each new parameter build.
        x0 = [0; 0];
        ode_function = @(t,x) ECM_RC_ode(t, x, param);

        % ode15s is used for stiff simulation (exagerted values).
        % ode45 is used for non-stiff simulation (but slower sim time).
        [t_sim, u_sim] = ode45(ode_function, options.time_span, x0);

        % Compute terminal voltage
        V_sim = zeros(size(t_sim));
        
        % Loop through every single time step from provided data to
        % calculate new terminal voltages, resistances, and capacitance.
        for k = 1:numel(t_sim)
            V_sim(k) = ECM_term_volt(t_sim(k), u_sim(k,:).', param);

            % ECM Dependant models are called in the following file.
            [battery_res,options] = Battery_Model_ECM_VolThev(...
                battery_res,param,options,k);

            % After every model generation, data will need to be saved so
            % that it can be plotted later.
            [data_save] = SaveData(...
                battery_res, data_save, options, k, w, cr);
        
        end

        mech_input.SOC  = data_save.SoC(:, w); 
        mech_input.j_Si = data_save.current_dist.j_Si(:, w, cr);
        mech_input.j_G  = data_save.current_dist.j_G(:, w, cr); 
        SOC_exp_ref = param.NMC_SoC; 
        VV0_profile = data_save.VV0(:, w);
        % Call the mechanical function
        data_save.mech{cr, w} = Mechanical_Model_Function(...
            options, options.wtSi(w), ...
            mech_input, SOC_exp_ref, VV0_profile);
    
        % Plot the OCV curve from 2RC model
        plot(t_sim, V_sim, 'LineWidth', 2, ...
             'DisplayName', sprintf('Si wt%% = %.2f', options.wtSi(w)));
    
    end
    xlabel('Time [min]');
    ylabel('Terminal Voltage [V]');
    title(sprintf(...
        'GrSi ECM Simulation with differnt Si.-wt%% ( C-Rate of %.1f)',...
        options.cRates(cr)));
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

    I_Si_snapshot = squeeze(...
        data_save.current_dist.I_Si(snap_row, :, cr)) * 1000;  % [mA]
    I_G_snapshot  = squeeze(...
        data_save.current_dist.I_G(snap_row, :, cr))  * 1000;  % [mA]

    b = bar([I_G_snapshot; I_Si_snapshot]', 'grouped');
    b(1).FaceColor = [0.47 0.67 0.19];  % Graphite
    b(2).FaceColor = [0.85 0.33 0.10];  % Silicon

    set(gca, 'XTickLabel', arrayfun(@(x) sprintf('%.0f%%', x*100),...
        options.wtSi, 'UniformOutput', false));
    title(sprintf('C-Rate %.1f', options.cRates(cr)), 'FontSize', 12,...
        'FontWeight', 'bold');
    xlabel('Si Content [wt-%]', 'FontSize', 11, 'FontWeight', 'bold');
    ylabel('Current [mA]',      'FontSize', 11, 'FontWeight', 'bold');
    
    if cr == 1
    legend('Graphite', 'Silicon', 'Location', 'northwest', ...
           'FontSize', 10, 'Box', 'on');
    % add headroom above bars
    ylim([0, max(max(I_G_snapshot), max(I_Si_snapshot)) * 1.3]);
    end
    grid on;
end

sgtitle('Current Distribution vs Silicon Content', 'FontSize',...
    16, 'FontWeight', 'bold');

%% ═══════════════════════════════════════════════════════════════════════
%% PLOT VOLUMETRIC CAPACITY CASE STUDIES 
%% ═══════════════════════════════════════════════════════════════════════

% Extract data for FIRST C-rate only 
% data_save.vol_cap is now a struct
wtSi_array    = data_save_vc.vol_cap.wtSi;
G_A_array     = data_save_vc.vol_cap.G_A;
V_A_case1     = data_save_vc.vol_cap.case1.V_A;
P_A_req_case1 = data_save_vc.vol_cap.case1.P_A_required;

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

% Mark P_A = 35% intersection (black square)
P_A_target = options.electrode.epsilon * 100;  % = 35 vol-%
idx_30 = find(P_A_req_case1 >= P_A_target, 1, 'first');

if ~isempty(idx_30)
    % Marker with meaningful label
    plot(wtSi_array(idx_30), P_A_target, 'ks', ...
         'MarkerSize', 12, 'MarkerFaceColor', 'k', ...
         'DisplayName', sprintf('P_A = %.0f%% at %.0f wt-%% Si', ...
         P_A_target, wtSi_array(idx_30)));

    % Reference lines — hidden from legend
    xline(wtSi_array(idx_30), '--k', 'LineWidth', 1.5, ...
          'HandleVisibility', 'off');
    yline(P_A_target, '--k', 'LineWidth', 1.5, ...
          'HandleVisibility', 'off');
end

ylabel('Initial electrode porosity P_A (vol-%)', ...
       'FontSize', 12, 'FontWeight', 'bold');
ylim([0, 100]);
set(gca, 'YColor', [0.00 0.45 0.74]);

% X-axis
xlabel('Silicon w_{Si} amount (wt-%)', 'FontSize',...
    12, 'FontWeight', 'bold');
xlim([0, 100]);

% Title
title('Case-Study 1: Zero Expansion (E=0 & P_{ALi}=0)', ...
      'FontSize', 14, 'FontWeight', 'bold');

% Legend
legend('Location', 'northwest', 'FontSize', 11);
set(gca, 'FontSize', 11, 'LineWidth', 1.5);

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
E_case2       = data_save_vc.vol_cap.case2.E;
V_A_case2_all = data_save_vc.vol_cap.case2.V_A_array;
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
plot(wtSi_array, E_case2, '-', 'LineWidth', 3, ...
     'Color', [0.2 0.2 0.2], 'DisplayName', 'Expansion tolerance E');

ylabel('Expansion Tolerance E (vol-%)', ...
       'FontSize', 12, 'FontWeight', 'bold');
ylim([0, 250]);
set(gca, 'YColor', [0.2 0.2 0.2]);

% X-axis
xlabel('Silicon w_{Si} amount (wt-%)',...
    'FontSize', 12, 'FontWeight', 'bold');
xlim([0, 100]);

% Title
title('Case-Study 2: Constant Porosity (P_A = P_{ALi})', ...
      'FontSize', 14, 'FontWeight', 'bold');

% Legend
legend('Location', 'northwest', 'FontSize', 11);
set(gca, 'FontSize', 11, 'LineWidth', 1.5);

%% ═══════════════════════════════════════════════════════════════════════
%% FIGURE 3: CASE STUDY 3 - Variable Porosity (P_ALi calculated)
%% ═══════════════════════════════════════════════════════════════════════
V_A_case3   = data_save_vc.vol_cap.case3.V_A;
P_ALi_case3 = data_save_vc.vol_cap.case3.P_ALi;

% Find crossing index (P_ALi hits 0)
idx_zero = find(P_ALi_case3 <= 0, 1, 'first');

figure('Position', [200, 200, 1200, 650]);
set(gcf, 'Color', 'w');

% LEFT axis: V_A (stops at NaN) and G_A (full range)
yyaxis left;
hold on; grid on; box on;

plot(wtSi_array, V_A_case3, '-', 'LineWidth', 3, ...
     'Color', [0.85 0.33 0.10], 'DisplayName', 'V_A (Case 3)');

ylabel('Volumetric V_A (mAh/cm^3)', ...
       'FontSize', 12, 'FontWeight', 'bold');
ylim([0, 3500]);
set(gca, 'YColor', 'k');

% RIGHT axis: P_ALi only — tight scale so it uses full axis height
yyaxis right;
hold on;

plot(wtSi_array, P_ALi_case3, '-', 'LineWidth', 3, ...
     'Color', [0.00 0.45 0.74], 'DisplayName',...
     'P_{ALi} (after lithiation)');

% Mark feasibility limit
if ~isempty(idx_zero)
    plot(wtSi_array(idx_zero), 0, 'ks', ...
         'MarkerSize', 12, 'MarkerFaceColor', 'k', ...
         'DisplayName', sprintf('P_{ALi} = 0  (%.0f wt-%% Si limit)',...
         wtSi_array(idx_zero)));
    
    xline(wtSi_array(idx_zero), '--k', 'LineWidth', 1.5, ...
          'HandleVisibility', 'off');
end

ylabel('P_{ALi} after lithiation (vol-%)', ...
       'FontSize', 12, 'FontWeight', 'bold', 'Color', [0.00 0.45 0.74]);
ylim([0, 40]);
set(gca, 'YColor', [0.00 0.45 0.74]);

% Shared x-axis
yyaxis left;  xlim([0, 100]);
yyaxis right; xlim([0, 100]);

xlabel('Silicon w_{Si} amount (wt-%)', 'FontSize',...
    12, 'FontWeight', 'bold');
title(...
    'Case-Study 3: Variable Porosity (P_{ALi} = P_A - \Sigma v_j e_j)', ...
      'FontSize', 14, 'FontWeight', 'bold');

legend('Location', 'northwest', 'FontSize', 11);
set(gca, 'FontSize', 11, 'LineWidth', 1.5);

%% Mechanical Plots
%% ═══════════════════════════════════════════════════════════════════════
%% PARTICLE STRESS ANALYSIS PLOTS 
%% ═══════════════════════════════════════════════════════════════════════
cmap_mech = jet(length(options.wtSi));

for cr = 1:length(options.cRates)
    fig = figure('Name', sprintf('Particle Stress Analysis @ %.1fC',...
        options.cRates(cr)), 'Units', 'normalized', 'Position',...
        [0.1, 0.1, 0.8, 0.7], 'Color', 'w');
    
    phases = {'Si', 'Gr'};
    titles = {'Silicon Particle Stresses', 'Graphite Particle Stresses'};
    
    for p = 1:2
        subplot(1, 2, p); hold on; grid on; box on;
        
        % Add a zero-stress reference line
        yline(0, 'k-', 'LineWidth', 1.5, 'HandleVisibility', 'off');
        
        for w = 1:length(options.wtSi)
            res = data_save.mech{cr, w};
            
            soc_full = res.SoC * 100;
            sig_t_full = real(res.(phases{p}).sigma_t_surface) / 1e6;
            sig_r_full = real(res.(phases{p}).sigma_r_center) / 1e6;
            
            % Plot Tangential Surface Stress (Solid line)
            plot(soc_full, sig_t_full, ...
                'Color', cmap_mech(w,:), 'LineWidth', 2, ...
                'DisplayName', sprintf('%.0f%% Si: \\sigma_t', options.wtSi(w)*100));
            
            % Plot Radial Center Stress (Dashed line)
            plot(soc_full, sig_r_full, ...
                'Color', cmap_mech(w,:), 'LineWidth', 1.5, 'LineStyle', '--', ...
                'HandleVisibility', 'off');
        end
        
        title(titles{p}, 'FontSize', 12);
        xlabel('State of Charge (SOC) [%]');
        ylabel('Stress [MPa]');
        xlim([0 100]);
        
        % Helper Text for Full Cycle
        text(2, max(ylim)*0.9, 'Discharge (Tension)', 'FontSize', 10, 'FontWeight', 'bold', 'Color', [0.6 0 0]);
        text(2, min(ylim)*0.9, 'Charge (Compression)', 'FontSize', 10, 'FontWeight', 'bold', 'Color', [0 0 0.6]);
        
        if p == 1
            legend('Location', 'best', 'NumColumns', 1, 'FontSize', 8);
            
            % Placement for line style helper text
            y_limits = ylim;
            text(50, y_limits(2)*0.85, 'Solid: Tangential (Surface)', 'FontSize', 9, 'FontAngle', 'italic');
            text(50, y_limits(2)*0.75, 'Dash: Radial (Center)', 'FontSize', 9, 'FontAngle', 'italic');
        end
    end
    sgtitle(sprintf('Intra-Particle Stress Comparison: %.1fC (Full Cycle)', options.cRates(cr)), ...
            'FontSize', 14, 'FontWeight', 'bold');
end

%% ═══════════════════════════════════════════════════════════════════════
%% TOTAL PACK (STACK) STRESS PLOT (FULL CYCLE)
%% ═══════════════════════════════════════════════════════════════════════
figure('Name', 'Total Pack Stack Stress (Full Cycle)', 'Color', 'w', 'Position', [200, 200, 800, 500]);
hold on; grid on; box on;
line_styles = {'-', '--', ':'};

for cr = 1:length(options.cRates)
    for w = 1:length(options.wtSi)
        res = data_save.mech{cr, w};
        
        % Plot the macro-scale stack stress (Pascals to MPa)
        plot(res.SoC*100, res.stack_stress / 1e6, ...
             'Color', cmap_mech(w,:), ...
             'LineStyle', line_styles{mod(cr-1,3)+1}, ...
             'LineWidth', 2);
    end
end

xlabel('State of Charge (SOC) [%]', 'FontWeight', 'bold');
ylabel('Total Stack Stress [MPa]', 'FontWeight', 'bold');
title('Macro-Scale Pack Stress vs. Silicon Content (Full Cycle)', 'FontSize', 14);

% Dynamic text placement based on current limits
y_max = max(ylim);
y_min = min(ylim);
text(5, y_min + 0.95*(y_max-y_min), 'Line Styles (C-Rate):', 'FontWeight', 'bold', 'FontSize', 10);
for cr = 1:length(options.cRates)
    text(10, y_min + (0.95 - cr*0.06)*(y_max-y_min), sprintf('%s  %.1f C', line_styles{mod(cr-1,3)+1}, options.cRates(cr)), 'FontSize', 10);
end

% Colorbar for Si Content
colormap(jet);
c = colorbar;
c.Label.String = 'Silicon Weight Fraction (wt-%)';
c.Ticks = linspace(0, 1, length(options.wtSi));
c.TickLabels = string(options.wtSi * 100);


%% ═══════════════════════════════════════════════════════════════════════
%% Plot Temperature and other remaining data from save_data.
%%  ═══════════════════════════════════════════════════════════════════════
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
    ylabel('Temperature [K]');
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
    xlabel('Time [min]');
    title(sprintf('Thermal & SoC Evolution at %.1fC Discharge',...
        options.cRates(cr)));
    legend('Location','best');

    % Temperature axis (left)
    yyaxis left;
    subplot(1,2,2);
    hold on;
    for w = 1:length(options.wtSi)
        plot(t_sim_CH, ...
             data_save.T.(options.Save.T{cr})(param.time_mid :...
             options.data.steps,w), ...
             'Color', cmap(w,:), ...
             'LineWidth', 1.5, ...
             'DisplayName', sprintf('Si wt%% = %.2f', options.wtSi(w)));
    end

    ylabel('Temperature [K]')
   
    % SoC axis (right)
    yyaxis right
    plot(t_sim_CH, data_save.SoC(param.time_mid : ...
        options.data.steps,1), ...
         'Color', [0 0.45 0.70], ...   % strong blue
         'LineWidth', 2, ...
         'DisplayName', 'SoC');
    xlim([min(t_sim_CH) max(t_sim_CH)])
    ylabel('State of Charge [-]');
    ylim([0 1]);
    xlabel('Time [min]');
    title(sprintf('Thermal & SoC Evolution at %.1fC Charge',...
        options.cRates(cr)));
    legend('Location','best');
    % Save the thermal plots as png files.
    saveas(gcf, "Thermal_Plot" + cr + ".png"); 
end

%% ----- Volume expansion Plot ------%%
figure;
plot(data_save.SoC(1 : length(param.NMC_OCV(:,1)), 1),...
    data_save.VV0, 'LineWidth', 2);
grid on;
xlabel('SOC [-]');
ylabel('V/V_0 [-]');
title('Anode V/V_0 vs SOC — effect of Si content (math model)');
legend(compose('wt_{Si} = %.0f%%', options.wtSi*100),...
    'Location', 'NorthWest');

%% ----- Thermal Strain ---- %%
figure;
plot(t_sim_CH, data_save.TVE.TVE_highC(param.time_mid :...
    options.data.steps,:), 'LineWidth', 2);
grid on;
xlabel('SOC [-]');
ylabel('V/V_0 [-]');
title('Thermal Strain VS SoC');
legend(compose('wt_{Si} = %.0f%%', options.wtSi*100),...
    'Location', 'NorthWest');

