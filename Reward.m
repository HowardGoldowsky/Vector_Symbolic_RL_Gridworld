classdef Reward
    
    % Generic reward object for an RL appliation
    
    properties       
        x                   % float x-coordinate on grid
        y                   % float y-coordinate on grid
        value               % FLOAT scalar
        type                % STRING    
        HV                  % hypervector representation
    end
    
    methods
        
        function obj = Reward(type, value, D)           
            obj.type  = type;
            obj.value = value;     
            obj.HV = PhasorHV(D);
        end
    
    end
end

