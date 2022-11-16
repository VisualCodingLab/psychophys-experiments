% Written by AS Sept/Oct 2022
% --- modified LZ Nov 2022

classdef csf_base < handle
    %MEASURECSFBASE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        cic
        
        testDuration = 250;     % (ms) how long test gabor is visible for
        testEccentricity = 5;   % how eccentric test (and adapt) are from fixation
        adapterFrequency = 2;   % spatial frequency of adaptors
    end
    
    methods
        function obj = csf_base()
            % Prerequisites. 
            import neurostim.*

            % Setup CIC and the stimuli.
            obj.cic =  marmolab.rigcfg;   
            obj.cic.trialDuration = Inf; % A trial can only be ended by a mouse click
            obj.cic.cursor = 'arrow';
            obj.cic.screen.color.background = 0.5*ones(1,3);
            
            % Adaptation props
            addprop(obj.cic, 'initialAdaptation');
            addprop(obj.cic, 'initialDelay');
            addprop(obj.cic, 'seqAdaptation');
            addprop(obj.cic, 'seqDelay');
            
            %% Create Stimuli
            % Add center point fixation 
            % Note: Could possible add eye tracker to see if participant
            % is looking at the center point fixation
            f = ABCfixation(obj.cic,'centerPoint');       % Add a fixation point stimulus
            f.color             = [1 1 1];
            f.X                 = 0;
            f.Y                 = 0;
            f.on                = 0;                % Always on
            f.duration          = Inf;

            
            % Test gabor to display left or right
            g=stimuli.gabor(obj.cic,'gabor_test'); % Gabor to display during testing (either left or right) 
            g.color = [0.5 0.5 0.5];
            g.sigma = 0.75;
            g.frequency = 1;
            g.phaseSpeed = 0;
            g.orientation = 90;
            g.width = 5;
            g.height = 5;
            g.mask ='GAUSS3';
            g.duration = obj.testDuration;
            g.on= '@gL_adapt.duration + gabor_test.delay';
            %g.on = '@gabTrialFixate.startTime.fixating'; % Turns on as soon as adapter turns off + delay that can be specified
            g.X = obj.testEccentricity;
            g.Y = 0;

            % Adapter gabors
            % Any changes should be only made to gL (as gR copies from gL)
            % Realisatically, the only changes made should be to frequency,
            % contrast (although should be 1) and duration (vector of
            % durations)
            gL = duplicate(g,'gL_adapt'); % Additional gabor to display for adapting image (left acts as master)
            gL.on = 0; %'@adaptFixate.startTime.initialFixate'; % Only turn on once particpant has started looking
            gL.duration = 0; % Default no adapter
            gL.X = -1*obj.testEccentricity;
            gL.contrast = 1;
            gL.frequency = obj.adapterFrequency;
            
            gR = duplicate(gL, 'gR_adapt'); % Right adapter (duplicates gL)
            gR.X = obj.testEccentricity;
            gR.duration = '@gL_adapt.duration';
            gR.frequency = '@gL_adapt.frequency';
            gR.contrast = '@gL_adapt.contrast';

            % Add additional props after duplication to gabor test:
            g.addprop('delay'); 
            % Delay parameter acts as a stimulus input for gabor_test,
            % whereby it specifies how much to delay the gabor trials (i.e.
            % how much time between the adaptation and trial). It is set in
            % the matlab runnable file (i.e. measureCSFadapt.m). It is used
            % in the following line (in the gabTrialFixate behaviour): 
            % fix.on = '@gL_adapt.off + gabor_test.delay';
            % Default to no delay:
            g.delay = 0;

            
            %% Create Behaviours
            % Key behaviour (L for left, R for right)
            k = behaviors.keyResponse(obj.cic,'choice');
            k.verbose = false;
            k.from = '@gabor_test.on'; % Only start recording after test turns on
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
            fix.on              = '@gL_adapt.off + gabor_test.delay';
            fix.X               = 0;
            fix.Y               = 0; 
            fix.tolerance       = 1;
            fix.failEndsTrial  = false; 
            fix.required = false; 

%             Sound feedback when fixate results in fail
            if ~ismac
                plugins.sound(obj.cic); 
                s= plugins.soundFeedback(obj.cic,'soundFeedback');
                s.add('waveform','bloop4.wav','when','afterTrial','criterion','@ ~gabTrialFixate.isSuccess');
                s.add('waveform','skCorrect.wav','when','afterTrial','criterion','@ choice.correct');
                s.add('waveform','skIncorrect.wav','when','afterTrial','criterion','@ ~choice.correct');
            end 

            adaptFix = fixate_adapt(obj.cic,'adaptFixate');
            adaptFix.verbose = true;
            adaptFix.on = 0;
            adaptFix.from            = '@gL_adapt.on';  
            adaptFix.to              = '@gL_adapt.off';   % Require fixation until the choice is done
            adaptFix.X               = 0;
            adaptFix.Y               = 0; 
            adaptFix.tolerance       = 1;
            adaptFix.failEndsTrial  = false; 
            adaptFix.required = false;
%         
            
        end
  
    end
end

