close all

data = load("BatteryData\ThicknessChange\Data4SiO_Gr\mechanicalProperties.mat");


figure; hold on;

subplot(2,2,1);
plot(data.mech.Gr_Dch.Stoch, data.mech.Gr_Dch.deltaV,".");
title("Graphite Discharge")
ylabel("deltaV")
xlabel("SOC")

subplot(2,2,2);
plot(data.mech.SiO_Dch.Stoch, data.mech.SiO_Dch.deltaV,".");
title("Silicon Oxide Discharge")
ylabel("deltaV")
xlabel("SOC")

subplot(2,2,3);
plot(data.mech.NMC_Dch.SoC, data.mech.NMC_Dch.deltaV,".");
title("Nickel Maganese Cobalt Discharge")
ylabel("deltaV")
xlabel("SOC")

subplot(2,2,4);
plot(data.mech.LCO.Stoch, data.mech.LCO.deltaV,"-");
title("Lithium Cobalt Oxide Discharge")
ylabel("deltaV")
xlabel("SOC")

