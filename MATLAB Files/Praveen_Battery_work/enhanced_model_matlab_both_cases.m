%% Enhanced Volumetric Capacity Model - Case Studies 1 & 2
% Based on: Otero et al. + Professor's experimental NMC/Gr/Si data
% Uses real voltage curves for both case studies

clear all; close all; clc;
%% Setup Output Directory
% Create 'outputs' folder in current directory if it doesn't exist
output_dir = fullfile(pwd, 'outputs');
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
    fprintf('Created output directory: %s\n\n', output_dir);
else
    fprintf('Using output directory: %s\n\n', output_dir);
end

fprintf('\n╔════════════════════════════════════════════════════════════╗\n');
fprintf('║   Enhanced Model: Case Studies 1 & 2                      ║\n');
fprintf('║   Using Professor''s Experimental Potential Data           ║\n');
fprintf('╚════════════════════════════════════════════════════════════╝\n\n');

%% Load Experimental Potential Data
fprintf('Loading experimental potential data...\n');

% Load the .mat file with experimental data
data_file = 'C:\Users\prave\Documents\Praveen_Battery_work\Potential_Gr_Si_NMC.mat';
load(data_file);

% Extract discharge data
dch_data = param.potentials.HC.DCH;

% Extract and clean potential curves
[NMC_SoC, NMC_OCV] = clean_potential_data(dch_data.NMC_SoC, dch_data.NMC_OCV);
[Gr_SoC, Gr_OCV] = clean_potential_data(dch_data.Gr_SoC, dch_data.Gr_OCV);
[Si_SoC, Si_OCV] = clean_potential_data(dch_data.Si_SoC, dch_data.Si_OCV);
[GrSi_SoC, GrSi_OCV] = clean_potential_data(dch_data.GrSi_SoC, dch_data.GrSi_OCV);

fprintf('✓ NMC: %d points, %.3f-%.3fV\n', length(NMC_SoC), min(NMC_OCV), max(NMC_OCV));
fprintf('✓ Graphite: %d points, %.3f-%.3fV\n', length(Gr_SoC), min(Gr_OCV), max(Gr_OCV));
fprintf('✓ Silicon: %d points, %.3f-%.3fV\n', length(Si_SoC), min(Si_OCV), max(Si_OCV));
fprintf('✓ Gr/Si Composite: %d points, %.3f-%.3fV\n\n', length(GrSi_SoC), min(GrSi_OCV), max(GrSi_OCV));

%% Material Properties
% Densities (g/cm³)
rho_Si = 2.3;      % Silicon density                                       
rho_G = 2.24;      % Graphite density
rho_IM = 1.1;      % Inactive materials density

% Specific capacities (mAh/g)
s_Si = 3600;       % Silicon specific capacity
s_G = 330;         % Graphite specific capacity
s_IM = 0;          % Inactive materials (no capacity)

% Volume expansion upon lithiation (vol.-%)
e_Si = 280;        % Silicon expansion
e_G = 0;           % Graphite expansion (assumed negligible)
e_IM = 0;          % Inactive materials expansion

% Fixed parameters
w_IM = 5;          % Inactive materials weight fraction (wt.-%)

%% Calculate Average Potentials from Experimental Curves
fprintf('Calculating average potentials from experimental curves...\n');

U_avg_NMC = calculate_average_potential(NMC_SoC, NMC_OCV);
U_avg_Si = calculate_average_potential(Si_SoC, Si_OCV);
U_avg_G = calculate_average_potential(Gr_SoC, Gr_OCV);

fprintf('Experimental Average Potentials:\n');
fprintf('  NMC Cathode:           %.4f V\n', U_avg_NMC);
fprintf('  Silicon Anode:         %.4f V\n', U_avg_Si);
fprintf('  Graphite Anode:        %.4f V\n', U_avg_G);
fprintf('  NMC vs Graphite:       %.4f V\n', U_avg_NMC - U_avg_G);
fprintf('  NMC vs Silicon:        %.4f V\n\n', U_avg_NMC - U_avg_Si);

%% Silicon weight fraction range
w_Si_range = 0:0.5:95;
n_points = length(w_Si_range);

%% ═══════════════════════════════════════════════════════════════════════
%% CASE STUDY 1: Zero Expansion (E=0, P_ALi=0)
%% ═══════════════════════════════════════════════════════════════════════
fprintf('═══════════════════════════════════════════════════════════\n');
fprintf('CASE STUDY 1: Zero Electrode Expansion (E=0 & P_ALi=0)\n');
fprintf('═══════════════════════════════════════════════════════════\n\n');

