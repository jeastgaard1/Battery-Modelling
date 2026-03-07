%% plot_param_volthev.m
clear; clc; close all;

% Build options + params
[options, msg] = options_ECM_VolThev;
wtSi  = 0.10;   % change this
cRate = 1.0;    % change this

param = ECM_Parameter_ECM_VolThev(options, wtSi, cRate);

% Time axis (use the same "time_span" indexing used in your param functions)
t = options.time_span;   % 1..N

% Evaluate key signals
za  = arrayfun(param.za, t);          % anode SOC vs "time index"
zc  = arrayfun(param.zc, t);          % cathode SOC
Vex = arrayfun(param.Volexp, t);      % volume expansion proxy
Uan = arrayfun(param.OCV_anode, t);   % anode OCV
Uca = arrayfun(param.OCV_cathode, t); % cathode OCV
Uoc = arrayfun(param.UCell, t);       % cell OCV (cathode-anode)

R0  = arrayfun(param.R0, t);
R1  = arrayfun(param.R1, t);
R2  = arrayfun(param.R2, t);
Rtot= arrayfun(param.Rtot, t);

C1  = arrayfun(param.C1, t);
C2  = arrayfun(param.C2, t);

% --- Plot 1: SOC vs time index
figure; plot(t, za, 'LineWidth', 2); grid on;
xlabel('t index'); ylabel('z_a (anode SOC)'); title('Anode SOC vs time index');

% --- Plot 2: Volume expansion vs SOC (this is closest to your task)
figure; plot(za, Vex, 'LineWidth', 2); grid on;
xlabel('z_a (SOC)'); ylabel('Volexp (proxy)'); title(sprintf('Volume expansion proxy vs SOC (wtSi=%.2f)', wtSi));

% --- Plot 3: OCV curves vs SOC
figure; hold on; grid on;
plot(za, Uan, 'LineWidth', 2);
plot(zc, Uca, 'LineWidth', 2);
xlabel('SOC'); ylabel('OCV [V]'); title('Electrode OCV vs SOC');
legend('Anode OCV','Cathode OCV','Location','best');

% --- Plot 4: Cell OCV vs time index
figure; plot(t, Uoc, 'LineWidth', 2); grid on;
xlabel('t index'); ylabel('U_{cell,OCV} [V]'); title('Cell OCV vs time index');

% --- Plot 5: Resistances vs SOC
figure; hold on; grid on;
plot(za, R0, 'LineWidth', 2);
plot(za, R1, 'LineWidth', 2);
plot(za, R2, 'LineWidth', 2);
plot(za, Rtot, 'LineWidth', 2);
xlabel('z_a (SOC)'); ylabel('Resistance [Ohm]');
title('R0, R1, R2, Rtot vs SOC (volume-coupled)');
legend('R0','R1','R2','Rtot','Location','best');

% --- Plot 6: Capacitances vs SOC
figure; hold on; grid on;
plot(za, C1, 'LineWidth', 2);
plot(za, C2, 'LineWidth', 2);
xlabel('z_a (SOC)'); ylabel('Capacitance [F]');
title('C1, C2 vs SOC (volume-coupled)');
legend('C1','C2','Location','best');
