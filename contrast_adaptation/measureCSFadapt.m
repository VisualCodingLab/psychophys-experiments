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