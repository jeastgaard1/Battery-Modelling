function [dL_total_anode, dL_total_cathode, dL_total] = TotalExpansion(options,dL_th_anode, dL_int_anode, dL_th_cathode, dL_int_cathode,dL_th_CC_Cathode, dL_th_CC_Anode, dL_th_Separator,cell_parameters)

% Calculation of the total anode expansion (thermal + intercalation-related):
dL_total_anode   = zeros(options.seg_height,options.seg_width,options.L);       % Gesamtausdehnung der Anode [-]
dL_int_seg_anode = zeros(options.seg_height,options.seg_width,options.L);       % Ausdehnung durch Interkalation pro Segment [-]

% Addition of the thickness values ​​of all thickness elements of a segment:
dL_int_seg_anode(:,:,:) = sum(dL_int_anode(1,:,:,:,:));

% Addition of the thermal expansion of individual segments "dL_th" and the intercalation-related expansion of individual segments "dL_int_seg"
dL_total_anode(:,:,:)=dL_th_anode(1,:,:,:);
dL_total_anode(:,:,:) = dL_total_anode(:,:,:)+dL_int_seg_anode(:,:,:);


%Calculation of the total cathode expansion (thermal + intercalation-related):
dL_total_cathode   = zeros(options.seg_height,options.seg_width,options.L);       % Gesamtausdehnung der Kathode [-]
dL_int_seg_cathode = zeros(options.seg_height,options.seg_width,options.L);       % Ausdehnung durch Interkalation pro Segment [-]

% Addition of the thickness values ​​of all thickness elements of a segment:
dL_int_seg_cathode(:,:,:) = sum(dL_int_cathode(1,:,:,:,:));

% Addition of the thermal expansion of individual segments "dL_th" and the intercalation-related expansion of individual segments "dL_int_seg"
dL_total_cathode(:,:,:) = dL_th_cathode(1,:,:,:);
dL_total_cathode(:,:,:) = dL_total_cathode(:,:,:)+dL_int_seg_cathode(1,:,:,:);


% Calculation of the total expansion per segment (thermal expansion of all cell elements + intercalation-related expansion of the electrodes):
dL_total = zeros(options.seg_height,options.seg_width,options.L);
dL_total(:,:,:)=dL_th_CC_Cathode(1,:,:,:) ...
              + dL_th_CC_Anode(1,:,:,:) ...
              + dL_th_Separator(1,:,:,:);
dL_total(:,:,:) = dL_total(:,:,:)+dL_total_cathode+dL_total_anode;

end