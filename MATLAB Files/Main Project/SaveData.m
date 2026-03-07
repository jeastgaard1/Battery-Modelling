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

data_save.TVE.(options.Save.TVE{cr,:})(run_variable,siW) ...
    =battery_res.TVE.(options.Save.TVE{cr,:})(1,:);
end

