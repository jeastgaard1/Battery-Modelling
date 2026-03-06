function [data_save] = SaveData(battery_res,data_save,options,run_variable,siW,cr)
% All of these lines of code just saves the information to the data_save
% variable.
% Save Data ###############################################################

% (rows, columsn) if there is a : then it's all the rows/columns.
data_save.time(run_variable,:)=run_variable;

for trans=1:length(options.Save.Cell(:,1))
    data_save.(options.Save.Cell{trans,:})(run_variable,siW) ...
        =battery_res.(options.Save.Cell{trans,:})(1,1);
end


data_save.T.(options.Save.T{cr,:})(run_variable,siW) ...
    =battery_res.T.(options.Save.T{cr,:})(1,:);

%% ── Current Distribution (PRAVEEN) ──────────────────────────────────────
% Current distribution is time-invariant — store as 2D (siW x cr).
% Written only at timeStep==1; all other steps are identical so no
% time dimension is needed. Plotting reads directly as (wt% x cr).
if isfield(battery_res, 'current_dist') 
    data_save.current_dist.I_Si(run_variable, siW, cr)    = battery_res.current_dist.I_Si;
    data_save.current_dist.I_G(run_variable, siW, cr)     = battery_res.current_dist.I_G;
    data_save.current_dist.j_Si(run_variable, siW, cr)    = battery_res.current_dist.j_Si;
    data_save.current_dist.j_G(run_variable, siW, cr)     = battery_res.current_dist.j_G;
    data_save.current_dist.frac_Si(run_variable, siW, cr) = battery_res.current_dist.frac_Si;
    data_save.current_dist.frac_G(run_variable, siW, cr)  = battery_res.current_dist.frac_G;
end

if isfield(battery_res, 'vol_cap') && run_variable == 1 && cr == 1
    vc = battery_res.vol_cap;

    % Common fields
    data_save.vol_cap.wtSi(siW) = vc.wtSi;
    data_save.vol_cap.G_A(siW)  = vc.G_A;
    data_save.vol_cap.P_A(siW)  = vc.P_A;

    % Case 1: Zero expansion
    data_save.vol_cap.case1.V_A(siW)          = vc.case1.V_A;
    data_save.vol_cap.case1.P_A_required(siW) = vc.case1.P_A_required;
    data_save.vol_cap.case1.P_ALi(siW)        = vc.case1.P_ALi;
    data_save.vol_cap.case1.E(siW)            = vc.case1.E;

    % Case 2: Constant porosity
    data_save.vol_cap.case2.V_A(siW)         = vc.case2.V_A;
    data_save.vol_cap.case2.V_A_array(siW,:) = vc.case2.V_A_array;
    data_save.vol_cap.case2.P_ALi(siW)       = vc.case2.P_ALi;
    data_save.vol_cap.case2.E(siW)           = vc.case2.E;

    % Case 3: Variable porosity
    data_save.vol_cap.case3.V_A(siW)   = vc.case3.V_A;
    data_save.vol_cap.case3.P_ALi(siW) = vc.case3.P_ALi;
    data_save.vol_cap.case3.E(siW)     = vc.case3.E;
end
end
