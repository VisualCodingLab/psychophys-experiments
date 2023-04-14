classdef nWave < neurostim.stimulus
    % Wrapper class for the (fast) procedural Gabor textures in the PTB.
    % 
    % Adjustable variables (from CreateProcGabor.m):
    % 	orientation - orientation angle in degrees (0-180)
    % 	contrast - amplitude of gabor in intensity units
    % 	phase - the phase of the gabor's sine grating in degrees.
    % 	frequency - gabor's spatial frequency in cycles per pixel
    % 	sigma - spatial constant of gaussian hull function of gabor
    % 	width, height - maximum size of the gabor.
    % 	mask - one of 'GAUSS','CIRCLE','ANNULUS', 'GAUSS3' (truncated at 3
    % 	sigma)
    %   phaseSpeed - the drift of the grating in degrees per frame
    %   color - mean color in space and time (default: cic.screen.color.background)
    %
    % Flicker settings (this moduldates the *amplitude* of the sine wave in
    % the gabor)
    %
    % flickerMode = 'none','sine','square',sineconctrast, squarecontrast.
    %                   In the sine/square modes pixels change polarity
    %                   (~contrast*sin(t)) in the sinecontrast/sinesquare
    %                   modes, the pixels keep their polarity and only the
    %                   Michelson contrasts of the sine changes
    %                   (~contrast(1+sin(t)))
    % flickerFrequency = in Hz
    % flickerPhaseOffset = starting  phase of the flicker modulation.
    %
    %
    %  This stimulus can also draw the sum of multiple gabors. You can
    %  choose the number and whether to randomize the phase. 
    % multiGaborsN  = Must be 10 or less. 
    % multiGaborsPhaseRand = Boolean to use random phase for each of the
    % N.(Default is false, which corresponds to zero phase offset between
    % the different components).
    % multiGaborsOriRand =  Boolean to use random orientaiton for each of
    % the N. Default is false, which corresponds to linearly spaced oris
    % between 0 and 180.
    
    % NP - 2021-01-19 - changed handling of phase (input variable) and
    % spatialPhase (private variable). `phase` now controls starting phase
    % of grating 
    
    properties (Constant)
        maskTypes = {'GAUSS','CIRCLE','ANNULUS','GAUSS3','GAUSS2D'};
        flickerTypes = {'NONE','SINE','SQUARE','SINECONTRAST','SQUARECONTRAST'};
    end
    properties (Access=private)
        texture;
        shader;
        textureRect;
        spatialPhase=0; % frame-by-frame , current phase: not logged explicitly
    end
   
    methods
        function o =nWave(c,name)
            o = o@neurostim.stimulus(c,name);
            
            o.color = o.cic.screen.color.background;
            
            %% Base Teture parameters, see CreateProceduralGabor.m for details
            % No need to change unless you want to save texture memory and draw
            % only small Gabors.
            o.addProperty('width',10,'validate',@isnumeric);
            o.addProperty('height',10,'validate',@isnumeric);
            
            %%  Gabor parameters
            o.addProperty('orientation',0,'validate',@isnumeric);
            o.addProperty('contrast',1,'validate',@isnumeric);
            o.addProperty('phase',0,'validate',@isnumeric);
            o.addProperty('frequency',0.05,'validate',@isnumeric);
            o.addProperty('maskSize',0,'validate',@isnumeric); % [Inner Outer] or  [Outer]
            o.addProperty('mask', []);
            o.addProperty('maskRect', []);
            o.addProperty('type', 'SineWave', 'validate', @ischar);
            o.addProperty('taperSize',0.5, 'validate', @isnumeric); 
            o.addProperty('harmonics', 1:2:20);
            
            %% Motion
            o.addProperty('phaseSpeed',0);
            o.addProperty('spd', 0);
            
            %% Flicker 
            o.addProperty('flickerMode','NONE','validate',@(x)(ismember(neurostim.stimuli.gabor.flickerTypes,upper(x))));            
            o.addProperty('flickerFrequency',0,'validate',@isnumeric);
            o.addProperty('flickerPhaseOffset',0,'validate',@isnumeric);
            
            
            o.addProperty('phaseWindow', 180, 'validate', @isnumeric);
            o.addProperty('multiGaborsN',1,'validate',@isnumeric);
            o.addProperty('multiGaborsPhaseOffset',zeros(1,10)); % Used internally to randomize phase for the ori mask
            o.addProperty('multiGaborsPhaseStep', zeros(1,10)); 
            o.addProperty('multiGaborsFreqOffset',[]); % Used internally to randomize phase for the ori mask
            o.addProperty('multiGaborsContrastOffset',[]); % Used internally to randomize phase for the ori mask
        end
        
        function beforeExperiment(o)
            % Create the procedural texture
            try
                createProcGabor(o);
            catch me
                error('Create Procedural Gabor Failed (%s)',me.message);
            end
            
            if o.maskSize
                createMask(o);
            end
            
        end
        
        
        function beforeTrial(o)
            
            o.spatialPhase = o.phase; % user-defined initial phase
            phaseStepBase = 360*o.spd/o.cic.screen.frameRate; %deg phase to move per frame
            
            switch o.type
                case 'SineWave'
                    o.multiGaborsN = 1;
                    o.multiGaborsPhaseOffset = 0;
                case 'Square'
                    o.multiGaborsPhaseOffset = ...
                        zeros(1,o.multiGaborsN);
                case 'PSSquare'
                    o.multiGaborsPhaseOffset = ...
                        (o.phaseWindow*2)*rand(1,o.multiGaborsN)-o.phaseWindow;
                otherwise
                    warning('Unknown Type - using Sine Wave');
                    o.multiGaborsN = 1;
                    o.multiGaborsPhaseOffset = 0;
                    
            end
            
            theseHarmonics = o.harmonics(1:o.multiGaborsN); 
            o.multiGaborsFreqOffset = theseHarmonics;
            o.multiGaborsContrastOffset = 1./theseHarmonics;
            
            o.multiGaborsPhaseStep = ...
                        phaseStepBase*o.multiGaborsFreqOffset; 
            
            o.multiGaborsPhaseOffset = deg2rad(o.multiGaborsPhaseOffset);
            o.multiGaborsPhaseStep = deg2rad(o.multiGaborsPhaseStep); 
                
            % Pass information that does not change during the trial to the
            % shader.
            glUseProgram(o.shader);      
            glUniform1i(glGetUniformLocation(o.shader, 'multiGaborsN'),max(1,o.multiGaborsN)); % At least 1 so that a single Gabor is drawn
            glUniform1fv(glGetUniformLocation(o.shader, 'multiGaborsPhaseOffset'),numel(o.multiGaborsPhaseOffset),o.multiGaborsPhaseOffset);
            glUniform1fv(glGetUniformLocation(o.shader, 'multiGaborsFreqOffset'),numel(o.multiGaborsFreqOffset),o.multiGaborsFreqOffset);
            glUniform1fv(glGetUniformLocation(o.shader, 'multiGaborsContrastOffset'),numel(o.multiGaborsContrastOffset),o.multiGaborsContrastOffset);
            glUniform1fv(glGetUniformLocation(o.shader, 'multiGaborsPhaseStep'),numel(o.multiGaborsPhaseStep),o.multiGaborsPhaseStep);
            
            glUseProgram(0);                        
            
        end
        
        function beforeFrame(o)
            % Draw the texture with the current parameter settings
            %Screen('DrawTexture', windowPointer, texturePointer [,sourceRect] [,destinationRect] [,rotationAngle] [, filterMode] [, globalAlpha] [, modulateColor] [, textureShader] [, specialFlags] [, auxParameters]);
            sourceRect= [];filterMode =[]; textureShader =[]; globalAlpha =[]; ...
            specialFlags = kPsychDontDoRotation; % Keep defaults
                                            
            % Draw the Gabor using the GLSL shader
            aux = [+o.spatialPhase, +o.frequency, +o.contrast, deg2rad(90-+o.orientation)]';    
            Screen('DrawTexture', o.window, o.texture, sourceRect, ...
                   o.textureRect, +o.orientation, filterMode, globalAlpha, ...
                   +o.color , textureShader,specialFlags, aux);   
            if o.maskSize
                Screen('BlendFunction', o.window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
                Screen('DrawTexture', o.window, o.mask, [], o.textureRect); 
            end
        end
        
        function afterFrame(o)
            % Change any or all of the parameters.
            if o.phaseSpeed ~=0
                o.spatialPhase = o.spatialPhase + 1; % increment phase step counter
            end            

        end
    end
    
    methods (Access=private)
        
        function createMask(o)
           [xPix,yPix] = o.cic.physical2Pixel(o.textureRect([1 3]),...
                                              o.textureRect([2 4]));
           o.maskRect = ceil([xPix(1) yPix(1) xPix(2) yPix(2)]); 
           mSize = RectSize(o.maskRect); 
           ppd = o.cic.physical2Pixel(1.0,0.0)-o.cic.physical2Pixel(0.0,0.0); 
           mask = uint8(ones(mSize, mSize, 2) * 128);
           winImage = squarewaves.createCosineWindow(mSize, o.taperSize*ppd, 0);
           mask(:,:,2) = abs(1-winImage) * 255;
           o.mask   = Screen('MakeTexture', o.window, mask, [], [], 0); 
%            o.maskRect = CenterRectOnPoint(maskRect,...
%                             Scr.center(1)+Stim.relCenterPX(1),...
%                             Scr.center(2)+Stim.relCenterPX(2)); 
        end
        
        function createProcGabor(o)
            % Copied from PTB
            debuglevel = 0;
            % Global GL struct: Will be initialized in the LoadGLSLProgramFromFiles
            global GL;
            % Make sure we have support for shaders, abort otherwise:
            AssertGLSL;
            % Load shader
            p = fileparts(mfilename('fullpath'));
            o.shader = LoadGLSLProgramFromFiles(fullfile(p,'GLSLShaders','nWave'), debuglevel);
            % Setup shader: variables set here cannot change during the
            % experiment.
            glUseProgram(o.shader);
            colorModes = {'RGB','XYL','LUM'}; % 1,2,3
            colorMode = find(ismember(o.cic.screen.colorMode,colorModes));
            if isempty(colorMode)
                error(['Gabor does not know how to deal with colormode ' o.cic.screen.colorMode]);
            end
            
            glUniform2f(glGetUniformLocation(o.shader , 'size'), o.width, o.height);
            glUniform1i(glGetUniformLocation(o.shader , 'colorMode'), colorMode);
                        
            % Setup done:
            glUseProgram(0);
            
            % Create a purely virtual procedural texture of size width x height virtual pixels.            % Attach the Shader to it to define its appearance:
            o.texture = Screen('SetOpenGLTexture', o.window, [], 0, GL.TEXTURE_RECTANGLE_EXT, o.width, o.height, 1, o.shader);
            % Query and return its bounding rectangle:
            o.textureRect= [-o.width -o.height o.width o.height]./2;
            
        end
    end
    
end