% Initialize arrays for Case 1
G_A_case1 = zeros(1, n_points);
V_A_case1 = zeros(1, n_points);
P_A_case1 = zeros(1, n_points);
ED_Vol_case1 = zeros(1, n_points);
U_cell_case1 = zeros(1, n_points);
U_anode_case1 = zeros(1, n_points);

% Calculate for each composition
for i = 1:n_points
    w_Si = w_Si_range(i);
    w_G = 100 - w_Si - w_IM;
    
    if w_G < 0
        continue;
    end
    
    % Gravimetric capacity (Equation 2)
    G_A_case1(i) = (w_Si * s_Si + w_G * s_G) / 100;
    
    % Required initial porosity for zero expansion (Equation 10 with P_ALi=0)
    numerator = w_Si * e_Si / rho_Si + w_G * e_G / rho_G;
    denominator = w_Si / rho_Si + w_G / rho_G + w_IM / rho_IM + ...
                  (w_Si * e_Si / rho_Si + w_G * e_G / rho_G) / 100;
    P_A_case1(i) = numerator / denominator;
    
    % Volumetric capacity (Equation 5 with P_ALi=0)
    V_A_case1(i) = G_A_case1(i) * 100 / denominator;
    
    % Average anode potential using experimental data (Equation 13)
    if G_A_case1(i) > 0
        U_anode_case1(i) = (w_Si * s_Si * U_avg_Si + w_G * s_G * U_avg_G) / ...
                           (w_Si * s_Si + w_G * s_G);
    else
        U_anode_case1(i) = U_avg_G;
    end
    
    % Cell voltage and energy density (Equation 14)
    U_cell_case1(i) = U_avg_NMC - U_anode_case1(i);
    ED_Vol_case1(i) = U_cell_case1(i) * V_A_case1(i);
end

% Find point at P_A = 30%
[~, idx_30] = min(abs(P_A_case1 - 30));
fprintf('At P_A = 30 vol-%%:\n');
fprintf('  Si content: %.1f wt-%%\n', w_Si_range(idx_30));
fprintf('  Volumetric capacity: %.1f mAh/cm³\n', V_A_case1(idx_30));
fprintf('  Gravimetric capacity: %.1f mAh/g\n', G_A_case1(idx_30));
fprintf('  Energy density: %.1f Wh/L\n\n', ED_Vol_case1(idx_30));

%% ═══════════════════════════════════════════════════════════════════════
%% CASE STUDY 2: Constant Porosity (P_A = P_ALi, Free Expansion)
%% ═══════════════════════════════════════════════════════════════════════
fprintf('═══════════════════════════════════════════════════════════\n');
fprintf('CASE STUDY 2: Constant Porosity (P_A = P_ALi)\n');
fprintf('═══════════════════════════════════════════════════════════\n\n');

% Different porosity values to analyze
porosity_values = [0, 10, 20, 30, 40];
n_porosity = length(porosity_values);

% Initialize arrays for Case 2
V_A_case2 = zeros(n_porosity, n_points);
E_expansion = zeros(1, n_points);
ED_Vol_case2 = zeros(n_porosity, n_points);

% Calculate for each porosity and composition
for j = 1:n_porosity
    P_A = porosity_values(j);
    fprintf('Calculating for porosity P_A = %d vol-%%...\n', P_A);
    
    for i = 1:n_points
        w_Si = w_Si_range(i);
        w_G = 100 - w_Si - w_IM;
        
        if w_G < 0
            continue;
        end
        
        % Same gravimetric capacity as Case 1
        G_A = G_A_case1(i);
        
        % Volumetric capacity with constant porosity (Equation 5)
        sum_w_rho = w_Si/rho_Si + w_G/rho_G + w_IM/rho_IM;
        sum_w_e_rho = w_Si*e_Si/(rho_Si*100) + w_G*e_G/(rho_G*100);
        
        rho_ALi = (100 - P_A) / (sum_w_rho + sum_w_e_rho);
        V_A_case2(j, i) = G_A * rho_ALi;
        
        % Energy density for Case 2
        ED_Vol_case2(j, i) = U_cell_case1(i) * V_A_case2(j, i);
    end
end

% Calculate expansion tolerance (Equation 11)
fprintf('\nCalculating expansion tolerance...\n');
for i = 1:n_points
    w_Si = w_Si_range(i);
    w_G = 100 - w_Si - w_IM;
    
    if w_G < 0
        continue;
    end
    
    sum_w_e_rho = w_Si * e_Si / rho_Si + w_G * e_G / rho_G;
    sum_w_rho = w_Si / rho_Si + w_G / rho_G + w_IM / rho_IM;
    
    E_expansion(i) = sum_w_e_rho / sum_w_rho;
end

fprintf('Done!\n\n');

