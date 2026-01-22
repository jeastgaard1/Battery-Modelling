function [battery_res,msg] = Solid_Diffusion_ECM_0D(battery_res,param,const,options,msg)
%ECM_PARAMETER_ECM_0D Summary of this function goes here
%   Detailed explanation goes here
if options.bool.ini==1                                                     %Initialization
    tempValue=1;
    
    %SoC dependend: linear fit Cmax (SoC=1) and Cmin (SoC=0)
    %Anode
    battery_res.Particle.c_Li_Anode(tempValue,1:options.seg_particle)= ...
        (param.ParticleDiffusion.Anode.Cmax-param.ParticleDiffusion.Anode.Cmin)*options.ini.SoC ...
        +param.ParticleDiffusion.Anode.Cmin;
    
    %Cathode
    battery_res.Particle.c_Li_Cathode(tempValue,1:options.seg_particle)= ...
        (param.ParticleDiffusion.Cathode.Cmax-param.ParticleDiffusion.Cathode.Cmin)*(1-options.ini.SoC) ...
        +param.ParticleDiffusion.Cathode.Cmin;
else
    tempValue=2;
    
    %in and outflow Li ions - Scale form volume element to particle based
    %on capacity content
    
    CurrAnode=zeros(1,1);
    CurrCathode=zeros(1,1);
    
    c_core=zeros(1,options.seg_particle);
    c_outer=zeros(1,options.seg_particle);
    c_eq=zeros(1,options.seg_particle-1);
    
    %Curr in mol/s
    CurrAnode(1,1)=battery_res.I(1,1)*param.ParticleDiffusion.Anode.CapaFac/const.F*options.delta_t;
    CurrCathode(1,1)=-battery_res.I(1,1)*param.ParticleDiffusion.Cathode.CapaFac/const.F*options.delta_t;
    
    %Anode ################################################################
    c_eq(1,:)=(battery_res.Particle.c_Li_Anode(tempValue-1,1:options.seg_particle-1).*param.ParticleDiffusion.Anode.dV(1:options.seg_particle-1) ...
        +battery_res.Particle.c_Li_Anode(tempValue-1,2:options.seg_particle).*param.ParticleDiffusion.Anode.dV(2:options.seg_particle)) ...
        ./(param.ParticleDiffusion.Anode.dV(1:options.seg_particle-1)+param.ParticleDiffusion.Anode.dV(2:options.seg_particle));
    
    %Exchange with two interphases
    c_core(1,1:options.seg_particle-1)=(battery_res.Particle.c_Li_Anode(tempValue-1,1:options.seg_particle-1)-c_eq(1,:)) ...
        .*exp(-options.delta_t./param.ParticleDiffusion.Anode.tau)+c_eq(1,:);
    c_outer(1,2:options.seg_particle)=(battery_res.Particle.c_Li_Anode(tempValue-1,2:options.seg_particle)-c_eq(1,:)) ...
        .*exp(-options.delta_t./param.ParticleDiffusion.Anode.tau)+c_eq(1,:);
    %Add both -> for all inner layers start concentration double time ->
    %substract one time
    battery_res.Particle.c_Li_Anode(tempValue,1:options.seg_particle)=c_core+c_outer;
    battery_res.Particle.c_Li_Anode(tempValue,2:options.seg_particle-1)=battery_res.Particle.c_Li_Anode(tempValue,2:options.seg_particle-1) ...
        -battery_res.Particle.c_Li_Anode(tempValue-1,2:options.seg_particle-1);
    
    %Li in and out flow at outer volume element
    battery_res.Particle.c_Li_Anode(tempValue,options.seg_particle)= ...
        battery_res.Particle.c_Li_Anode(tempValue,options.seg_particle)+ ...
        CurrAnode/param.ParticleDiffusion.Anode.dV(options.seg_particle);
    
    %Cathode ##############################################################
    c_eq(1,:)=(battery_res.Particle.c_Li_Cathode(tempValue-1,1:options.seg_particle-1).*param.ParticleDiffusion.Cathode.dV(1:options.seg_particle-1) ...
        +battery_res.Particle.c_Li_Cathode(tempValue-1,2:options.seg_particle).*param.ParticleDiffusion.Cathode.dV(2:options.seg_particle)) ...
        ./(param.ParticleDiffusion.Cathode.dV(1:options.seg_particle-1)+param.ParticleDiffusion.Cathode.dV(2:options.seg_particle));
    c_core(1,1:options.seg_particle-1)=(battery_res.Particle.c_Li_Cathode(tempValue-1,1:options.seg_particle-1)-c_eq(1,:)) ...
        .*exp(-options.delta_t./param.ParticleDiffusion.Cathode.tau)+c_eq(1,:);
    c_outer(1,2:options.seg_particle)=(battery_res.Particle.c_Li_Cathode(tempValue-1,2:options.seg_particle)-c_eq(1,:)) ...
        .*exp(-options.delta_t./param.ParticleDiffusion.Cathode.tau)+c_eq(1,:);
    
    battery_res.Particle.c_Li_Cathode(tempValue,1:options.seg_particle)=c_core+c_outer;
    battery_res.Particle.c_Li_Cathode(tempValue,2:options.seg_particle-1)=battery_res.Particle.c_Li_Cathode(tempValue,2:options.seg_particle-1) ...
        -battery_res.Particle.c_Li_Cathode(tempValue-1,2:options.seg_particle-1);
    
    battery_res.Particle.c_Li_Cathode(tempValue,options.seg_particle)= ...
        battery_res.Particle.c_Li_Cathode(tempValue,options.seg_particle)+ ...
        CurrCathode/param.ParticleDiffusion.Cathode.dV(options.seg_particle);
end



end

