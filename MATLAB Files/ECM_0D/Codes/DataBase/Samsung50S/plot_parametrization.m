load('PulseFit_Samsung_50S_ECM_R_3RC.mat');
%% OCV ####################################################################
h=figure;
plot(param.fit.OCV.DCH.SoC,param.fit.OCV.DCH.U,'color',[1 0 0],'linewidth',1.5)
grid on
grid minor
xlabel('Soc [-]')
ylabel('U [V]')
options.link_data='M:\xx_iontwin\02_Vaeridion\Projekt_4151-22-03\05_Model\ECM_0D\Codes\DataBase\Samsung50S\Graphics\';
print(h, '-dpdf', [options.link_data 'OCV'])
close(h)
%% Hysterese ##############################################################
h=figure;
plot(param.fit.OCV.DCH.SoC,param.fit.OCV.DCH.U,'color',[1 0 0],'linewidth',1.5)
hold on
plot(param.fit.OCV.CH.SoC,param.fit.OCV.CH.U,'color',[0 0 1],'linewidth',1.5)
grid on
grid minor
legend({'DCH';'CH'})
xlabel('Soc [-]')
ylabel('U [V]')
options.link_data='M:\xx_iontwin\02_Vaeridion\Projekt_4151-22-03\05_Model\ECM_0D\Codes\DataBase\Samsung50S\Graphics\';
print(h, '-dpdf', [options.link_data 'Hysterese'])
close(h)
%% R dependency to SOC ####################################################
T=25;
SoC=linspace(0,1,100)';
R=param.fit.DCH.R0(SoC,T);
h=figure;
plot(SoC, R*1000,'color',[1 0 0],'linewidth',1.5)
grid on
grid minor
xlabel('SoC [-]')
ylabel('R [m\Omega]')
options.link_data='M:\xx_iontwin\02_Vaeridion\Projekt_4151-22-03\05_Model\ECM_0D\Codes\DataBase\Samsung50S\Graphics\';
print(h, '-dpdf', [options.link_data 'R_DCH'])
close(h)
%% R dependency to T ####################################################
T=linspace(5,45,100);
SoC=0.25;
R=zeros(100,1);
for i=1:100
R(i)=param.fit.DCH.R0(SoC,T(i));
end
h=figure;
plot(T, R*1000,'color',[1 0 0],'linewidth',1.5)
grid on
grid minor
xlabel('T [°C]')
ylabel('R [m\Omega]')
options.link_data='M:\xx_iontwin\02_Vaeridion\Projekt_4151-22-03\05_Model\ECM_0D\Codes\DataBase\Samsung50S\Graphics\';
print(h, '-dpdf', [options.link_data 'R_DCH_T'])
close(h)
%% Surface plot ###########################################################
h=figure;
plot(param.fit.DCH.R0)
view([65 25])
ylabel('T [°C]')
xlabel('SoC [-]')
zlabel('R [\Omega]')
options.link_data='M:\xx_iontwin\02_Vaeridion\Projekt_4151-22-03\05_Model\ECM_0D\Codes\DataBase\Samsung50S\Graphics\';
print(h, '-dpdf', [options.link_data 'R_DCH_Surf'])
close(h)

h=figure;
plot(param.fit.CH.R0)
view([65 25])
ylabel('T [°C]')
xlabel('SoC [-]')
zlabel('R [\Omega]')
options.link_data='M:\xx_iontwin\02_Vaeridion\Projekt_4151-22-03\05_Model\ECM_0D\Codes\DataBase\Samsung50S\Graphics\';
print(h, '-dpdf', [options.link_data 'R_CH_Surf'])
close(h)

%% RC3 dependency to SOC ####################################################
T=25;
SoC=linspace(0,1,100)';
R=param.fit.DCH.R_RC3(SoC,T);
tau=param.fit.DCH.tau_RC3(SoC,T);
h=figure;
subplot(1,2,1)
plot(SoC, R*1000,'color',[1 0 0],'linewidth',1.5)
grid on
grid minor
xlabel('SoC [-]')
ylabel('R [m\Omega]')
subplot(1,2,2)
plot(SoC, tau,'color',[1 0 0],'linewidth',1.5)
grid on
grid minor
xlabel('SoC [-]')
ylabel('\tau [s]')
options.link_data='M:\xx_iontwin\02_Vaeridion\Projekt_4151-22-03\05_Model\ECM_0D\Codes\DataBase\Samsung50S\Graphics\';
print(h, '-dpdf', [options.link_data 'RC3_DCH'])
close(h)
%% RC3 dependency to T ####################################################
T=linspace(5,45,100);
SoC=0.25;
R=zeros(100,1);
tau=zeros(100,1);
for i=1:100
R(i)=param.fit.DCH.R_RC3(SoC,T(i));
tau(i)=param.fit.DCH.tau_RC3(SoC,T(i));
end
h=figure;
subplot(1,2,1)
plot(T, R*1000,'color',[1 0 0],'linewidth',1.5)
grid on
grid minor
xlabel('T [°C]')
ylabel('R [m\Omega]')
subplot(1,2,2)
plot(T,tau,'color',[1 0 0],'linewidth',1.5)
grid on
grid minor
xlabel('T [°C]')
ylabel('\tau [s]')
options.link_data='M:\xx_iontwin\02_Vaeridion\Projekt_4151-22-03\05_Model\ECM_0D\Codes\DataBase\Samsung50S\Graphics\';
print(h, '-dpdf', [options.link_data 'RC3_DCH_T'])
close(h)

%% Surface plot ###########################################################
h=figure;
plot(param.fit.DCH.R_RC3)
view([65 25])
ylabel('T [°C]')
xlabel('SoC [-]')
zlabel('R [\Omega]')
options.link_data='M:\xx_iontwin\02_Vaeridion\Projekt_4151-22-03\05_Model\ECM_0D\Codes\DataBase\Samsung50S\Graphics\';
print(h, '-dpdf', [options.link_data 'R_DCH_Surf'])
close(h)

h=figure;
plot(param.fit.CH.R_RC3)
view([65 25])
ylabel('T [°C]')
xlabel('SoC [-]')
zlabel('R [\Omega]')
options.link_data='M:\xx_iontwin\02_Vaeridion\Projekt_4151-22-03\05_Model\ECM_0D\Codes\DataBase\Samsung50S\Graphics\';
print(h, '-dpdf', [options.link_data 'RC3_CH_Surf'])
close(h)