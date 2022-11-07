% Written by AS Sept/Oct 2022

clear all;

%% Prerequisites. 
import neurostim.*

%% Create CIC 
csf = csf_base;
csf.cic.addScript('BeforeTrial',@beginTrial); % Script that varies adapter


%% Enter inputs
csf.inputs.contrast = [0.5];
csf.inputs.freq = [3 6 10 11];
csf.inputs.repeat = 1;
csf.generateInputs(); % Randomised inputs are saved to csf.genInputs


%% == Adaptations for each trial ==
%% Create durations array for adapter
csf.cic.initialAdaptation = 500; % Initial adaptation (ms) - first trial
csf.cic.initialDelay = 100; % Initial delay from adaptation to trial (ms) - first trial
csf.cic.seqAdaptation = [500 500 500]; % Cyclic sequence of adaptations (ms)
csf.cic.seqDelay = [1000 1000 1000]; % Cyclic sequence of delay from adapt to trial (ms)
adapterFrequency = 5;

 

%% Experimental setup
% Define experimental setup
d = design('contrast-freq');

% Contrast
d.fac1.gabor_test.contrast = csf.genInputs.contrast; 

% Frequency
d.fac1.gabor_test.frequency = csf.genInputs.freq;

% Adapter
d.fac1.gL_adapt.frequency = adapterFrequency; % Could move this to the beginTrial block for varying frequencies

d.randomization = 'SEQUENTIAL'; % Prevent auto randomisation of inputs (as we have alread randomised them) + our adapters won't be all over the place
d.retry = 'RANDOM'; % This means retry any trials that fail due to non-fixation in a random position sometime in a future trial


blk = block('contrast-freq',d);
blk.nrRepeats = 1;
csf.cic.run(blk);



%% Analyse data
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
  c.gabor_test.X = randLogical*c.testEccentricity + ~randLogical * (-1*c.testEccentricity);
end