% Written by AS Sept/Oct 2022

%% Prerequisites. 
import neurostim.*

%% Create CIC 
csf = csf_base;
csf.cic.addScript('BeforeTrial',@beginTrial); % Script that varies adapter


%% Enter inputs
csf.inputs.contrast = logspace(-1, 0, 10);
csf.inputs.freq = 3;
csf.inputs.repeat = 1;
csf.generateInputs(); % Randomised inputs are saved to csf.genInputs



%% Experiment setup
% Define experimental setup
d = design('contrast-freq');

% Contrast
d.fac1.gabor_test.contrast = csf.genInputs.contrast; 

% Frequency
d.fac1.gabor_test.frequency = csf.genInputs.freq;


d.randomization = 'SEQUENTIAL'; % Prevent auto randomisation of inputs (as we have alread randomised them)
d.retry = 'RANDOM'; % This means retry any trials that fail due to non-fixation in a random position sometime in a future trial

% blk = block('contrast-freq',d);
% blk.nrRepeats = 1;
for i=1:2
    myBlock{i}=block(['contrast-freq',num2str(i)],d);             %Create a block of trials using the factorial. Type "help neurostim/block" for more options.
    myBlock{i}.nrRepeats=csf.inputs.repeat;
    myBlock{i}.afterMessage = 'Take a break!';
    myBlock{i}.beforeMessage = ['Block ', num2str(i) ' of ' num2str(2)];
end


csf.cic.run(myBlock{:});

%% Analyse data
% Gather data
%csfPostProcessing(0, csf.cic);

%% Functions
function beginTrial(c)
  % Randomise position of gabor_test (left or right)
  randLogical = (rand()<0.5); % 1 or 0
  c.gabor_test.X = randLogical*c.testEccentricity + ~randLogical * (-1*c.testEccentricity);
end
