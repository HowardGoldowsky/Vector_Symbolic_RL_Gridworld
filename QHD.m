classdef QHD
    
    % A hyperdimensional Q-learning reinforcement learning algorithm
    
    properties
        
        type                  % text string ('Q-learning' etc)
        isTraining          % BOOL true if training is on
        gamma              % discount of future rewards
        alpha                 % weight of error term
        epsilon               % probability of exploration
        epsilonDecay       % rate at which exploration decreases
        basisState           % initial state of agent
        H                       % current superimposed state hypervector of agent
        prevH                 % previous superimposed state hypervector of agent
        P1                      % state hypervector 1: relative location of agent from food X-dim
        P2                      % state hypervector 2: relative location of agent from food Y-dim
        P3                      % state hypervector 3: relative location of agent from enemy X-dim
        P4                      % state hypervector 4: relative location of agent from enemy Y-dim
        maxQTarget        % value of inner product with most similar model hypervector
        maxQMain
        maxQ
        foodStateHV
        enemyStateHV
        beta                    % model update rate
        
    end % properties
    
    methods
        
        function obj = QHD(epsilon,epsilonDecay,alpha,gamma,isTraining,D,beta) % constructor            
            obj.epsilon = epsilon;
            obj.epsilonDecay = epsilonDecay;
            obj.alpha = alpha;
            obj.gamma = gamma;           
            obj = initModel(obj,D);  
            obj.type = 'QHD';
            obj.isTraining = isTraining;
            obj.beta=beta;
        end
        
        function obj = reset(obj,epsilon)
            obj.epsilon = epsilon;
        end
        
        function obj = initModel(obj,D)           
            % Initialize the required hypervectors     
            obj.H = PhasorHV('D', D);                    % init random state vector as zero state
            obj.basisState = obj.H;

            obj.P1 = PhasorHV('D', D);                 
            obj.P2 = PhasorHV('D', D);
            obj.P3 = PhasorHV('D', D);
            obj.P4 = PhasorHV('D', D);
            
            obj.foodStateHV = PhasorHV('D', D);
            obj.enemyStateHV = PhasorHV('D', D);
        end
        
        function obj = encodeState(obj, agent, maxVal, minVal)
            % Takes in the continuous four element state vector 
            % of the system and encodes this into the state hypervector. 
            % 1) Find the difference from previous continuous state
            % 2) Bind this difference to the previous feature vectors
            % 3) Bind new feature vectors to the current state hypervector
            %
            % INPUT
            %   prevState: previous continuous state
            %   state: continuous state [x, x_dot, theta, theta_dot]
            %   H: continuous state hypervector
            %   P1-P4: feature hypervectors
            %
            % OUTPUT
            %   H: new continuous state hypervector
                
            % Find delta with previous state
            delta = agent.state - agent.previousState;   

            % Find mapping range
            limit = maxVal - minVal; 

            % Linearly map delta to between 0:2*pi around the unit circle.
            % I dont think this mapping to 2*pi matters, because the only thing that
            % matters is the gradient descent of the model HV. 
            %map = (delta./limit) * pi; 
            %map = (delta./limit) * 2 * pi; 
            map = delta;
            
            p1 = obj.P1.encode(map(1));                
            p2 = obj.P2.encode(map(2));
            p3 = obj.P3.encode(map(3));
            p4 = obj.P4.encode(map(4));

            % Bind new feature hypervectors to the old state 
            % hypervector to make the new state hypervector
            obj.H = bind(obj.H,p1);
            obj.H = bind(obj.H,p2);
            obj.H = bind(obj.H,p3);
            obj.H = bind(obj.H,p4);
            
        end

        function obj = findMaxQ_using_main(obj, agent)
           [obj.maxQMain, ~] = max([similarity(obj.H, agent.model(1)), ...
                similarity(obj.H, agent.model(2)), ...
                similarity(obj.H, agent.model(3)), ...
                similarity(obj.H, agent.model(4))]);           
        end 

        function obj = findMaxQ_using_target(obj, agent)
            [obj.maxQTarget, ~] = max([similarity(obj.H, agent.model_target(1)), ...
                similarity(obj.H, agent.model_target(2)), ...
                similarity(obj.H, agent.model_target(3)), ...
                similarity(obj.H, agent.model_target(4))]);           
        end 
        
    end % methods
    
end % class

