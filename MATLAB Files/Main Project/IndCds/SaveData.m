function [data_save] = SaveData(battery_res,data_save,options,run_variable)
% All of these lines of code just saves the information to the data_save
% variable.
% Save Data ###############################################################

% (rows, columsn) if there is a : then it's all the rows/columns.
data_save.time(run_variable,:)=battery_res.time(1,:);

for trans=1:length(options.Save.Cell(:,1))
    data_save.(options.Save.Cell{trans,:})(run_variable,:) ...
        =battery_res.(options.Save.Cell{trans,:})(1,:);
end
%ECM
for trans=1:length(options.Save.ECM(:,1))
    data_save.ECM.(options.Save.ECM{trans,:})(run_variable,:) ...
        =battery_res.ECM.(options.Save.ECM{trans,:})(1,:);
end


%Particle
for trans=1:length(options.Save.Particle(:,1))
    data_save.Particle.(options.Save.Particle{trans,:})(run_variable,:) ...
        =battery_res.Particle.(options.Save.Particle{trans,:})(1,:);
end
end

