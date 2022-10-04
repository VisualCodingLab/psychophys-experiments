classdef csf_base < handle
    %MEASURECSFBASE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        cic
        inputs
        genInputs
    end
    
    methods
        function obj = csf_base()
            %% Prerequisites. 
            import neurostim.*

            %% Parameters
            stimulus_on_time = 500; % ms

            
            %% Setup CIC and the stimuli.
            obj.cic = myRig;   
            obj.cic.trialDuration = Inf; % A trial can only be ended by a mouse click
            obj.cic.cursor = 'arrow';
            obj.cic.screen.color.background = 0.5*ones(1,3);
            addprop(obj.cic, 'inputs'); % Create property for inputs, so that we can access them from cic
            
            
            %% Create Stimuli
            % Add center point fixation 
            % Note: Could possible add eye tracker to see if participant
            % is looking at the center point fixation
            f = stimuli.fixation(obj.cic,'centerPoint');       % Add a fixation point stimulus
            f.color             = [1 1 1];
            f.shape             = 'STAR';           % Shape of the fixation point
            f.size              = 0.25;
            f.X                 = 0;
            f.Y                 = 0;
            f.on                = 0;                % Always on
            f.duration          = Inf;

            
            % Test gabor to display left or right
            g=stimuli.gabor(obj.cic,'gabor_test'); % Gabor to display during testing (either left or right) 
            g.color = [0.5 0.5 0.5];
            g.sigma = 0.5;    
            g.frequency = 1;
            g.phaseSpeed = 0;
            g.orientation = 90;
            g.mask ='GAUSS3';
            g.duration = stimulus_on_time;
            g.on = '@gL_adapt.off + gabor_test.delay'; % Turns on as soon as adapter turns off + delay that can be specified
            g.X = 5;
            g.Y = 0;

            % Adapter gabors
            % Any changes should be only made to gL (as gR copies from gL)
            % Realisatically, the only changes made should be to frequency,
            % contrast (although should be 1) and duration (vector of
            % durations)
            gL = duplicate(g,'gL_adapt'); % Additional gabor to display for adapting image (left acts as master)
            gL.on = 0; 
            gL.duration = 0; % Default no adapter
            gL.X = -5;
            gL.contrast = 1;
            
            gR = duplicate(gL, 'gR_adapt'); % Right adapter (duplicates gL)
            gR.X = 5;
            gR.duration = '@gL_adapt.duration';
            gR.frequency = '@gL_adapt.frequency';
            gR.contrast = '@gL_adapt.contrast';

            % Add additional props after duplication to gabor test:
            g.addprop('delay');
            g.delay = 0;

            
            %% Create Behaviours
            % Key behaviour (L for left, R for right)
            k = behaviors.keyResponse(obj.cic,'choice');
            k.verbose = false;
            k.from = '@gL_adapt.off'; % Only start recording after adapter turns off
            k.maximumRT= Inf;                   %Allow inf time for a response
            k.keys = {'a' 'l'};                                 %Press 'A' for "left" gabor, 'L' for "right" gabor -> 
                                                                %Note: This was changed
                                                                %from R & L because R
                                                                %is on the left side of
                                                                %the keyboard and L is
                                                                %on the right side of
                                                                %the keyboard
            k.correctFun = '@(gabor_test.X > 0) + 1';   %Function returns the index of the correct response (i.e., key 1 -> L or 2 -> R)
            k.required = false; % Do not repeat if incorrect response
            % Define trial duration
            obj.cic.trialDuration = '@choice.stopTime';       %End the trial as soon as the 2AFC response is made.
            k.failEndsTrial = false;
            k.successEndsTrial  = false;
            
            %% Enforce Fixation at Center
            %Make sure there is an eye tracker (or at least a virtual one)
            if isempty(obj.cic.pluginsByClass('eyetracker'))
                e = neurostim.plugins.eyetracker(obj.cic);      %Eye tracker plugin not yet added, so use the virtual one. Mouse is used to control gaze position (click)
                e.useMouse = true;
            end
            
            fix = behaviors.fixate(obj.cic,'gabTrialFixate');
            fix.verbose = false;
            fix.from            = '@gabor_test.on';  % If fixation has not been achieved at this time, move to the next trial
            fix.to              = '@gabor_test.off';   % Require fixation until the choice is done.
            fix.X               = 0;
            fix.Y               = 0; 
            fix.tolerance       = 2;
            fix.failEndsTrial  = true; % Need to take into consideration how the adapter will be replayed with the trial, if trial fails


            adaptFix = behaviors.fixate(obj.cic,'adaptFixate');
            adaptFix.verbose = true;
            adaptFix.from            = 0;  % If fixation has not been achieved at this time, move to the next trial
            adaptFix.to              = '@gL_adapt.off';   % Require fixation until the choice is done
            adaptFix.X               = 0;
            adaptFix.Y               = 0; 
            adaptFix.tolerance       = 2;
            adaptFix.failEndsTrial  = false; 
            adaptFix.required = false;
        
            
            
            



            %% Set default inputs
            obj.inputs.contrast = [0.5];
            obj.inputs.freq = [3];
            obj.inputs.repeat = 1;

        

            %% Set random generated inputs
            obj.genInputs.contrast = [1 3 9 4 49];
            obj.genInputs.freq = [3];
            obj.genInputs.numTrials = 1;
            obj.genInputs.dispX = [5];
        end


        
        function generateInputs(obj)
            %% Prerequisites. 
            import neurostim.*
            
            %% Create Inputs
            % Combine variables 
            % Note: We could do it via .fac1, .fac2, however this would mean that one
            % contrast or frequency would remain constant whilst going through fac2
            % (i.e. not random on both dimensions). So only use one .fac1
            % The lengths of both arrays should now match, and each corresponding point represents a
            % trial
            inputContrast = reshape(repmat(obj.inputs.contrast, length(obj.inputs.freq), 1), 1, []); % i.e. If inputContrast = [1 2 3] and len(inputFreq) = 2, this generates: [1 1 2 2 3 3]
            inputFreq = repmat(obj.inputs.freq, 1, length(obj.inputs.contrast)); % i.e. If inputFreq = [1 2 3], and len(inputContrast) = 2, this generates: [1 2 3 1 2 3]
            
            % Repetitions
            inputContrast = repmat(inputContrast, 1, obj.inputs.repeat);
            inputFreq = repmat(inputFreq, 1, obj.inputs.repeat);
            
            numTrials = length(inputContrast);
            
            % Randomise
            randomise = true;
            if (randomise)
                randVector = randperm(numTrials); % Generate random vector and use for BOTH of the input arrays to randomise but keep correspondance
                inputContrast = inputContrast(randVector);
                inputFreq = inputFreq(randVector);
            end
            
            
            % Generate random array to determine if gabor displays left/right
            dispX = double(rand(1, numTrials) > 0.5); 
            dispX = dispX*2 - 1; % Turn 0 -> -1
            dispX = dispX * 5; % Scale by 5 to move X position outward

            %% Save inputs to object (for testing purposes)
            obj.genInputs.contrast = inputContrast;
            obj.genInputs.freq = inputFreq;
            obj.genInputs.numTrials = numTrials;
            obj.genInputs.dispX = dispX;
                
            %% Save inputs to cic (for later data analysis)
            obj.cic.inputs.contrast = obj.inputs.contrast; 
            obj.cic.inputs.frequency = obj.inputs.freq; % Save pre-randomised versions (raw)
            obj.cic.inputs.numTrials = numTrials; 
            obj.cic.inputs.contrastFull = inputContrast;
            obj.cic.inputs.freqFull = inputFreq; % Save randomised versions
            obj.cic.inputs.dispX = dispX;

        end


        
    end
end

