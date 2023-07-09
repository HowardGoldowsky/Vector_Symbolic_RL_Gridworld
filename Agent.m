classdef Agent
    
    properties
        
        x                               % INT x-coordinate on grid
        y                               % INT y-coordinate on grid
        ID                              % INT agent ID 
        type                           % STRING text string
        learningAlgorithm       % LEARNING OBJECT 
        state                          % [1 x 4] observation parameters 
        previousState 
        action                        % 1 up, 2 down, 3 left, 4 right
        rewardHistory
        stepHistory
        stepDirectionHistory
        iterationReward
        episodeReward           
        choice                        % choice of movement direction (left, right, down up)
        model                        % [1 x 4] model hypervectors
        model_target
           
    end
    
    methods
        
        function obj = Agent(type,learningAlgorithm,numEpisodes,D)  % constructor    
            obj.type = type;
            obj.learningAlgorithm = learningAlgorithm;
            obj.iterationReward = 0;
            obj.episodeReward = 0;
            obj.rewardHistory = zeros(numEpisodes,1);
            obj.stepHistory = zeros(numEpisodes,1);
            obj.stepDirectionHistory = cell(numEpisodes,10);
            M1 = PhasorHV(D,zeros(D,1));    % model hypervectors, one for each action; init to zeros
            M2 = PhasorHV(D,zeros(D,1));
            M3 = PhasorHV(D,zeros(D,1));    
            M4 = PhasorHV(D,zeros(D,1));          
            Mt1 = PhasorHV(D,zeros(D,1));    % model hypervectors, one for each action; init to zeros
            Mt2 = PhasorHV(D,zeros(D,1));
            Mt3 = PhasorHV(D,zeros(D,1));    
            Mt4 = PhasorHV(D,zeros(D,1));          
            
            obj.model = [M1,M2,M3,M4];    % make easy to index
            obj.model_target = [Mt1,Mt2,Mt3,Mt4];   
            
            obj.state = [0 0 0 0];
        end % constructor
        
        function obj = observe(obj,food,enemy)
            foodDiff  = [obj.x - food.x, obj.y - food.y];
            enemyDiff = [obj.x - enemy.x, obj.y - enemy.y];
            obj.previousState = obj.state;
          %  obj.state = [foodDiff, enemyDiff]; 
            obj.state = sign([foodDiff, enemyDiff]); 
        end 
        
         function obj = selectAction(obj, H, epsilon)
            
            M1 = obj.model(1);
            M2 = obj.model(2);
            M3 = obj.model(3);
            M4 = obj.model(4);
            
            if (rand < epsilon)                                         
                obj.action = randi([1 4],1);
            else    
                [~, obj.action] = max([similarity(H,M1),similarity(H,M2),similarity(H,M3),similarity(H,M4)]);
            end                   
            obj = act2choice(obj); % text description of action
         end
        
         function obj = updateModel(obj, qhd)
            % Function updates the model hypervectors
            q_true = obj.iterationReward + qhd.gamma * qhd.maxQ;
            q_pred = similarity(qhd.prevH, obj.model(obj.action));
            regError = q_true - q_pred;
            obj.model(obj.action).samples = obj.model(obj.action).samples + qhd.alpha * regError * qhd.prevH.samples; 
      %      obj.model(obj.action) = obj.model(obj.action).normalize;
         end
        
        function obj = reset(obj)
            obj.x = [];                      
            obj.y = [];                    
            obj.state = [0 0 0 0];                    
            obj.iterationReward = 0;
            obj.episodeReward = 0;
        end    
        
        function obj = act2choice(obj)
            switch(obj.action)
                case 1
                    obj.choice = 'up';
                case 2
                    obj.choice = 'down';
                case 3
                    obj.choice = 'left';
                case 4
                    obj.choice = 'right';
            end
        end
         
    end % methods
end % class

