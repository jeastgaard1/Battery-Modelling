function [results] = Mechanical_Model_Function(options, wtSi, current_dist)
% MECHANICAL_MODEL_FUNCTION
% Full Multiscale Model: 
% Micro: Particle Diffusion-Induced Stress (Si & Graphite) with Plastic Yielding
% Macro: Electrode Stack Stress based on Si weight fraction

%% ── 1. Parameters & Constants ──────────────────────────────────────────────
% Mechanical Properties
E_Si = 80e9;   nu_Si = 0.22;  Omega_Si = 9.4e-6;  % Silicon
E_Gr = 10e9;   nu_Gr = 0.30;  Omega_Gr = 3.1e-6;  % Graphite
R_Si = 50e-9;  R_Gr = 5e-6;                       % Particle Radii

% Yield Limits (Plasticity Caps)
Y_Si = 1.5e9;  % 1.5 GPa (Silicon)
Y_Gr = 0.5e9;  % 0.5 GPa (Graphite)

% Grid Setup
Nr = 50; 
steps = length(current_dist.SOC);
results.SoC = current_dist.SOC;

%% ── 2. Micro-Scale: Particle Stress Loop ──────────────────────────────────
for p = 1:2 % Phase 1: Silicon, Phase 2: Graphite
    if p == 1
        E = E_Si; nu = nu_Si; Omega = Omega_Si; R_p = R_Si; Y = Y_Si; phase_name = "Si";
    else
        E = E_Gr; nu = nu_Gr; Omega = Omega_Gr; R_p = R_Gr; Y = Y_Gr; phase_name = "Gr";
    end

    r = linspace(0, R_p, Nr);
    const_r = (2 * E * Omega) / (9 * (1 - nu));
    const_t = (E * Omega) / (9 * (1 - nu));

    sig_r = zeros(Nr, steps);
    sig_t = zeros(Nr, steps);

    for t = 1:steps
        % Concentration Profile Assumption (Parabolic)
        c_surf = current_dist.SOC(t) * (1/Omega); 
        c_profile = c_surf * (r/R_p).^2; 
        
        c_avg = (3/R_p^3) * trapz(r, c_profile.*r.^2);
        int_v = cumtrapz(r, c_profile.*r.^2);

        for i = 2:Nr
            avg_loc = (3/r(i)^3) * int_v(i);
            
            % Elastic Calculations
            raw_r = const_r * (c_avg - avg_loc);
            raw_t = const_t * (2*c_avg + avg_loc - 3*c_profile(i));

            % Apply Yield Caps (Micro-scale failure criteria)
            sig_r(i,t) = max(min(raw_r, Y), -Y);
            sig_t(i,t) = max(min(raw_t, Y), -Y);
        end

        % Center Symmetry (r=0)
        center_val = const_r * (c_avg - c_profile(1));
        sig_r(1,t) = max(min(center_val, Y), -Y);
        sig_t(1,t) = sig_r(1,t);
    end

    % Export to results structure
    results.(phase_name).sigma_r_center = sig_r(1, :);
    results.(phase_name).sigma_t_surface = sig_t(Nr, :);
end



%% ── 3. Macro-Scale: Electrode Stack Stress ───────────────────────────────
% Estimate bulk expansion based on weighted average of Si/Gr expansion
% Stack stress is proportional to the weighted partial molar volume
avg_expansion = (wtSi * Omega_Si + (1-wtSi) * Omega_Gr) * mean(current_dist.SOC);
results.stack_stress = (avg_expansion * E_Si) / 100; % Normalized unit pressure

end