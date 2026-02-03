function [dL_int_anode] = AnodeIntercalationExpansion (options,cell_parameters,SoC,sort)

%AnodeIntercalationExpansion: Berechnung der Dickenänderung der
%Anode aufgrund der durchschnittlichen Lithiumkonzentration in den
%Partikeln in Abhängigkeit des SoC je Dickenelement:

%deifning Matrix-Element_Structure:options.seg_thickness
dL_int_anode        = zeros(options.seg_thickness,options.seg_height,options.seg_width,options.L);      % Dickenänderung [-]
x                   = zeros(options.seg_thickness,options.seg_height,options.seg_width,options.L);      % Stöchiometriefaktor x in LiC6 [-]
dV_crystal_anode    = zeros(options.seg_thickness,options.seg_height,options.seg_width,options.L);      % Volumenänderung in der Kristallstruktur [%]
u_Rp_anode          = zeros(options.seg_thickness,options.seg_height,options.seg_width,options.L);      % radiale Verschiebung u bei Radius Rp [m]
dV_p_anode          = zeros(options.seg_thickness,options.seg_height,options.seg_width,options.L);      % Volumenänderung des repräsentativen Partikels [-]



% Berechnung des Stöchiometriefaktors x:
x = cell_parametersStochiometricNumbers.Anode_x0 ...
    + (cell_parametersStochiometricNumbers.Anode_x100 - cell_parametersStochiometricNumbers.Anode_x0) * SoC(1,:,:,:,:);

% Interpolation der Volumenänderung "dV_crystal_anode" in der Kristallstruktur des Anoden-Aktivmaterials aus Lookup-Table in Abhängigkeit der Stöchiometrie x:
dV_crystal_anode = interp1(sort.Anode_x,sort.AnodeDeltaV,x,'spline');

% Berechnung der radialen Verschiebung "u_Rp_anode" bei Radius Rp durch interkalation der Lithium-Ionen:
u_Rp_anode= 1/3 * cell_parameters.ParticleDiffusion.Anode.R * dV_crystal_anode *0.01;

% Berechnung der Volumenänderung "dV_p_anode" des repräsentativen runden Partikels:
dV_p_anode= ((4/3* pi * (cell_parametersParticleDiffusion.Anode.R + u_Rp_anode).^3) ...
    - (4/3* pi * (cell_parametersParticleDiffusion.Anode.R).^3)) / (4/3* pi * (cell_parametersParticleDiffusion.Anode.R).^3);

% Berechnung der Dickenänderung "dL_int_anode" der Dickenelemente der Anode:
dL_int_anode = cell_parametersActivematerialVolumeFraction.Anode*dV_p_anode ...
    *cell_parametersThickness.Anode/options.seg_thickness; 

end