function [results] = Mechanical_Model_Function(options, wtSi, current_dist)
    % Extract parameters
    m = options.mech;
    
    % FIX: Use the dynamic SOC from the electrical simulation
    SoC_sim = current_dist.SOC;
    % Clamp SOC to physical bounds for stress calculations
    SoC_sim(SoC_sim < 0) = 0;
    SoC_sim(SoC_sim > 1) = 1;
    steps = length(SoC_sim);
    dt = options.delta_t;
    F = options.constants.F;
    
    %% 1. Macro-Scale: Strain & Stack Stress
    eps_Si = SoC_sim * 2.8; 
    eps_Gr = SoC_sim * 0.1; 
    eps_NMC = -SoC_sim * 0.02; 
    
    eps_anode = (wtSi)*eps_Si + (1-wtSi)*eps_Gr;
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
    % Define properties for Silicon and Graphite phases
    phases = {'Si', 'Gr'};
    flux_data = {current_dist.j_Si/F, current_dist.j_G/F};
    
    % Material constants: [Silicon, Graphite]
    E_vals = [12e9, 10e9];           % Young's Modulus [Pa]
    D_vals = [m.D_s, 1e-14];         % Diffusion Coefficient [m^2/s]
    R_vals = [m.R_p, 5e-6];          % Particle Radius [m]
    Omega_vals = [m.Omega, 3e-6];     % Partial Molar Volume [m^3/mol]
    C_max_vals = [300000, 30000];    % Max concentration [mol/m^3]

    for p = 1:2
        phase_name = phases{p};
        flux_vec = flux_data{p};
        
        % Radial discretization
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
        const_t = (Omega_vals(p) * E_vals(p)) / (9 * (1 - m.nu));
        sig_t = zeros(Nr, steps);
        for t = 1:steps
            c_avg = (3/R_vals(p)^3) * trapz(r, c(:,t).*r.^2);
            int_v = cumtrapz(r, c(:,t).*r.^2);
            for i = 2:Nr
                avg_loc = (3/r(i)^3) * int_v(i);
                sig_t(i,t) = const_t * (2*c_avg + avg_loc - 3*c(i,t));
            end
            sig_t(1,t) = const_t * (c_avg - c(1,t)); % Center stress
        end
        
        results.(phase_name).sigma_t_surface = sig_t(Nr, :);
        results.(phase_name).max_tensile = max(sig_t(:));
    end
    results.SoC = SoC_sim;
end