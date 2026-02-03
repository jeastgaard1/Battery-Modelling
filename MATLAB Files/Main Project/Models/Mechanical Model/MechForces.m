function [sigma_cell,epsilon_separator,epsilon_BufferLayer,epsilon_anode,epsilon_cathode] = MechForces(deltaL_total, options, cell_parameters)
%Berechnung der Spannungen und Dehnungen der einzelnenen Zellelemente beim
%Verspannen der Zelle

%defining Matrix-Element_Structure:
epsilon_anode       = zeros(options.seg_height, options.seg_width);
epsilon_cathode     = zeros(options.seg_height, options.seg_width);
epsilon_separator   = zeros(options.seg_height, options.seg_width);  
epsilon_BufferLayer = zeros(options.seg_height, options.seg_width);      
epsilon_cell        = zeros(options.seg_height, options.seg_width);
sigma_cell          = zeros(options.seg_height, options.seg_width);


%Randbedingungen: 
% 1. sigma_cell    = sigma_CCAnode = sigma_Anode = sigma_Cathode = simga_CCCathode = sigma_Separator = sigma_preload
% 2. epsilon_cell  = epsilon_CCAnode + epsilon_Anode + epsilon_Cathode + epsilon_CCCathode + epsilon_Separator + epsilon_preload
strain_preload=zeros(options.seg_height, options.seg_width);
strain_preload(:,:)=interp1(cell_parameters.stress_stepwise,cell_parameters.strain_ges,options.stress_preload, 'spline')*ones(options.seg_height, options.seg_width);

%Determine strain and stress of the cell:
epsilon_cell(:,:) = 2*sum(deltaL_total(1,:,:,:),4)/cell_parameters.Thickness.thickness_ges; %deltaL_total expansion of half cell
sigma_cell(:,:) = interp1(cell_parameters.strain_ges,cell_parameters.stress_stepwise,epsilon_cell(:,:)+strain_preload(:,:),'spline');
%epsilon_cell(:,:) = interp1(cell_parameters.stress_stepwise,cell_parameters.strain_ges,sigma_cell(:,:),'spline');
%Strain of all elements:
epsilon_separator(:,:)    = interp1(cell_parameters.stress_stepwise,cell_parameters.separator_strain_stepwise,sigma_cell(:,:),'spline');
epsilon_anode(:,:)        = interp1(cell_parameters.stress_stepwise,cell_parameters.anode_strain_stepwise,sigma_cell(:,:),'spline');
epsilon_cathode(:,:)      = interp1(cell_parameters.stress_stepwise,cell_parameters.cathode_strain_stepwise,sigma_cell(:,:),'spline');
epsilon_BufferLayer(:,:)  = interp1(cell_parameters.stress_stepwise,cell_parameters.bufferlayer_strain_stepwise,sigma_cell(:,:),'spline');
end 