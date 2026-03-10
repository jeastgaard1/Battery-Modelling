function [results] = Mechanical_Model_Function(options, wtSi, current_dist)
% MECHANICAL_MODEL_FUNCTION
% Calculates diffusion-induced stresses in spherical Si and Graphite particles
% and computes the total electrode stack stress.

%% ── Parameters & Constants ──────────────────────────────────────────────
F     = options.constants.F;
R_gas = options.constants.R_gas;
T     = options.ini.T; 

% Mechanical Properties
E_Si = 80e9;   nu_Si = 0.22;  Omega_Si = 9.4e-6;  % Silicon
E_Gr = 10e9;   nu_Gr = 0.30;  Omega_Gr = 3.1e-6;  % Graphite
R_Si = 50e-9;  R_Gr = 5e-6;                       % Particle Radii

% Yield Limits (Caps)
Y_Si = 1.5e9;  % 1.5 GPa
Y_Gr = 0.5e9;  % 0.5 GPa

% Grid Setup
Nr = 50; 
r_Si = linspace(0, R_Si, Nr);
r_Gr = linspace(0, R_Gr, Nr);

steps = length(current_dist.SOC);
results.SoC = current_dist.SOC;

%% ── Particle Stress Loop ────────────────────────────────────────────────
for p = 1:2 % Phase 1: Silicon, Phase 2: Graphite
    if p == 1
        E = E_Si; nu = nu_Si; Omega = Omega_Si; R_p = R_Si; r = r_Si;
        j_flux = current_dist.j_Si; phase_name = "Si"; Y = Y_Si;
    else
        E = E_Gr; nu = nu_Gr; Omega = Omega_Gr; R_p = R_Gr; r = r_Gr;
        j_flux = current_dist.j_G;  phase_name = "Gr"; Y = Y_Gr;
    end

    % Integration constants
    const_r = (2 * E * Omega) / (9 * (1 - nu));
    const_t = (E * Omega) / (9 * (1 - nu));

    % Initialize Concentration and Stress matrices
    c = zeros(Nr, steps);
    sig_r = zeros(Nr, steps);
    sig_t = zeros(Nr, steps);

    % Simple Diffusion Approximation (Concentration Profile)
    % Note: In a full model, this uses the PDE solver; here we use the 
    % analytical distribution based on the flux j_flux.
    for t = 1:steps
        % Surface Concentration based on Flux
        c_surf = current_dist.SOC(t) * (1/Omega); 
        c(:,t) = c_surf * (r/R_p).^2; % Parabolic distribution assumption
        
        c_avg = (3/R_p^3) * trapz(r, c(:,t).*r.^2);
        int_v = cumtrapz(r, c(:,t).*r.^2);

        for i = 2:Nr
            avg_loc = (3/r(i)^3) * int_v(i);
            
            % Elastic Stress calculation
            raw_r = const_r * (c_avg - avg_loc);
            raw_t = const_t * (2*c_avg + avg_loc - 3*c(i,t));

            % Apply Plastic Yielding Caps
            sig_r(i,t) = max(min(raw_r, Y), -Y);
            sig_t(i,t) = max(min(raw_t, Y), -Y);
        end

        % Center Symmetry (r=0)
        center_val = const_r * (c_avg - c(1,t));
        sig_r(1,t) = max(min(center_val, Y), -Y);
        sig_t(1,t) = sig_r(1,t);
    end

    % Store results for plotting
    results.(phase_name).sigma_r_center = sig_r(1, :);
    results.(phase_name).sigma_t_surface = sig_t(Nr, :);
end



%% ── Stack Stress Calculation ────────────────────────────────────────────
% Macro-scale expansion based on Si content
total_expansion = wtSi * Omega_Si * mean(current_dist.SOC);
results.stack_stress = (total_expansion * E_Si) / 100; % Normalized to Area

end