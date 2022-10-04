

%% Prerequisites. 
import neurostim.*

%% Create CIC 
csf = csf_base;

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

% Right or left
d.fac1.gabor_test.X = csf.genInputs.dispX;


blk = block('contrast-freq',d);
blk.nrRepeats = 1;
csf.cic.subject = 'easyD';
csf.cic.run(blk);

%% Analyse data
% Possible to do live plotting in between trials ?
% Gather data
csfPostProcessing(0, csf.cic);

