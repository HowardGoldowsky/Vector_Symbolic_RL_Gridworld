% Main program to run the GridWorld Q-learning algorithm
clc; clear all; close all;              % clear the command window, the workspace and close the figures

epsilon = 0.999;                               
epsilonDecay = .995;                      
alpha = 0.15;      
gamma = .9;                                   
                
% Initialize Environment variables
isTraining = true;
lengthGrid = 8;                                         % length/width of the grid
maxValue = (lengthGrid - 1) * ones(1,4);    % used for encoding state hypervectors
minValue  = - (lengthGrid - 1) * ones(1,4); % used for encoding state hypervectors
numEpisodes = 10000;                              % number of episodes to train the agent
maxIterations = 100;                                 % max number of iterations per episode
D = 10000;                                               % hypervector length
beta = .01;                                               % update rate for target model

% Initialize Display variables
showEvery     = 1000;                              % wait these many episodes to display

% Set reward values
MOVE_PENALTY  = 0;%-.001;%-1/300; %-1;   
ENEMY_PENALTY = -1;%-25/300;%-1; %-300;%-300;  
WALL_PENALTY = -1;%-25/300;
FOOD_REWARD   = 1;%25/300;%25;


% Instantiate reward objects
food  = Reward('food', FOOD_REWARD, D);
enemy = Reward('enemy', ENEMY_PENALTY, D);
wall = Reward('wall', WALL_PENALTY, D);
move  = Reward('move', MOVE_PENALTY, D);

% Instantiate sim objects
qhd = QHD(epsilon, epsilonDecay, alpha, gamma, isTraining, D, beta);
agent = Agent('player', qhd, numEpisodes, D);
gridWorld = Environment(lengthGrid, numEpisodes, maxIterations, wall);
display = Display(showEvery);

% Train the agent
if (qhd.isTraining)
    for episode = 1:gridWorld.numEpisodes

        % Add players to the grid world. Set new initial locations on grid.
        % Initialize other parameters.
        [gridWorld, agent] = gridWorld.addPlayer(agent);
        [gridWorld, food]  = gridWorld.addPlayer(food);
        [gridWorld, enemy] = gridWorld.addPlayer(enemy); 
        
        agent = agent.observe(food,enemy);
        qhd.H = qhd.basisState;
        qhd = qhd.encodeState(agent, maxValue, minValue);
        qhd.prevH = qhd.H;
        
        doneHV = false;
        steps = 0;
        agent.iterationReward = 0;
        
        while ~doneHV
            
            steps = steps + 1;
            if (steps >= gridWorld.maxIterations)
                doneHV = true;
            end
            
            % Select the best action by comparing models to the state hypervectors.    
            agent = agent.selectAction(qhd.H, qhd.epsilon);
            
            % Take the action by using agent.choice. Change the 
            % environment status.
            [agent, gridWorld] = takeAction(agent, gridWorld);
      
            % Observe agent's new relationship to food and enemy.
            % This observes the agent's current Euclidean position
            % and represents it relationally by
            % [dxFood dyFood dxEnemy dyEnemy].
            agent = agent.observe(food,enemy);           
            
            % Encode agent's Euclidean state into their respective
            % hypervectors.
            qhd = qhd.encodeState(agent, maxValue, minValue);
            
            % Find the max Q, the max inner product between H 
            % and all model hypervectors
            qhd = qhd.findMaxQ_using_target(agent);
            qhd = qhd.findMaxQ_using_main(agent);
            qhd.maxQ = min(qhd.maxQTarget,qhd.maxQMain);
             
            % Receive reward
            if (agent.x == enemy.x && agent.y == enemy.y)                         % avoidance
                agent.iterationReward = agent.iterationReward + enemy.value;
                doneHV = true;
            elseif (agent.x == food.x && agent.y == food.y)                         % goal
                agent.iterationReward = agent.iterationReward + food.value;
                doneHV = true;
            elseif (agent.x == gridWorld.lengthGrid+1 || agent.x == 0 || ...
                      agent.y == gridWorld.lengthGrid+1 || agent.y == 0)         % wall  
                agent.iterationReward = agent.iterationReward + wall.value;
                doneHV = true;
            else
                agent.iterationReward = agent.iterationReward + move.value;
            end

            % Update Reward
            agent.episodeReward = agent.episodeReward + agent.iterationReward;

            % Update the agent's models
            agent = agent.updateModel(qhd);
            qhd.prevH = qhd.H;
            
            % Transfer from target model to main model. 
            agent.model_target(1).samples = (qhd.beta)*agent.model(1).samples + (1-qhd.beta)*agent.model_target(1).samples;
            agent.model_target(2).samples = (qhd.beta)*agent.model(2).samples + (1-qhd.beta)*agent.model_target(2).samples;
            agent.model_target(3).samples = (qhd.beta)*agent.model(3).samples + (1-qhd.beta)*agent.model_target(3).samples;
            agent.model_target(4).samples = (qhd.beta)*agent.model(4).samples + (1-qhd.beta)*agent.model_target(4).samples;
                       
            agent.stepDirectionHistory{episode,steps} = agent.choice;
        end % while ~doneHV
        
        agent.rewardHistory(episode) = agent.episodeReward;
        agent.stepHistory(episode) = steps;
        qhd.epsilon = qhd.epsilon * qhd.epsilonDecay;

        % Clean the environment
        [gridWorld,agent] = gridWorld.cleanWorld(agent); 

        if (mod(episode,1000)==0)
            tmpStr = sprintf('episode: %d, epsilon: %1.5f, epsilonDecay: %1.5f, alpha: %1.5f, gamma: %1.5f',episode, epsilon, epsilonDecay, alpha, gamma);
            disp(tmpStr)
        end
        
    end % for episode
