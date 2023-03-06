% Written by LZ Mar 2023

% Prerequisites. 
import neurostim.*

% Setup CIC and the stimuli.
obj.cic =  marmolab.rigcfg;   
obj.cic.trialDuration = Inf; % A trial can only be ended by a mouse click
obj.cic.cursor = 'arrow'; % hide? 
obj.cic.screen.color.background = 0.5*ones(1,3);
            
%% Create Stimuli
% Add center point fixation 
% Note: Could possible add eye tracker to see if participant
% is looking at the center point fixation
f = stimuli.fixation(obj.cic,'centerPoint');       % Add a fixation point stimulus
f.shape             = 'ABC';
f.color             = [1 1 1];
f.color2            = obj.cic.screen.color.background;
f.size              = 0.75; 
f.size2             = 0.15;
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
g.on = '@min(gabTrialFixate.startTime.fixating, gabTrialFixate.on + gabor_test.waitFixate)'; % Turns on as soon as adapter turns off + delay that can be specified
g.X = obj.testEccentricity;
g.Y = 0;

            % Adapter gabors
            % Any changes should be only made to gL (as gR copies from gL)
            % Realisatically, the only changes made should be to frequency,
            % contrast (although should be 1) and duration (vector of
            % durations)
            gL = duplicate(g,'gL_adapt'); % Additional gabor to display for adapting image (left acts as master)
            % Below statement: If duration is 0 (i.e. no adapter), then
            % turn the stimuli on immediately (don't wait for fixation) to
            % prevent double fixation waiting time
            gL.on = '@iff(gL_adapt.duration == 0, 100, (min(adaptFixate.startTime.initialFixate, adaptFixate.on + gL_adapt.waitFixate)))'; % Only turn on once particpant has started looking
            %gL.on = '@adaptFixate.startTime.initialFixate';
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
            g.addprop('waitFixate');
            % Delay parameter acts as a stimulus input for gabor_test,
            % whereby it specifies how much to delay the gabor trials (i.e.
            % how much time between the adaptation and trial). It is set in
            % the matlab runnable file (i.e. measureCSFadapt.m). It is used
            % in the following line (in the gabTrialFixate behaviour): 
            % fix.on = '@gL_adapt.off + gabor_test.delay';
            % Default to no delay:
            g.delay = 0;
            g.waitFixate = Inf;
            


            % Add additional props to gL 
            % waitFixate: How long to wait for fixation, until you just
            % turn on the adaptation stimulus anyways
            gL.addprop('waitFixate');
            gL.waitFixate = Inf; % Default to wait for fixatation, no maximum timeout


            
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
            fix.verbose         = true;
            fix.from            = '@gabor_test.on';  % If fixation has not been achieved at this time, move to the next trial
            fix.to              = '@gabor_test.off';   % Require fixation until the choice is done.
            fix.on              = '@gL_adapt.off + gabor_test.delay';
            fix.X               = 0;
            fix.Y               = 0; 
            fix.tolerance       = 5;
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

            
            % Written by AS Sept/Oct 2022

clear all;

% dependencies
import neurostim.*

% Create CIC 
csf = csf_base;
csf.cic.addScript('BeforeTrial',@beginTrial); % Script that varies adapter
csf.cic.itiClear = 0;

% Enter inputs
blockStruct = 'no-adapt'; %'no-adapt', 'AB', 'BA'
contrastList   = logspace(-2.1, -0.38, 8);
freqList       = logspace(-0.2, 0.76, 5); 
nRepeatsPerCond = 2;    % conditions: SF/Contrast combos


switch blockStruct
    case 'AB'
        nBlocksPerCond = 5;     % conditions: Adapt/no-adapt
        designOrder = mod(ceil(0:0.5:nBlocksPerCond),2)+1;
        nBlocks = nBlocksPerCond*2;
    case 'BA'
        nBlocksPerCond = 5;     % conditions: Adapt/no-adapt
        designOrder = mod(ceil(1:0.5:1+nBlocksPerCond),2)+1;
        nBlocks = nBlocksPerCond*2;
    case 'adapt'
        nBlocksPerCond = 10;
        designOrder = ones(1, nBlocksPerCond);
        nBlocks = nBlocksPerCond;
    case 'no-adapt'
        nBlocksPerCond = 10;
        designOrder = ones(1, nBlocksPerCond)+1;
        nBlocks = nBlocksPerCond;
end


% == Adaptations for each trial ==
% Create durations array for adapter
csf.testDuration = 250;
csf.testEccentricity = 5; 
csf.adapterFrequency = 2.5;

csf.cic.initialAdaptation = 60000; % Initial adaptation (ms) - first trial
csf.cic.initialDelay = 500; % Initial delay from adaptation to trial (ms) - first trial
csf.cic.seqAdaptation = [0 0 0 0 0 0 0 0 0 5000]; % Cyclic sequence of adaptations (ms)
csf.cic.seqDelay = [0 0 0 0 0 0 0 0 0 250]; % Cyclic sequence of delay from adapt to trial (ms)

csf.cic.gL_adapt.waitFixate = 500; % Wait for fixation for x ms, until giving up and starting the adaptation
csf.cic.gabor_test.waitFixate = 0; % Wait for x ms, until giving up and starting the trial

% not pretty, but this sets up 0.5cpd gratings that contrast reverse at
% 2Hz. 
csf.cic.gL_adapt.flickerMode = 'square';
csf.cic.gL_adapt.flickerFrequency = 2;
csf.cic.gL_adapt.frequency = 2;
csf.cic.gR_adapt.flickerMode = 'square';
csf.cic.gR_adapt.flickerFrequency = 2;
csf.cic.gR_adapt.frequency = 2;

% Experimental setup
% Define experimental setup
d{1} = design('Adapt');
d{1}.fac1.gL_adapt.contrast = 1;
d{1}.fac2.gabor_test.contrast = contrastList;
d{1}.fac3.gabor_test.frequency = freqList;
d{1}.retry = 'RANDOM'; % This means retry any trials that fail due to non-fixation in a random position sometime in a future trial

d{2}= design('No-Adapt');
d{2}.fac1.gL_adapt.contrast = 0;
d{2}.fac2.gabor_test.contrast = contrastList; %csf.genInputs.contrast; 
d{2}.fac3.gabor_test.frequency = freqList; %csf.genInputs.freq;
d{2}.retry = 'RANDOM'; % This means retry any trials that fail due to non-fixation in a random position sometime in a future trial

% load designs into blocks

for i=1:nBlocks
    myBlock{i}=block([d{designOrder(i)}.name num2str(i)],d{designOrder(i)});             %Create a block of trials using the factorial. Type "help neurostim/block" for more options.
    myBlock{i}.nrRepeats=nRepeatsPerCond;
    myBlock{i}.afterMessage = 'Take a break!';
    myBlock{i}.beforeMessage = ['Block ', num2str(i) ' of ' num2str(nBlocks)];
end

%%
csf.cic.run(myBlock{:});

%% Functions
function beginTrial(c)
  % Start each trial with adapter (according to sequence)
  if c.gL_adapt.contrast > 0 % if an adapt block, use timings else, be speedy
      if (c.blockTrial == 1)
        % Initial adaptation
        dur = c.initialAdaptation;
        del = c.initialDelay;
      else
          seqLength = length(c.seqAdaptation);
          seqIndex = mod(c.blockTrial-2, seqLength)+1; % Cyclicly select sequences
          dur = c.seqAdaptation(seqIndex);
          del = c.seqDelay(seqIndex);
      end
  else
      dur = 0;
      del = 0;
  end  
  c.gL_adapt.duration = dur; 
  c.gabor_test.delay = del;
  
  fprintf('Duration: %3.2f, Delay: %3.2f\n', dur, del);

  % Randomise position of gabor_test (left or right)
  randLogical = (rand()<0.5); % 1 or 0
  eccentricity = c.gR_adapt.X;
  c.gabor_test.X = randLogical*eccentricity + ~randLogical * (-1*eccentricity);
  
end