%% ═══════════════════════════════════════════════════════════════════════
%% PLOTTING
%% ═══════════════════════════════════════════════════════════════════════
fprintf('Creating plots...\n');

%% Plot 1: Case Study 1 - Zero Expansion
fig1 = figure('Position', [100, 100, 1200, 800]);
set(fig1, 'Color', 'w');

yyaxis left
plot(w_Si_range, V_A_case1, 'r-', 'LineWidth', 2.5); hold on;
plot(w_Si_range, G_A_case1, 'g-', 'LineWidth', 2.5);
ylabel('V_A (mAh/cm³) & G_A (mAh/g)');

yyaxis right
plot(w_Si_range, P_A_case1, 'b-', 'LineWidth', 2.5);
ylabel('Initial Porosity (vol-%)');

xline(w_Si_range(idx_30), 'k--');
yline(30, 'k--');

xlabel('Silicon wt-%');
title('Case 1: Zero Expansion');
grid on;

saveas(fig1, fullfile(output_dir, 'matlab_case1_experimental.png'));

%% Plot 2: Case Study 2 - Constant Porosity
fig2 = figure('Position', [150, 150, 1200, 800]);
set(fig2, 'Color', 'w');

colors = lines(n_porosity);

yyaxis left
for j = 1:n_porosity
    plot(w_Si_range, V_A_case2(j,:), 'LineWidth', 2.5, 'Color', colors(j,:)); hold on;
end
ylabel('V_A (mAh/cm³)');

yyaxis right
plot(w_Si_range, E_expansion, 'k-', 'LineWidth', 3);
ylabel('Expansion');

xlabel('Silicon wt-%');
title('Case 2: Constant Porosity');
grid on;

saveas(fig2, fullfile(output_dir, 'matlab_case2_experimental.png'));

%% Plot 3: Energy Density Comparison - Case 1
fig3 = figure('Position', [200, 200, 1200, 800]);
set(fig3, 'Color', 'w');

yyaxis left
plot(w_Si_range, ED_Vol_case1, 'b-', 'LineWidth', 2.5);
ylabel('Energy Density (Wh/L)');

yyaxis right
plot(w_Si_range, U_cell_case1, 'r-', 'LineWidth', 2.5);
ylabel('Cell Voltage (V)');

xlabel('Silicon wt-%');
title('Energy Density - Case 1');
grid on;

saveas(fig3, fullfile(output_dir, 'matlab_energy_case1_experimental.png'));

%% Plot 4: Energy Density for Different Porosities - Case 2
%% Plot 4: Energy Density Case 2
fig4 = figure('Position', [250, 250, 1200, 800]);
set(fig4, 'Color', 'w');

for j = 1:n_porosity
    plot(w_Si_range, ED_Vol_case2(j,:), 'LineWidth', 2.5, 'Color', colors(j,:)); hold on;
end

xlabel('Silicon wt-%');
ylabel('Energy Density (Wh/L)');
title('Energy Density - Case 2');
grid on;

saveas(fig4, fullfile(output_dir, 'matlab_energy_case2_experimental.png'));

%% Plot 5: Experimental Potential Curves
fig5 = figure('Position', [300, 300, 1400, 900]);
set(fig5, 'Color', 'w');

subplot(2,2,1); plot(NMC_SoC, NMC_OCV, 'LineWidth',2); grid on; title('NMC');
subplot(2,2,2); plot(Gr_SoC, Gr_OCV, 'LineWidth',2); grid on; title('Graphite');
subplot(2,2,3); plot(Si_SoC, Si_OCV, 'LineWidth',2); grid on; title('Silicon');
subplot(2,2,4); plot(GrSi_SoC, GrSi_OCV, 'LineWidth',2); grid on; title('Gr/Si');

sgtitle('Experimental Potentials');

saveas(fig5, fullfile(output_dir, 'matlab_experimental_potentials.png'));

%% Plot 6: Combined Comparison - Both Case Studies
fig6 = figure('Position', [350, 350, 1400, 900]);
set(fig6, 'Color', 'w');

subplot(2,2,1);
plot(w_Si_range, V_A_case1, 'r-', 'LineWidth',2.5); hold on;
plot(w_Si_range, V_A_case2(3,:), 'b-', 'LineWidth',2.5);
title('Volumetric Capacity'); grid on;

subplot(2,2,2);
plot(w_Si_range, P_A_case1, 'b-', 'LineWidth',2.5); hold on;
plot(w_Si_range, E_expansion, 'r-', 'LineWidth',2.5);
title('Porosity vs Expansion'); grid on;

