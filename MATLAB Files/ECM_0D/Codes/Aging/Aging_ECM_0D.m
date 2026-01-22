function [battery_res] = Aging_ECM_0D(battery_res,param,options)
%AGING_ECM_0D Summary of this function goes here
%   Detailed explanation goes here

battery_res.Aging.SoH_R(1,1)=1;
battery_res.Aging.SoH_C(1,1)=1;
end

