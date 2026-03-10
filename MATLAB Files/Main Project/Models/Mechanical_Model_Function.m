function [results] = Mechanical_Model_Function(options, param, current_dist, SOC_exp_ref, VV0_profile)
    % Extract parameters
    m = options.mech;
    SoC_sim = current_dist.SOC;
    % SoC_sim(SoC_sim < 0) = 0;
    % SoC_sim(SoC_sim > 1) = 1;
    steps = length(param.NMC_OCV(:,1));
    dt = options.delta_t;
    F = options.constants.F;
    
    %% 1. Macro-Scale: Strain & Stack Stress
    % Use expansion values from options
    eps_Si_max = options.materials.e_Si / 100; % e.g., 2.8
    eps_Gr_max = options.materials.e_G / 100;  % e.g., 0.1
    eps_NMC = -SoC_sim * 0.02; % Cathode contraction
    
    [SOC_ref_unique, idx] = unique(SOC_exp_ref);
    VV0_unique = VV0_profile(idx);

    eps_anode = interp1(SOC_ref_unique, VV0_unique - 1, SoC_sim, 'linear', 'extrap');
    delta_L = (m.d0_anode * eps_anode) + (m.d0_cathode * eps_NMC);
    
    % Cell Stress Calculation
    Compliance = (m.d0_anode/(m.E_anode*m.Area)) + ...
                 (m.d0_cathode/(m.E_cathode*m.Area)) + ...
                 (m.d0_sep/(m.E_sep*m.Area));
                 
    if strcmp(m.BoundaryCondition, 'fixed')
        results.stack_stress = (delta_L / Compliance) / m.Area;
    else
        results.stack_stress = zeros(size(SoC_sim));
    end
    results.strain = eps_anode;
    results.thickening = delta_L;

    %% 2. Micro-Scale: Multi-Phase Particle Stress
    phases = {'Si', 'Gr'};
    % Corrected to ensure we use the right input names
    flux_data = {current_dist.j_Si/F, current_dist.j_G/F}; 
    
    E_vals = [m.E_anode, 10e9];          
    D_vals = [m.D_s, 1e-14];         
    R_vals = [m.R_p, options.particles.r_G];          
    Omega_vals = [m.Omega, 3e-6];     
    C_max_vals = [300000, 30000];    

    for p = 1:2
        phase_name = phases{p};
        flux_vec = flux_data{p};

        Nr = 50; 
        r = linspace(0, R_vals(p), Nr)'; 
        dr = r(2)-r(1);
        Fo = D_vals(p) * dt / dr^2;

         % Diffusion Matrix (A)
        A = zeros(Nr, Nr);
        for i = 2:Nr-1
            gamma = Fo * (dr / r(i));
            A(i, i-1) = -Fo + gamma; A(i, i) = 1 + 2*Fo; A(i, i+1) = -Fo - gamma;
        end
        A(1,1) = 1+6*Fo; A(1,2) = -6*Fo;
        A(Nr, Nr-1) = -2*Fo; A(Nr, Nr) = 1 + 2*Fo;

        % Solve Concentrations
        c = zeros(Nr, steps);
        for t = 1:steps-1
            B = c(:,t);
            B(Nr) = B(Nr) + 2*Fo*dr*(flux_vec(t) / D_vals(p));
            c_next = A \ B;
            % Numerical safety caps
            c_next(c_next < 0) = 0;
            c_next(c_next > C_max_vals(p)) = C_max_vals(p);
            c(:,t+1) = c_next;
        end

        % Compute Tangential Stress
        const_tr = (Omega_vals(p) * E_vals(p)) / (9 * (1 - m.nu));
        sig_t = zeros(Nr, steps);
        for t = 1:steps
            c_avg = (3/R_vals(p)^3) * trapz(r, c(:,t).*r.^2);
            int_v = cumtrapz(r, c(:,t).*r.^2);
            for i = 2:Nr
                avg_loc = (3/r(i)^3) * int_v(i);
                sig_t(i,t) = const_tr * (2*c_avg + avg_loc - 3*c(i,t));
                sig_r(i,t) = const_tr * (c_avg - avg_loc);
            end
            sig_t(1,t) = const_tr * (c_avg - c(1,t)); % Center stress
            sig_r(1,t) = sig_t(1,t);
        end
        
        results.(phase_name).sigma_t_surface = sig_t(Nr, :);
        results.(phase_name).sigma_r_center = sig_r(1, :);
        results.(phase_name).max_tensile = max(sig_t(:));
        results.SoC = SoC_sim;
    end
end