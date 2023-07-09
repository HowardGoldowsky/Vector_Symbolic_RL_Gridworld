
function mainQHD_ff(agent,qhd)      
% Main program to run the GridWorld Q-learning algorithm
                
% Initialize Environment variables
lengthGrid = 4;                                         % length/width of the grid
maxValue = (lengthGrid - 1) * ones(1,4);    % used for encoding state hypervectors
minValue  = - (lengthGrid - 1) * ones(1,4); % used for encoding state hypervectors
numEpisodes = 1000;                                % number of episodes to train the agent
maxIterations = 50;                                  % max number of iterations per episode
D = 10000;                                               % hypervector length

% Initialize Display variables
showEvery     = 1000;                              % wait these many episodes to display

% Set reward values
MOVE_PENALTY  = 0;
ENEMY_PENALTY = -1;
WALL_PENALTY = -1;
FOOD_REWARD   = 1;

% Instantiate reward objects
food  = Reward('food', FOOD_REWARD, D);
enemy = Reward('enemy', ENEMY_PENALTY, D);
wall = Reward('wall', WALL_PENALTY, D);
move  = Reward('move', MOVE_PENALTY, D);

gridWorld = Environment(lengthGrid, numEpisodes, maxIterations, wall);
qhd.epsilon=0;

    for episode = 1:gridWorld.numEpisodes

        % Add players to the grid world. Set new initial locations on grid.
        % Initialize other parameters.
        [gridWorld, agent] = gridWorld.addPlayer(agent);
        [gridWorld, food]  = gridWorld.addPlayer(food);
        [gridWorld, enemy] = gridWorld.addPlayer(enemy); 
        
        agent = agent.observe(food,enemy);
        qhd.H = qhd.basisState;
        qhd = qhd.encodeState(agent, maxValue, minValue, food, enemy);
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
            qhd = qhd.encodeState(agent, maxValue, minValue, food, enemy);
             
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

            qhd.prevH = qhd.H;
                       
            agent.stepDirectionHistory{episode,steps} = agent.choice;
        end % while ~doneHV
        
        agent.rewardHistory(episode) = agent.episodeReward;
        agent.stepHistory(episode) = steps;

        % Clean the environment
        [gridWorld,agent] = gridWorld.cleanWorld(agent); 

        if (mod(episode,showEvery)==0)
            tmpStr = sprintf('episode: %d',episode);
            disp(tmpStr) %#ok<DSPS>
        end
        
    end % for episode

figure;plot(agent.rewardHistory(1:episode),'x');axis([0 5000 -1.1 1.1]);
figure;plot(movmean(agent.rewardHistory(1:episode),200));

end % function

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
