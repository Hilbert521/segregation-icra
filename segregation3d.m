 clear all; close all; clc;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Constants (you may freely set these values).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
alpha  = 3.0;  % control gain.
dAA    = 2.0;  % distance among same types.
dAB    = 5.0;  % distance among distinct types.

% Simulation.
ROBOTS = 100;  % number of robots.
GROUPS = 5;    % number of groups.
WORLD  = 10;   % world size.
dt     = 0.01; % time step.

if mod(ROBOTS,GROUPS) ~= 0
    fprintf('ROBOTS mod GROUPS must be 0.');
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialization.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% AA(i,j) == 1 if i and j belong to the same team,  0 otherwise.
% AB(i,j) == 1 if i and j belong to distinct teams, 0 otherwise.
[i j] = meshgrid((1:ROBOTS));
gpr = GROUPS / ROBOTS;
AA  = (floor(gpr*(i-1)) == floor(gpr*(j-1)));
AB  = (floor(gpr*(i-1)) ~= floor(gpr*(j-1)));
clearvars i j;

% vectorization of dAA and dAB.
const = dAA .* AA + dAB .* AB;

% number of robots in one group.
nAA = ROBOTS / GROUPS;

% number of robots in distinct groups.
nAB = (GROUPS - 1) * ROBOTS / GROUPS;

q = WORLD * rand(ROBOTS, 3); % position.
v = zeros(ROBOTS, 3);        % velocity.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize all plots.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
simulation = figure('Backingstore', 'off', 'renderer', 'zbuffer');
hold on; axis equal; grid on; 
xlim([0 WORLD]); ylim([0 WORLD]); zlim([0 WORLD]);

color = hsv(GROUPS); 
handler = zeros(1, GROUPS);
for i = (1:GROUPS)
    handler(i) = plot3(nan, nan, nan, '.');
    start = floor((i - 1) * ROBOTS / GROUPS) + 1;
    stop  = floor(i * ROBOTS / GROUPS);
    set(handler(i),'Color',color(i,:), 'MarkerSize', 20);
    set(handler(i),'XData',q(start:stop,1), ...
                   'YData',q(start:stop,2), ...
                   'ZData',q(start:stop,3));
end
set(gca,'xticklabel',[], 'yticklabel', [], 'zticklabel', []);
set(gca,'xcolor',[0.6 0.6 0.6], ...
        'ycolor',[0.6 0.6 0.6], ...
        'zcolor',[0.6 0.6 0.6]);
view([45 45 45]);

title('Press any key to start');
waitforbuttonpress;
title('');
set(simulation, 'currentch', char(0));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Simulation.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    
while strcmp(get(simulation, 'currentch'), '')
    
    % Relative position among all pairs [q(j:2) - q(i:2)].
    xij  = bsxfun(@minus, q(:,1)', q(:,1));
    yij  = bsxfun(@minus, q(:,2)', q(:,2));
    zij  = bsxfun(@minus, q(:,3)', q(:,3));
    
    % Relative velocity among all pairs [v(j:2) - v(i:2)]..
    vxij = bsxfun(@minus, v(:,1)', v(:,1));
    vyij = bsxfun(@minus, v(:,2)', v(:,2));
    vzij = bsxfun(@minus, v(:,3)', v(:,3));
    
    % Relative distance among all pairs.
    dsqr = xij.^2 + yij.^2 + zij.^2;
    dist = sqrt(dsqr);
       
    % Control equation.
    dV = alpha .* (1.0 ./ dist - const ./ dsqr + (dist - const));
    ax = - dV .* xij ./ dist - vxij;
    ay = - dV .* yij ./ dist - vyij;
    az = - dV .* zij ./ dist - vzij;        
      
    % a(i, :) -> acceleration input for robot i.
    a = [nansum(ax)' nansum(ay)' nansum(az)'];
    
    % simple taylor expansion.
    q = q + v * dt + a * (0.5 * dt^2);
    v = v + a * dt;
    
    % Update data for drawing.
    for i = (1:GROUPS)
        start = floor((i - 1) * ROBOTS / GROUPS) + 1;
        stop  = floor(i * ROBOTS / GROUPS);
        set(handler(i),'XData',q(start:stop,1), ...
                       'YData',q(start:stop,2), ...
                       'ZData',q(start:stop,3));
    end
    drawnow;    
end