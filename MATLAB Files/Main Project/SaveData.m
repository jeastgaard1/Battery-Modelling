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

end