subplot(2,2,3);
plot(w_Si_range, ED_Vol_case1, 'r-', 'LineWidth',2.5); hold on;
plot(w_Si_range, ED_Vol_case2(3,:), 'b-', 'LineWidth',2.5);
title('Energy Density'); grid on;

subplot(2,2,4);
plot(w_Si_range, U_cell_case1, 'LineWidth',2.5);
title('Cell Voltage'); grid on;

sgtitle('Case Comparison');

saveas(fig6, fullfile(output_dir, 'matlab_both_cases_comparison.png'));


%% Print Summary
fprintf('\n╔════════════════════════════════════════════════════════════╗\n');
fprintf('║                    SUMMARY RESULTS                         ║\n');
fprintf('╚════════════════════════════════════════════════════════════╝\n\n');

fprintf('═══ CASE STUDY 1: Zero Expansion (E=0) ═══\n\n');

[max_ED1, idx_max_ED1] = max(ED_Vol_case1);
fprintf('Maximum Energy Density: %.1f Wh/L at %.1f wt-%% Si\n', ...
        max_ED1, w_Si_range(idx_max_ED1));
fprintf('  Cell Voltage: %.3f V\n', U_cell_case1(idx_max_ED1));
fprintf('  Volumetric Capacity: %.1f mAh/cm³\n', V_A_case1(idx_max_ED1));
fprintf('  Required Porosity: %.1f vol-%%\n\n', P_A_case1(idx_max_ED1));

[max_V1, idx_max_V1] = max(V_A_case1);
fprintf('Maximum Volumetric Capacity: %.1f mAh/cm³ at %.1f wt-%% Si\n\n', ...
        max_V1, w_Si_range(idx_max_V1));

fprintf('═══ CASE STUDY 2: Constant Porosity ═══\n\n');

fprintf('At P_A = 0%% (Zero Porosity):\n');
fprintf('  Max Volumetric Capacity: %.1f mAh/cm³\n', max(V_A_case2(1, :)));
fprintf('  Max Energy Density: %.1f Wh/L\n\n', max(ED_Vol_case2(1, :)));

fprintf('At P_A = 20%% (Typical):\n');
fprintf('  Max Volumetric Capacity: %.1f mAh/cm³\n', max(V_A_case2(3, :)));
fprintf('  Max Energy Density: %.1f Wh/L\n\n', max(ED_Vol_case2(3, :)));

fprintf('At P_A = 40%% (High Porosity):\n');
fprintf('  Max Volumetric Capacity: %.1f mAh/cm³\n', max(V_A_case2(5, :)));
fprintf('  Max Energy Density: %.1f Wh/L\n\n', max(ED_Vol_case2(5, :)));

fprintf('Maximum Expansion Tolerance: %.1f vol-%% at %.1f wt-%% Si\n\n', ...
        max(E_expansion), w_Si_range(find(E_expansion == max(E_expansion), 1)));

fprintf('═══════════════════════════════════════\n\n');

fprintf('Files saved:\n');
fprintf('  ✓ matlab_case1_experimental.png\n');
fprintf('  ✓ matlab_case2_experimental.png\n');
fprintf('  ✓ matlab_energy_case1_experimental.png\n');
fprintf('  ✓ matlab_energy_case2_experimental.png\n');
fprintf('  ✓ matlab_experimental_potentials.png\n');
fprintf('  ✓ matlab_both_cases_comparison.png\n');
fprintf('  ✓ matlab_case1_results.csv\n');
fprintf('  ✓ matlab_case2_results.csv\n\n');

fprintf('All analyses completed successfully!\n');
fprintf('Using experimental potentials from professor''s data.\n\n');

%% Helper Functions

function [SoC_clean, OCV_clean] = clean_potential_data(SoC_raw, OCV_raw)
    % Clean potential data by removing invalid values
    SoC = SoC_raw(:);
    OCV = OCV_raw(:);
    
    % Filter valid physical ranges
    valid_idx = (SoC >= 0) & (SoC <= 1) & (OCV >= 0) & (OCV <= 5);
    
    SoC_clean = SoC(valid_idx);
    OCV_clean = OCV(valid_idx);
end

function U_avg = calculate_average_potential(SoC, OCV)
    % Calculate average potential from SoC-Voltage curve
    % Using trapezoidal integration
    
    if isempty(SoC) || isempty(OCV)
        U_avg = 0;
        return;
    end
    
    % Ensure column vectors
    SoC = SoC(:);
    OCV = OCV(:);
    
    % Numerical integration
    integral_V = trapz(SoC, OCV);
    delta_SoC = SoC(end) - SoC(1);
    
    if delta_SoC > 0
        U_avg = integral_V / delta_SoC;
    else
        U_avg = mean(OCV);
    end
end
