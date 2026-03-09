function [results] = Mechanical_Model_Function(options, wtSi, current_dist)
    % Extract parameters for readability
    m = options.mech;
    SoC_sim = current_dist.SOC; 
    steps = length(SoC_sim);
    
    %% 1. Macro-Scale: Strain Calculation
    % Synthetic strain (replace with mahenders volume expansion)
    eps_Si = SoC_sim * 2.8; 
    eps_Gr = SoC_sim * 0.1; 
    eps_NMC = -SoC_sim * 0.02; 
    
    eps_anode = (wtSi)*eps_Si + (1-wtSi)*eps_Gr;
    delta_L = (m.d0_anode * eps_anode) + (m.d0_cathode * eps_NMC);
    
    % Cell Stress
    Compliance = (m.d0_anode/(m.E_anode*m.Area)) + (m.d0_cathode/(m.E_cathode*m.Area)) + (m.d0_sep/(m.E_sep*m.Area));
    if strcmp(m.BoundaryCondition, 'fixed')
        results.stack_stress = (delta_L / Compliance) / m.Area;
    else
        results.stack_stress = zeros(size(SoC_sim));
    end
    results.strain = eps_anode;
    results.thickening = delta_L;

    %% 2. Micro-Scale: Particle Stress (Dynamic & Stabilized)
    % ---------------------------------------------------------------------
    % This section uses the current distribution from the Butler-Volmer 
    % model to drive the diffusion-induced stress in Silicon particles.
    % ---------------------------------------------------------------------
    
    % --- Physical Constants & Grid ---
    Nr = 50;                             % Radial nodes
    r = linspace(0, m.R_p, Nr)';         % Radial vector [m]
    dr = r(2) - r(1);
    dt = options.delta_t;                % Time step [s]
    F = options.constants.F;             % 96485 C/mol
    
    % Dynamic Flux from Current Distribution Model
    % j_Si is [A/m^2], flux is [mol/(m^2*s)]
    flux_dynamic = current_dist.j_Si / F; 
    steps = length(current_dist.j_Si);

    % --- Stabilized Implicit Diffusion Solver ---
    Fo = m.D_s * dt / dr^2;              % Fourier number
    A = zeros(Nr, Nr);
    
    % 1. Internal Nodes (Central Difference)
    for i = 2:Nr-1
        gamma = Fo * (dr / r(i));
        A(i, i-1) = -Fo + gamma;
        A(i, i)   = 1 + 2*Fo;
        A(i, i+1) = -Fo - gamma;
    end
    
    % 2. Center Boundary (r=0, Zero Flux Symmetry)
    A(1,1) = 1 + 6*Fo; 
    A(1,2) = -6*Fo; 
    
    % 3. Surface Boundary (r=R_p, Stabilized Mass Balance)
    % Ties surface concentration to both the flux and the previous state
    A(Nr, Nr-1) = -2*Fo;
    A(Nr, Nr)   = 1 + 2*Fo;
    
    % --- Time Stepping Loop ---
    c = zeros(Nr, steps);                % Concentration matrix [mol/m^3]
    c_max_physical = 300000;             % Approx max concentration for Li15Si4
    
    for t = 1:steps-1
        B = c(:,t); 
        % Incorporate surface flux into the mass accumulation term
        B(Nr) = B(Nr) + 2*Fo*dr*(flux_dynamic(t) / m.D_s); 
        
        % Solve system
        c_next = A \ B;
        
        % Numerical Safety: Prevent unphysical concentration spikes
        c_next(c_next > c_max_physical) = c_max_physical;
        c_next(c_next < 0) = 0;
        
        c(:,t+1) = c_next;
    end

    % --- Stress Calculation (Tangential) ---
    % E_Si: Lithiated Silicon is ~12-15 GPa. Pure Si is ~80 GPa.
    E_Si = 12e9; 
    const_t = (m.Omega * E_Si) / (9 * (1 - m.nu));

    sig_t = zeros(Nr, steps);
    for t = 1:steps
        % Calculate Volume-Averaged Concentration
        c_avg = (3/m.R_p^3) * trapz(r, c(:,t).*r.^2);
        
        % Calculate Local Average (Integral from 0 to current r)
        int_v = cumtrapz(r, c(:,t).*r.^2);
        
        for i = 2:Nr
            avg_loc = (3/r(i)^3) * int_v(i);
            % Tangential Stress Equation:
            % Surface (i=Nr) will be negative (compression) during lithiation
            % Core (i=1) will be positive (tension) during lithiation
            sig_t(i,t) = const_t * (2*c_avg + avg_loc - 3*c(i,t));
        end
        % Analytical limit for center node
        sig_t(1,t) = const_t * (c_avg - c(1,t)); 
    end
    
    % --- Store Results ---
    results.sigma_t_surface = sig_t(Nr, :);     % Compressive stress (negative)
    results.sigma_t_core = sig_t(1, :);        % Tensile stress (positive)
    results.max_tensile_stress = max(sig_t(:)); % For fracture analysis
    results.SoC = current_dist.SOC;             % Aligned SOC vector
    results.r_norm = r / m.R_p;                 % Normalized radius for plotting