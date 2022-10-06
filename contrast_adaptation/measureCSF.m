

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



%% Experiment setup
% Define experimental setup
d = design('contrast-freq');

% Contrast
d.fac1.gabor_test.contrast = csf.genInputs.contrast; 

% Frequency
d.fac1.gabor_test.frequency = csf.genInputs.freq;


d.randomization = 'SEQUENTIAL'; % Prevent auto randomisation of inputs (as we have alread randomised them)
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
  % Randomise position of gabor_test (left or right)
  randLogical = (rand()<0.5); % 1 or 0
  c.gabor_test.X = randLogical*5 + ~randLogical * (-5);
end
