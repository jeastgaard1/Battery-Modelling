function [] = MechForces(deltaL_total, options)
%Berechnung der Spannungen und Dehnungen der einzelnenen Zellelemente beim
%Verspannen der Zelle

delta_V_Gr = SoC * eps_Gr;
delta_V_Si = zeros(size(SoC));
delta_V_Si(SoC > 0.2) = (SoC(SoC > 0.2) - 0.2) * eps_Si; % Slide 31

% Weighted anode expansion
delta_d_free_anode = d0_anode * ( (Gr_wt_percent/100)*delta_V_Gr + (Si_wt_percent/100)*delta_V_Si );
delta_d_free_cathode = d0_cathode * SoC * eps_NMC;
delta_d_free_total = delta_d_free_anode + delta_d_free_cathode;

%% 3. Mechanical Constraints & Stress Evolution (Slide 43)
% Effective stiffness of the cell (Serial spring connection)
k_cell = 1 / ( (d0_anode/(E_anode*Area)) + (d0_cathode/(E_cathode*Area)) + (d0_sep/(E_sep*Area)) );

if E_env == inf
    % Fixed Boundary: Stress increases to cancel delta_d_free
    Force = delta_d_free_total * k_cell;
    Stress = Force / Area;
    d_actual_cell = d0_anode + d0_cathode + d0_sep; % Constant length
else
    % Free Boundary: Cell expands, zero external stress
    Stress = zeros(size(SoC));
    d_actual_cell = (d0_anode + d0_cathode + d0_sep) + delta_d_free_total;
end

%% 4. Porosity Change Calculation (Slide 31, 43)
% Under fixed boundary, expanding material consumes pore volume
V_total_anode = d0_anode * Area;
V_solid_0 = V_total_anode * (1 - 0.3); % Initial 30% porosity
V_solid_active = V_solid_0 + (delta_d_free_anode * Area);
Porosity = 1 - (V_solid_active / V_total_anode);

%% 5. Visualization
figure('Name', 'Mechanical Behavior');
subplot(3,1,1);
plot(SoC*100, delta_d_free_total*1e6, 'LineWidth', 2);
title('Free Thickness Expansion'); ylabel('\Delta d_{free} [\mu m]'); grid on;

subplot(3,1,2);
plot(SoC*100, Stress/1e6, 'r', 'LineWidth', 2);
title('Stress Evolution'); ylabel('Stress [MPa]'); grid on;

subplot(3,1,3);
plot(SoC*100, Porosity*100, 'g', 'LineWidth', 2);
title('Anode Porosity Change'); xlabel('SoC [%]'); ylabel('Porosity [%]'); grid on;

end 