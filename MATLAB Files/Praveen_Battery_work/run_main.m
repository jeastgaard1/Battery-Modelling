%% Setup output directory
% Creates 'results' folder in current directory
output_dir = 'results';
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
    fprintf('✓ Created output directory: %s\n', output_dir);
end
fprintf('✓ Results will be saved to: %s\n\n', fullfile(pwd, output_dir));


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

%% Silicon weight fraction range
w_Si_range = 0:0.5:95;
n_points = length(w_Si_range);

%% Calculate Average Potentials from Experimental Curves
fprintf('Calculating average potentials from experimental curves...\n');

U_avg_NMC = calculate_average_potential(NMC_SoC, NMC_OCV);
U_avg_Si = calculate_average_potential(Si_SoC, Si_OCV);
U_avg_G = calculate_average_potential(Gr_SoC, Gr_OCV);
%U_avg_GrSi = calculate_average_potential(GrSi_SoC, GrSi_OCV);

fprintf('NMC Cathode      : %.4f V\n', U_avg_NMC);
fprintf('Silicon Anode    : %.4f V\n', U_avg_Si);
fprintf('Graphite Anode   : %.4f V\n', U_avg_G);
%fprintf('Gr/Si Composite  : %.4f V\n', U_avg_GrSi);

%% CASE STUDY 1: Zero Expansion (E=0, P_ALi=0)
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
target_PA = 30;   % change to any value you want
[~, idx] = min(abs(P_A_case1 - target_PA));
fprintf('At P_A = %.0f vol-%%:\n', target_PA);
fprintf('  Si content: %.1f wt-%%\n', w_Si_range(idx));
fprintf('  Volumetric capacity: %.1f mAh/cm³\n', V_A_case1(idx));
fprintf('  Gravimetric capacity: %.1f mAh/g\n', G_A_case1(idx));
fprintf('  Energy density: %.1f Wh/L\n\n', ED_Vol_case1(idx));

%% CASE STUDY 2: Constant Porosity (P_A = P_ALi, Free Expansion)
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
plot(w_Si_range, V_A_case1, 'r-', 'LineWidth', 2.5, 'DisplayName', 'V_A (Si/Graphite)');
hold on;
plot(w_Si_range, G_A_case1, 'g-', 'LineWidth', 2.5, 'DisplayName', 'G_A (Si/Graphite)');
ylabel('Specific Capacity (V_A in mAh/cm³ & G_A in mAh/g)', ...
       'FontWeight', 'bold', 'FontSize', 12);
ylim([0, 3500]);
set(gca, 'YColor', 'k');

yyaxis right
plot(w_Si_range, P_A_case1, 'b-', 'LineWidth', 2.5, 'DisplayName', 'P_A (Si/Graphite)');
ylabel('Initial electrode porosity P_A (vol-%)', ...
       'FontWeight', 'bold', 'FontSize', 12, 'Color', 'b');
ylim([0, 100]);
set(gca, 'YColor', 'b');

% Mark the P_A = 30% point
yyaxis right
yline(30, 'k--', 'LineWidth', 1.5, 'Alpha', 0.7);
xline(w_Si_range(idx), 'k--', 'LineWidth', 1.5, 'Alpha', 0.7);
plot(w_Si_range(idx), 30, 'ko', 'MarkerSize', 8, ...
     'MarkerFaceColor', 'w', 'LineWidth', 2);

yyaxis left
plot(w_Si_range(idx), V_A_case1(idx), 'ks', 'MarkerSize', 10, ...
     'MarkerFaceColor', 'k', 'LineWidth', 2);

xlabel('Silicon w_{Si} amount (wt-%)', 'FontWeight', 'bold', 'FontSize', 12);
title('Case-Study 1: Zero Expansion (E=0 & P_{ALi}=0) - Experimental Potentials', ...
      'FontWeight', 'bold', 'FontSize', 14);
legend('Location', 'northwest', 'FontSize', 10);
grid on;
set(gca, 'FontSize', 11);

saveas(fig1, fullfile(output_dir, 'case1_experimental.png'));
fprintf('✓ Case 1 plot saved\n');

%% Plot 2: Case Study 2 - Constant Porosity
fig2 = figure('Position', [150, 150, 1200, 800]);
set(fig2, 'Color', 'w');

colors_porosity = lines(n_porosity);

yyaxis left
for j = 1:n_porosity
    plot(w_Si_range, V_A_case2(j, :), '-', 'Color', colors_porosity(j, :), ...
         'LineWidth', 2.5, 'DisplayName', sprintf('Porosity %d%%', porosity_values(j)));
    hold on;
end
ylabel('Volumetric capacity V_A (mAh/cm³)', 'FontWeight', 'bold', 'FontSize', 12);
ylim([0, 2400]);
set(gca, 'YColor', 'k');

yyaxis right
plot(w_Si_range, E_expansion, 'b-', 'LineWidth', 3, ...
     'DisplayName', 'Expansion tolerance factor');
ylabel('Expansion Tolerance E (vol-%)', 'FontWeight', 'bold', ...
       'FontSize', 12, 'Color', 'b');
ylim([0, 260]);
set(gca, 'YColor', 'b');

xlabel('Silicon w_{Si} amount (wt-%)', 'FontWeight', 'bold', 'FontSize', 12);
title('Case-Study 2: Constant Porosity (P_A = P_{ALi}) - Experimental Potentials', ...
      'FontWeight', 'bold', 'FontSize', 14);
legend('Location', 'best', 'FontSize', 10);
grid on;
set(gca, 'FontSize', 11);

saveas(fig2, fullfile(output_dir, 'case2_experimental.png'));
fprintf('✓ Case 2 plot saved\n');




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