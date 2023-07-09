classdef (Abstract) Hypervector 
    
    % Abstract hypervector class. Constructor builds a generic hypervector
    % of all zeros of the specified dimension.
    
    properties (Abstract)
        dimension (1,1) double
        samples
    end % properties
    
    methods
        
        function    obj = Hypervector()     % Constructor
        
        end
        
        function result = superimpose(vectors)   
            % Create a superposition of an array of PhasorHV objects and return an object of
            % class PhasorHV.
            % TODO: Make this function more dynamic by examining the
            % incoming class and outputting the same class. e.g. this
            % should be generic for Boolean and Binary HV as well. 
            % There is also the question of should we normalize the output,
            % because the deVine & Bruza paper say that "meaning" of the superposiiton
            % should be just the angle of the sample sums, not the sums themselves. 
            N = length(vectors);
            D = vectors(1).dimension;
            x = reshape([vectors.samples].',N,D);  % MATLAB's (.') notation does not take the conjugate when taking the transpose.
            superpos = sum(x).';                          % MATLAB's (.') notation does not take the conjugate when taking the transpose.
            result = PhasorHV(D,superpos);
        end
                
    end % methods
    
end

