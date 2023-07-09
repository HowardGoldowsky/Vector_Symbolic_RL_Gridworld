classdef PhasorHV < Hypervector 
    % Class for circular hypervectors
    
    % Required by abstract class Hypervector
    properties
        dimension
        samples
    end % required properties
    
    % Specific to PhasorHV class
    properties
        
    end
      
    methods
               
        function obj = PhasorHV(op) % Constructor   
            
            arguments
                op.D                    (1,1) double = 1000
                op.samples          (:,1) = []  
                op.meanBias         (1,1) double = 0;
                op.variance           (1,1) double = pi/2
                op.distribution     (1,1) string = 'uniform'
            end
            
            switch (op.distribution)
                case 'uniform'
                    obj.dimension = op.D;
                    phi = 2 * pi * rand(op.D,1) - pi; % [-pi, pi)

                    if (isempty(op.samples))
                        obj.samples = exp(1i * phi);
                    else
                        obj.samples = op.samples;
                    end
                    
                case 'normal'
                    obj.dimension = op.D;
                    phi = op.variance * randn(op.D,1) + op.meanBias; % [-pi, pi)

                    if (isempty(op.samples))
                        obj.samples = exp(1i * phi);
                    else
                        obj.samples = op.samples;
                    end
            
            end % switch
        end
        
        function obj = normalize(obj)
            % Makes the length of each phasor element equal to 1. 
            % This is an element-by-element normalization, so  
            % each sample returns to the unit circle.
            obj.samples = obj.samples./abs(obj.samples);
        end
        
        function result = bind(v1,v2)
            % We are adding the angle values of each element when 
            % we do an elementwise multiplication.
            boundSamples = v1.samples .* v2.samples;
            D = v1.dimension;
            result = PhasorHV('D', D, 'samples', boundSamples);
        end
        
        function result = unbind(v1,v2)
            % This is the same as bind, except we use the complex conjugate
            % of one of the hypervetors. The scalar result here is the
            % "mean of the cosine of corresponding angle differences." (de
            % Vine & Bruza, "Semantic Oscillations: Encoding Context and
            % Structure in Complex Valued Holographic Vectors." Therefor,
            % when we take the scalar product of this result with the
            % original bound hypervector, it should be close to 1.
            boundSamples = v1.samples .* conj(v2.samples);
            D = v1.dimension;
            result = PhasorHV('D', D, 'samples', boundSamples);
        end
        
        function result = similarity(v1,v2)
            % Similarity is defined as the mean of the cosine of the
            % corresponding angle differences. It is important to note that
            % the complex conjugate must be applied to one of these
            % vectors. This is the definition of the scalar product between
            % two complex vectors. If we had two identical vectors, then we
            % would need the mean angle between each dimension to be zero,
            % For two identical vectors, each element's angle will be theta
            % + -theta = 0. So here we are taking the scalar product, which 
            % computes the mean of the angles. The MATLAB "apostrophe" 
            % operator takes the conjugate transpose if the vector is complex. 
            % Therefor the function being called is equivalent to the
            % following two lines:
            %result = abs(mean(cos(angle(v1.samples)-angle(v2.samples))));
            %result = abs(mean(cos(angle(v1.samples.*conj(v2.samples)))));
            % Taking the complex conjugate affords us the opportunity to
            % "add" the angles by taking the scalar product. In the code,
            % where we do not use the angle() function, the real part of
            % each sample is equivalent to the component of the phasor
            % extracted by the cos() of the angle. Normalizing by the
            % length of the vector, D, effectively takes the mean.  
            % Absolute value should not be applied here to the function. It should be
            % applied outside the function, because taking it obscured the
            % differences on the real axis.
            D = v1.dimension;
            result = real(v1.samples'*v2.samples)/D;
            %result = abs(mean(cos(angle(v1.samples)-angle(v2.samples))));
        end
        
        function result = inverse(obj)
            % Negation of theta, modulo 2*pi. The modulo does not really
            % matter here, since the angles are not affected.
            D = obj.dimension;
            phi = pi * ones(D,1);
            invSamples = obj.samples .* exp(1i*phi);      % Add pi to every angle.      
            result = PhasorHV('D', D, 'samples', invSamples);                
        end
        
        function result = encode(obj,state)
            % This function takes in a value and
            % then encodes the value into the hypervector by 
            % raising each sample to the power of the value.
            % INPUT:
            %   state: value of the feature
            D = obj.dimension;
            encodedSamples = obj.samples.^state;     % raise every sample to the same power
            result = PhasorHV('D', D, 'samples', encodedSamples);
        end
            
    end % methods
end % class
