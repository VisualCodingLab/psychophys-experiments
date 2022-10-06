clear all;
%% Prerequisites. 
import neurostim.*

%% Create CIC 
csf = csf_base;
csf.cic.addScript('BeforeTrial',@beginTrial); % Script that varies adapter


%% Enter inputs
csf.inputs.contrast = [0.3 0.5 0.8];
csf.inputs.freq = [3 6 10];
csf.inputs.repeat = 1;
csf.generateInputs(); % Randomised inputs are saved to csf.genInputs


%% == Adaptations for each trial ==
%% Create durations array for adapter
csf.cic.initialAdaptation = 5000; % Initial adaptation (ms) - first trial
csf.cic.initialDelay = 1000; % Initial delay from adaptation to trial (ms) - first trial
csf.cic.seqAdaptation = [0 0 1000]; % Cyclic sequence of adaptations (ms)
csf.cic.seqDelay = [0 0 500]; % Cyclic sequence of delay from adapt to trial (ms)




%% Experimental setup
% Define experimental setup
d = design('contrast-freq');


% Contrast
d.fac1.gabor_test.contrast = csf.genInputs.contrast; 

% Frequency
d.fac1.gabor_test.frequency = csf.genInputs.freq;

% Adapter
d.fac1.gL_adapt.frequency = 5; % Could move this to the beginTrial block for varying frequencies

d.randomization = 'SEQUENTIAL'; % Prevent auto randomisation of inputs (as we have alread randomised them) + our adapters won't be all over the place
d.retry = 'RANDOM'; 


blk = block('contrast-freq',d);
blk.nrRepeats = 1;
csf.cic.subject = 'easyD';
csf.cic.run(blk);



%% Analyse data
% Possible to do live plotting in between trials ?
% Gather data
csfPostProcessing(0, csf.cic);


%% Functions
function beginTrial(c)
  % Start each trial with adapter (according to sequence)
  if (c.trial == 1)
    % Initial adaptation
    dur = c.initialAdaptation;
    del = c.initialDelay;
  else
      seqLength = length(c.seqAdaptation);
      seqIndex = mod(c.trial-2, seqLength)+1; % Cyclicly select sequences
      dur = c.seqAdaptation(seqIndex);
      del = c.seqDelay(seqIndex);
  end
  
  c.gL_adapt.duration = dur; 
  c.gabor_test.delay = del;

  % Randomise position of gabor_test (left or right)
  randLogical = (rand()<0.5); % 1 or 0
  c.gabor_test.X = randLogical*5 + ~randLogical * (-5);
end