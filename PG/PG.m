% High-level PG function
%% Initialization
max_iter = 10000;
step_thresh = 0.001;
reach_desination_thres = 0.008;

% Initialize linked arms
% TODO: write a function for this
theta = zeros(2,1);
linkages = ones(2,1)*0.1;
dest_pos = [0.1; 0.1];
states.lengths = linkages;
% states.angles = theta;
% states.angular_velocities = theta;

% Initialize model matrix
features = getFeatures(states);
% model = rand(length(states.angles), length(features));
model = [4 0 0; 0 -4 4*1.5707963];
matrix_stationary_thres = 1e-6;

% Needs to attempt to learn M by repeatedly calling pgUpdate, for at most
% max_iter iterations or until converges (nothing updates by more than
% step_thresh)
%% Start running the main loop
profile on
distances = zeros(max_iter, 1);
rewards = zeros(max_iter, 1);
for i = 1:max_iter
    features = getFeatures(states);
    grad = gradient(states, model, dest_pos);
    model_his = model;
    model = pgUpdate(model, grad);
    angular_vel = model*features;
    states.angular_velocities = angular_vel;
    states.angles = states.angles + angular_vel*step_thresh;
    % return when matrix converged
    if norm(reshape(model - model_his,1,[])) <= matrix_stationary_thres
        break
    end
    [X, Y] = FK2D(states.angles, states.lengths);
    end_effector = [X(end), Y(end)]';
    % reset the angles after reach the final position
%     if norm(dest_pos - end_effector) <= reach_desination_thres
%         states.angles = zeros(2,1);
%     end
    rewards(i) = getReward(states, dest_pos, FKvelocity(states, model*features))/400;
    if i == 1
        figure
        distances(1) = norm(dest_pos - end_effector);
        disfig = plot(i,norm(dest_pos - end_effector),'linewidth',2);
        grid on
        hold on
        xlabel('iterations');
        ylabel('b/J - a')
        rewardfig = plot(i, rewards(i),'r','linewidth',2);
    else
        distances(i) = norm(dest_pos - end_effector);
        set(disfig, 'xdata', [1:i], 'ydata', distances(1:i));
        set(rewardfig, 'xdata', [1:i], 'ydata', rewards(1:i));
    end
    FKanimate(states.angles, dest_pos, states.lengths, i)
end
profile off
profile viewer