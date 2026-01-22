function [dL_int_cathode] = CathodeIntercalationExpansion(options,cell_parameters,SoC,sort)

%CathodeIntercalationExpansion: Berechnung der Dickenänderung der
%Kathode aufgrund der durchschnittlichen Lithiumkonzentration in den
%Partikeln in Abhängigkeit des SoC je Dickenelement:

%deifning Matrix-Element_Structure:
dL_int_cathode      = zeros(options.seg_thickness,options.seg_height,options.seg_width,options.L);      % Dickenänderung in der Kathode [-]
y                   = zeros(options.seg_thickness,options.seg_height,options.seg_width,options.L);      % Stöchiometriefaktor y in LiCoO2 [-]
dV_crystal_cathode  = zeros(options.seg_thickness,options.seg_height,options.seg_width,options.L);      % Volumenänderung in der Kristallstruktur der Kathode [%]
u_Rp_cathode        = zeros(options.seg_thickness,options.seg_height,options.seg_width,options.L);      % radiale Verschiebung u bei Radius Rp [m]
dV_p_cathode        = zeros(options.seg_thickness,options.seg_height,options.seg_width,options.L);      % Volumenänderung des repräsentativen Partikels [-]



% Berechnung des Stöchiometriefaktors y:
y(:,:,:,:) = cell_parameters.StochiometricNumbers.Cathode_y0 + (cell_parameters.StochiometricNumbers.Cathode_y100 - cell_parameters.StochiometricNumbers.Cathode_y0) * (1-SoC(1,:,:,:,:));
%y(:,:,:,:) = cell_parameters.StochiometricNumbers.Cathode_y0 + (cell_parameters.StochiometricNumbers.Cathode_y100 - cell_parameters.StochiometricNumbers.Cathode_y0) * (1-simple.Thickness.SOC_Cathode(1,:,:,:,:));

% Interpolation der Volumenänderung "dV_crystal_cathode" in der Kristallstruktur des Anoden-Aktivmaterials aus Lookup-Table in Abhängigkeit der Stöchiometrie x:
dV_crystal_cathode(:,:,:,:) = interp1(sort.Cathode_y,sort.CathodeDeltaV,y(:,:,:,:));


% Berechnung der radialen Verschiebung "u_Rp_cathode" bei Radius Rp durch interkalation der Lithium-Ionen:
u_Rp_cathode(:,:,:,:)= 1/3 * cell_parameters.ParticleDiffusion.Cathode.R * dV_crystal_cathode(:,:,:,:) *0.01;

% Berechnung der Volumenänderung "dV_p_cathode" des repräsentativen runden Partikels:
dV_p_cathode(:,:,:,:) = ((4/3* pi * (cell_parameters.ParticleDiffusion.Cathode.R + u_Rp_cathode).^3) - (4/3* pi * (cell_parameters.ParticleDiffusion.Cathode.R).^3)) / (4/3* pi * (cell_parameters.ParticleDiffusion.Cathode.R).^3);


% Berechnung der Dickenänderung "dL_int_cathode" der Dickenelemente der Anode:
dL_int_cathode(:,:,:,:) = cell_parameters.ActivematerialVolumeFraction.Cathode * dV_p_cathode(:,:,:,:)...
    *cell_parameters.Thickness.Cathode/options.seg_thickness;

end