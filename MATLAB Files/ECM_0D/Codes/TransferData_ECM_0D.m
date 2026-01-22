function [battery_res] = TransferData_ECM_0D(battery_res,options)
% Data transfer 2 -> 1 ####################################################
%Cell
for trans=1:length(options.Transfer.Cell(:,1))
    battery_res.(options.Transfer.Cell{trans,:})(1,:) ...
        =battery_res.(options.Transfer.Cell{trans,:})(2,:);
    battery_res.(options.Transfer.Cell{trans,:})(2,:)=0;
end

%ECM
for trans=1:length(options.Transfer.ECM(:,1))
    battery_res.ECM.(options.Transfer.ECM{trans,:})(1,:) ...
        =battery_res.ECM.(options.Transfer.ECM{trans,:})(2,:);
    battery_res.ECM.(options.Transfer.ECM{trans,:})(2,:)=0;
end

%Time
battery_res.time(1)=battery_res.time(2);
battery_res.time(2)=0;

%Partilce
for trans=1:length(options.Transfer.Particle(:,1))
    battery_res.Particle.(options.Transfer.Particle{trans,:})(1,:) ...
        =battery_res.Particle.(options.Transfer.Particle{trans,:})(2,:);
    battery_res.Particle.(options.Transfer.Particle{trans,:})(2,:)=0;
end
end
