%% This is a test of multi trail with parallel updating
% Programed by Yunkai Cui
% This is a testing of all the function implementation
run init
%% Initialization
% Initialize system
N = 2; % number of links
linkages = ones(N,1)*0.1;   % legnth of links
dest_pos = [0.1; 0.1];     % Desired position
theta = zeros(N,1);         % Initial joint angle
state.lengths = linkages;
state.angles = theta;
discount = 0.99;

% Initialize Gaussian Policy Model
k = rand(N, N+1);
sigma = 0.001*rand(N,1);
% system dynamic function: \dot{x} = A*x + B*u
A = zeros(N); % System dynamic
B = eye(N); % System dynamic
Q = eye(2); % weight of distance on reward
R = eye(N); % weight of angular velocity in reward
eta = 1;    % importance factor of angular velocity
t = 0.01;
discretize = 10000;
policy = initGaussPolicy(k,sigma,A, B, Q, R, eta, t, discretize);

% Initialize simulation
max_exploration = 500; % depends on discount^max_exploration
trail_num = 100;        % number of trails to try

% Turn on the profiler
profile on
%% Begin multi trail exploration
% b_num = 0;
% b_den = 0;
g_rf_first = zeros(size(policy.theta.k));
g_rf_second = zeros(size(policy.theta.k));
b_his_1 = zeros(trail_num,1);
b_his_2 = zeros(trail_num,1);
% delete(gcp);
poolobj = parpool;
parfor tr = 1:trail_num
%% Begin One Trail Exploration
    trail_state = state;
    trail_policy = policy;
    a_l = 1;
    accum_reward = 0;
    accum_dlogpi_dtheta = zeros(size(policy.theta.k));
    for i = 1:max_exploration
        x = getFeatures(trail_state);
        u = drawAction(trail_policy,x);
        trail_state.angles = mod(drawNextState(trail_policy, trail_state.angles,u),2*pi);
        reward = getRewardLQR(trail_state, dest_pos, trail_policy, u);
        accum_reward = accum_reward + a_l*reward;
        a_l = a_l*discount;
        gradient_log_pi = DlogPiDthetaLinearApproximation(x,u,trail_policy);
    %     gradient_log_pi.k
        accum_dlogpi_dtheta = accum_dlogpi_dtheta + gradient_log_pi.k;
        % run simulation
%         FKanimate(trail_state.angles, dest_pos, trail_state.lengths, i);
    end
%     b_num = b_num + reshape(accum_dlogpi_dtheta,1,[])*reshape(accum_dlogpi_dtheta,[],1)*accum_reward;
%     b_den = b_den + reshape(accum_dlogpi_dtheta,1,[])*reshape(accum_dlogpi_dtheta,[],1);
    g_rf_first = g_rf_first + accum_dlogpi_dtheta*accum_reward;
    g_rf_second = g_rf_second + accum_dlogpi_dtheta;
    b_his_1(tr) = reshape(accum_dlogpi_dtheta,1,[])*reshape(accum_dlogpi_dtheta,[],1)*accum_reward;
    b_his_2(tr) = reshape(accum_dlogpi_dtheta,1,[])*reshape(accum_dlogpi_dtheta,[],1);
end
b = mean(b_his_1)/mean(b_his_2);
Gk = g_rf_first - g_rf_second*b;
Gk = Gk/trail_num;
delete(poolobj);
Gk
profile off
profile viewer