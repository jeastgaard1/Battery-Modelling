function [vol_cap_results] = Volumetric_Capacity_Model(param, options)
%% ═══════════════════════════════════════════════════════════════════════
%% VOLUMETRIC CAPACITY ANALYSIS - ELECTRODE DESIGN CASES
%% ═══════════════════════════════════════════════════════════════════════
% Analyzes volumetric energy density for three electrode design cases:
%   Case 1: Zero expansion (E=0, P_ALi=0) - Theoretical baseline
%   Case 2: Constant porosity (P_A = P_ALi) - Practical design
%   Case 3: Variable porosity (P_ALi calculated) - Optimized design

%% Extract material properties
rho_Si = options.materials.rho_Si;      % [g/cm³]
rho_G = options.materials.rho_G;        % [g/cm³]
rho_IM = options.materials.rho_IM;      % [g/cm³]
s_Si = options.materials.s_Si;          % [mAh/g]
s_G = options.materials.s_G;            % [mAh/g]
e_Si = options.materials.e_Si;          % [vol-%]
e_G = options.materials.e_G;            % [vol-%]
w_IM = options.materials.w_IM;          % [wt-%]

%% Get current configuration
wtSi = param.anode.wtSi * 100;    % Silicon weight fraction [%]
%w_Si_range = 0:0.5:95;
wtG = 100 - wtSi - w_IM;          % Graphite weight fraction [%]

if wtG < 0
    error('Invalid composition: wtG < 0 for wtSi = %.1f wt-%%', wtSi);
end

%% Weight fractions (convert to decimals for equations)s
%w_Si = wtSi / 100;
%w_G = wtG / 100;
%w_IM_frac = w_IM / 100;

%% Gravimetric capacity [mAh/g] - Equation (2)
G_A = (wtSi * s_Si + wtG * s_G) / 100;

%% Initial electrode porosity
P_A = options.electrode.epsilon;  % Initial porosity (before lithiation)

% fprintf('\n═══════════════════════════════════════════════════════════════\n');
% fprintf('  VOLUMETRIC CAPACITY ANALYSIS: Si %.0f wt%%\n', wtSi);
% fprintf('═══════════════════════════════════════════════════════════════\n');
% fprintf('  Gravimetric capacity: %.2f mAh/g\n', G_A);
% fprintf('  Initial porosity (P_A): %.2f\n', P_A);
% fprintf('───────────────────────────────────────────────────────────────\n\n');

%% ═══════════════════════════════════════════════════════════════════════
%% CASE 1: ZERO EXPANSION (Theoretical Baseline)
%% ═══════════════════════════════════════════════════════════════════════
% Assumes no volume change upon lithiation (E = 0)
% This gives the theoretical maximum volumetric energy density

% fprintf('CASE 1: Zero Expansion (E=0)\n');

% No expansion
E_case1 = 0;
P_ALi_case1 = 0;  % Porosity after lithiation set to zero for max capacity

% Calculate initial porosity required - Equation (10)
% P_A = [P_ALi * Σ(w_j/ρ_j) + Σ(w_j*e_j/ρ_j)] / [Σ(w_j/ρ_j) + Σ(w_j*e_j/100*ρ_j)]

numerator = wtSi * e_Si / rho_Si + wtG * e_G / rho_G;

denominator = wtSi / rho_Si + wtG / rho_G + w_IM / rho_IM + ...
              (wtSi * e_Si / rho_Si + wtG * e_G / rho_G) / 100;

P_A_required_case1 = numerator / denominator;

% Density of lithiated electrode - Equation (4)
%rho_ALi_case1 = (100 - P_ALi_case1) / ...
                %(w_Si/rho_Si + w_G/rho_G + w_IM_frac/rho_IM + ...
                 %w_Si*e_Si/(rho_Si*100) + w_G*e_G/(rho_G*100));

% Volumetric capacity - Equation (5)
V_A_case1 = G_A * 100 / denominator;