end % if (learningAlgorithm.trainAgent)

figure;plot(agent.rewardHistory,'x');axis([0 numEpisodes -1.1 1.1]);
figure;plot(movmean(agent.rewardHistory,200));

function [agent, environment] = takeAction(agent,environment)    
    previousX = agent.x;
    previousY = agent.y;
    [agent] = movePlayer(agent,environment.lengthGrid,environment.wall.value);

    % If agent hits the wall, then don't update the grid.
    if (agent.x == environment.lengthGrid+1 || agent.x == 0 || ...
        agent.y == environment.lengthGrid+1 || agent.y == 0)    
        return;
    end% wall  
                  
    % update the grid
    environment.grid(previousY,previousX) = 0; % delete previous location
    if isequal(agent.type,'enemy')  % draw current one
        environment.grid(agent.y,agent.x) = 1;
    elseif isequal(agent.type,'food')
        environment.grid(agent.y,agent.x) = 2;
    elseif isequal(agent.type,'player')
        environment.grid(agent.y,agent.x) = 3;
    end                     
end % takeAction

function [agent] = movePlayer(agent,lengthGrid,wallValue)
    % Move the player. If the player hits the edge of the grid,
    % then set the movement inValid = false. The calling function
    % then calls this function again until inValid = true. If the agent
    % hits a wall, then penalize it.
    if isequal(agent.choice,'right')
        if agent.x + 1 <= lengthGrid
            agent.x = agent.x + 1;
        else
            agent.x = agent.x + 1;
          %  agent.iterationReward = agent.iterationReward + wallValue;
        end
    elseif isequal(agent.choice,'left')
        if agent.x - 1 > 0
            agent.x = agent.x - 1;
        else
            agent.x = agent.x - 1;
         %   agent.iterationReward = agent.iterationReward + wallValue;
        end
    elseif isequal(agent.choice,'up')
        if agent.y - 1 > 0
            agent.y = agent.y - 1;
        else
            agent.y = agent.y - 1;
      %      agent.iterationReward = agent.iterationReward + wallValue;
        end
    elseif isequal(agent.choice,'down')
        if agent.y + 1 <= lengthGrid
            agent.y = agent.y + 1;
        else
            agent.y = agent.y + 1;
       %     agent.iterationReward = agent.iterationReward + wallValue;
        end
    end
end % move
