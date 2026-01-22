function [dL_total_anode, dL_total_cathode, dL_total] = TotalExpansion(options,dL_th_anode, dL_int_anode, dL_th_cathode, dL_int_cathode,dL_th_CC_Cathode, dL_th_CC_Anode, dL_th_Separator,cell_parameters)

%Berechnung der gesamten Anodenausdehnung (thermisch + interkalationsbedingt):
dL_total_anode   = zeros(options.seg_height,options.seg_width,options.L);       % Gesamtausdehnung der Anode [-]
dL_int_seg_anode = zeros(options.seg_height,options.seg_width,options.L);       % Ausdehnung durch Interkalation pro Segment [-]

% Additon der Dickenwerte aller Dickenelemente eines Segmentes:
dL_int_seg_anode(:,:,:) = sum(dL_int_anode(1,:,:,:,:));
% Addition der thermischen Ausdehnung einzelner Segmente "dL_th" und der interkalationsbedingten Ausdehnung einzelner Segmente "dL_int_seg"

dL_total_anode(:,:,:)=dL_th_anode(1,:,:,:);
dL_total_anode(:,:,:) = dL_total_anode(:,:,:)+dL_int_seg_anode(:,:,:);


%Berechnung der gesamten Kathodenausdehnung (thermisch + interkalationsbedingt):
dL_total_cathode   = zeros(options.seg_height,options.seg_width,options.L);       % Gesamtausdehnung der Kathode [-]
dL_int_seg_cathode = zeros(options.seg_height,options.seg_width,options.L);       % Ausdehnung durch Interkalation pro Segment [-]

% Additon der Dickenwerte aller Dickenelemente eines Segmentes:
dL_int_seg_cathode(:,:,:) = sum(dL_int_cathode(1,:,:,:,:));

% Addition der thermischen Ausdehnung einzelner Segmente "dL_th" und der interkalationsbedingten Ausdehnung einzelner Segmente "dL_int_seg"
dL_total_cathode(:,:,:) = dL_th_cathode(1,:,:,:);
dL_total_cathode(:,:,:) = dL_total_cathode(:,:,:)+dL_int_seg_cathode(1,:,:,:);


%Berechnung der Gesamtausdehnung pro Segment (thermische Dehnung aller Zellelemente + interkalationsbedingte Dehnung der Elektroden):
dL_total = zeros(options.seg_height,options.seg_width,options.L);
dL_total(:,:,:)=dL_th_CC_Cathode(1,:,:,:) ...
              + dL_th_CC_Anode(1,:,:,:) ...
              + dL_th_Separator(1,:,:,:);
dL_total(:,:,:) = dL_total(:,:,:)+dL_total_cathode+dL_total_anode;

end