% fprintf('  Expansion (E): %.2f%%\n', E_case1);
% fprintf('  Required initial porosity (P_A): %.2f\n', P_A_required_case1);
% fprintf('  Porosity after Li (P_ALi): %.2f\n', P_ALi_case1);
% fprintf('  Volumetric capacity: %.2f mAh/cm³\n', V_A_case1);
% fprintf('\n');

%% ═══════════════════════════════════════════════════════════════════════
%% CASE 2: CONSTANT POROSITY (Practical Design)
%% ═══════════════════════════════════════════════════════════════════════
% Assumes porosity remains constant (P_A = P_ALi)
% Porosity remains constant, electrode expands freely
% This represents a design that maintains structural integrity

% fprintf('CASE 2: Constant Porosity (P_A = P_ALi)\n');

% Define porosity levels to calculate
porosity_levels = [0, 10, 20, 30, 40];  % vol-%
n_porosity = length(porosity_levels);

% Calculate expansion - Equation (11)
% E = [Σ(w_j*e_j/ρ_j)] / [Σ(w_j/ρ_j)]
sum_w_e_rho = wtSi * e_Si / rho_Si + wtG * e_G / rho_G;
sum_w_rho = wtSi / rho_Si + wtG / rho_G + w_IM / rho_IM;

E_case2 = sum_w_e_rho / sum_w_rho;  % This gives decimal, multiply by 100 for %

% Calculate volumetric capacity for each porosity level
V_A_case2_array = zeros(1, n_porosity);

for p = 1:n_porosity
    % Calculate using weight percentages
    sum_w_e_rho_fraction = wtSi*e_Si/(rho_Si*100) + wtG*e_G/(rho_G*100);
    
    % Density at this porosity
    rho_ALi = (100 - porosity_levels(p)) / (sum_w_rho + sum_w_e_rho_fraction);
    
    % Volumetric capacity
    V_A_case2_array(p) = G_A * rho_ALi;
end

% Use actual porosity (P_A) for primary result
P_ALi_case2 = P_A;
idx_actual = find(porosity_levels == round(P_A * 100));
if ~isempty(idx_actual)
    V_A_case2 = V_A_case2_array(idx_actual);
else
    % If actual porosity not in list, calculate separately
    sum_w_e_rho_fraction = wtSi*e_Si/(rho_Si*100) + wtG*e_G/(rho_G*100);
    rho_ALi_case2 = (100 - P_A) / (sum_w_rho + sum_w_e_rho_fraction);
    V_A_case2 = G_A * rho_ALi_case2;
end



%E_case2 = ((w_Si*e_Si/rho_Si + w_G*e_G/rho_G) / ...
          %(w_Si/rho_Si + w_G/rho_G + w_IM_frac/rho_IM)) * 100;

% Density of lithiated electrode - Equation (4)
%rho_ALi_case2 = (100 - P_ALi_case2) / ...
%                (w_Si/rho_Si + w_G/rho_G + w_IM_frac/rho_IM + ...
%                 w_Si*e_Si/(rho_Si*100) + w_G*e_G/(rho_G*100));

%sum_w_e_rho_fraction = wtSi*e_Si/(rho_Si*100) + wtG*e_G/(rho_G*100);
%rho_ALi_case2 = (100 - P_ALi_case2) / (sum_w_rho + sum_w_e_rho_fraction);
% Volumetric capacity - Equation (5)
%V_A_case2 = G_A * rho_ALi_case2;

% fprintf('  Expansion (E): %.2f%%\n', E_case2);
% fprintf('  Initial porosity (P_A): %.2f\n', P_A);
% fprintf('  Porosity after Li (P_ALi): %.2f\n', P_ALi_case2);
% fprintf('  Volumetric capacity (at P_A=%.2f): %.2f mAh/cm³\n', P_A, V_A_case2);
% fprintf('\n');

%% ═══════════════════════════════════════════════════════════════════════
%% CASE 3: VARIABLE POROSITY (Optimized Design)
%% ═══════════════════════════════════════════════════════════════════════
% Calculates actual porosity after lithiation
% P_ALi = P_A - E (porosity decreases due to expansion)
% Porosity changes due to expansion - Equation (7)

