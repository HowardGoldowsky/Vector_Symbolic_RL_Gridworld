classdef Environment
    
    % Environment class for a GridWorld application
    
    properties
        
        agent                        % autonomous player in the GridWorld
        numEpisodes             % number of episodes
        maxIterations            % number of iterations per episode
        maxStepsPerEpisode  % max allowed steps per episode
        lengthGrid                 % length of side 
        numPlayers                % number of objects in the grid world
        occupiedCells             % [numPlayers x 2] objects occupy these cells
        grid                            % grid where action takes place
        wall                            % wall object, boundary of grid world
        configs                       % array of all 2x2 agent, enemy, and goal configurations
        
    end % properties
    
    methods
 
        function obj = Environment(lengthGrid, numEpisodes, maxIterations, wall)  % constructor            
            obj.lengthGrid = lengthGrid;
            obj.numEpisodes = numEpisodes;
            obj.numPlayers = 0;
            obj.grid = zeros(lengthGrid); 
            obj.maxIterations = maxIterations;
            obj.wall = wall;
           % obj.configs = populateConfigs();
        end % constructor
        
        function [obj, player] = addPlayer(obj,player)  
            % Add player to a random location on grid. Flag avoids two players 
            % from occupying the same cell in the grid.
            flag = true;                                    
            while flag
                x = randi(obj.lengthGrid,1);
                y = randi(obj.lengthGrid,1); 
                flag = false;   
                for i = 1:obj.numPlayers
                    if x == obj.occupiedCells(i,2) && y == obj.occupiedCells(i,1)
                        flag = true;
                    end
                end % for i
            end % while
            
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DEBUG CODE TO USE CONSTANT LOCATIONS %%%%%%%%%
 
%             caseIDX = randi(2,1);
%             caseList = [9 17];
%             configCase = caseList(caseIDX);
%                 switch player.type  
%                     case 'player'
%                         x = obj.configs(configCase).player(2); y = obj.configs(configCase).player(1);
%                     case 'food'
%                         x = obj.configs(configCase).food(2); y = obj.configs(configCase).food(1);
%                     case 'enemy'  
%                         x = obj.configs(configCase).enemy(2); y = obj.configs(configCase).enemy(1);
%                 end
                
   
            obj.numPlayers = obj.numPlayers + 1;
            obj.occupiedCells(obj.numPlayers,:) = [y,x]; 
            player.x = x;
            player.y = y; 
                       
            % update the grid
            if isequal(player.type,'enemy')
                obj.grid(y,x) = 1; 
            elseif isequal(player.type,'food')
                obj.grid(y,x) = 2; 
            elseif isequal(player.type,'player')
                obj.grid(y,x) = 3; 
            end
        end % addPlayer
        
        function [obj,agent] = cleanWorld(obj,agent)          
            obj.grid = zeros(obj.lengthGrid);   
            obj.occupiedCells = zeros(obj.numPlayers,2); 
            obj.numPlayers = 0;  
            agent = agent.reset;
        end % cleanWorld
                
    end % methods
end % class

