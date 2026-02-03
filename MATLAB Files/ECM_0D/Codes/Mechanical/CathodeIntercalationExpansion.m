function [dL_int_cathode] = CathodeIntercalationExpansion(options,cell_parameters,SoC,sort)

%CathodeIntercalationExpansion: Calculation of the thickness change of the
%cathode due to the average lithium concentration in the
%particles as a function of the SoC per thickness element:

%deifning Matrix-Element_Structure:
dL_int_cathode =        zeros(options.seg_thickness,options.seg_height,options.seg_width,options.L); % change in thickness in the cathode [-]
y =                     zeros(options.seg_thickness,options.seg_height,options.seg_width,options.L); % stoichiometry factor y in LiCoO2 [-]
dV_crystal_cathode =    zeros(options.seg_thickness,options.seg_height,options.seg_width,options.L); % volume change in the crystal structure of the cathode [%]
u_Rp_cathode =          zeros(options.seg_thickness,options.seg_height,options.seg_width,options.L); % radial displacement u at radius Rp [m]

dV_p_cathode = zeros(options.seg_thickness,options.seg_height,options.seg_width,options.L); % volume change of the representative particle [-]


% Calculation of the stoichiometry factor y:
y(:,:,:,:) = cell_parameters.StochiometricNumbers.Cathode_y0 + (cell_parameters.StochiometricNumbers.Cathode_y100 - cell_parameters.StochiometricNumbers.Cathode_y0) * (1-SoC(1,:,:,:,:));
%y(:,:,:,:) = cell_parameters.StochiometricNumbers.Cathode_y0 + (cell_parameters.StochiometricNumbers.Cathode_y100 - cell_parameters.StochiometricNumbers.Cathode_y0) * (1-simple.Thickness.SOC_Cathode(1,:,:,:,:));

% Interpolation of the volume change "dV_crystal_cathode" in the crystal structure of the anode active material from lookup table as a function of the stoichiometry x:
dV_crystal_cathode(:,:,:,:) = interp1(sort.Cathode_y,sort.CathodeDeltaV,y(:,:,:,:));


% Calculation of the radial displacement "u_Rp_cathode" at radius Rp by intercalation of lithium ions:
u_Rp_cathode(:,:,:,:)= 1/3 * cell_parameters.ParticleDiffusion.Cathode.R * dV_crystal_cathode(:,:,:,:) *0.01;

% Calculation of the volume change "dV_p_cathode" of the representative round particle:
dV_p_cathode(:,:,:,:) = ((4/3* pi * (cell_parameters.ParticleDiffusion.Cathode.R + u_Rp_cathode).^3) - (4/3* pi * (cell_parameters.ParticleDiffusion.Cathode.R).^3)) / (4/3* pi * (cell_parameters.ParticleDiffusion.Cathode.R).^3);


% Calculation of the thickness change "dL_int_cathode" of the thickness elements of the anode:
dL_int_cathode(:,:,:,:) = cell_parameters.ActivematerialVolumeFraction.Cathode * dV_p_cathode(:,:,:,:)...
    *cell_parameters.Thickness.Cathode/options.seg_thickness;
end