%fprintf('CASE 3: Variable Porosity (P_ALi calculated)\n');

% Same expansion as Case 2
E_case3 = E_case2;

% Calculate volume fractions for P_ALi calculation
% First calculate initial density
w_Si_frac = wtSi / 100;
w_G_frac = wtG / 100;
w_IM_frac = w_IM / 100;

% Calculate volume fractions - Equation (9)
% v_j = (ρ_A / ρ_j) * w_j

% First calculate initial density - Equation (1)
%rho_A = (100 - P_A) / (w_Si/rho_Si + w_G/rho_G + w_IM_frac/rho_IM);
rho_A = (100 - P_A) / (w_Si_frac/rho_Si + w_G_frac/rho_G + w_IM_frac/rho_IM);
%v_Si = (rho_A / rho_Si) * w_Si;
%v_G = (rho_A / rho_G) * w_G;
v_Si = (rho_A / rho_Si) * w_Si_frac;
v_G = (rho_A / rho_G) * w_G_frac;
%v_IM = (rho_A / rho_IM) * w_IM_frac;

% Calculate P_ALi - Equation (7) rearranged for P_ALi
% P_A = Σ(v_j * e_j / 100) + P_ALi * (V_f/V_i) + 100 * (1 - V_f/V_i)
% Assuming V_f/V_i = 1 + E/100

%V_f_over_V_i = 1 + E_case3/100;

P_ALi_case3 = P_A - (v_Si*e_Si + v_G*e_G)/100;

% Density of lithiated electrode - Equation (4)
%rho_ALi_case3 = (100 - P_ALi_case3) / ...
%                (w_Si/rho_Si + w_G/rho_G + w_IM_frac/rho_IM + ...
%                 w_Si*e_Si/(rho_Si*100) + w_G*e_G/(rho_G*100));
rho_ALi_case3 = (100 - P_ALi_case3) / (sum_w_rho + sum_w_e_rho_fraction);
% Volumetric capacity - Equation (5)
V_A_case3 = G_A * rho_ALi_case3;

% fprintf('  Expansion (E): %.2f%%\n', E_case3);
% fprintf('  Initial porosity (P_A): %.2f\n', P_A);
% fprintf('  Porosity after Li (P_ALi): %.2f\n', P_ALi_case3);
% fprintf('  Volumetric capacity: %.2f mAh/cm³\n', V_A_case3);
% fprintf('\n');

%% Store results
vol_cap_results.wtSi = wtSi;
vol_cap_results.G_A = G_A;
vol_cap_results.P_A = P_A;

% Case 1
vol_cap_results.case1.E = E_case1;
vol_cap_results.case1.P_A_required = P_A_required_case1;
vol_cap_results.case1.P_ALi = P_ALi_case1;
%vol_cap_results.case1.rho_ALi = rho_ALi_case1;
vol_cap_results.case1.V_A = V_A_case1;

% Case 2
vol_cap_results.case2.E = E_case2;
vol_cap_results.case2.P_ALi = P_ALi_case2;
%vol_cap_results.case2.rho_ALi = rho_ALi_case2;
vol_cap_results.case2.V_A = V_A_case2;
vol_cap_results.case2.porosity_levels = porosity_levels;  % [0, 10, 20, 30, 40]
vol_cap_results.case2.V_A_array = V_A_case2_array;  % V_A for all porosities

% Case 3
vol_cap_results.case3.E = E_case3;
vol_cap_results.case3.P_ALi = P_ALi_case3;
%vol_cap_results.case3.rho_ALi = rho_ALi_case3;
vol_cap_results.case3.V_A = V_A_case3;


% fprintf('═══════════════════════════════════════════════════════════════\n');
% fprintf('  VOLUMETRIC CAPACITY ANALYSIS COMPLETE\n');
% fprintf('═══════════════════════════════════════════════════════════════\n\n');

end