clear all;
%% Prerequisites. 
import neurostim.*

%% Create CIC 
csf = csf_base;

%% Enter inputs
csf.inputs.contrast = [0.3 0.5 0.8];
csf.inputs.freq = [3 6 10];
csf.inputs.repeat = 1;
csf.generateInputs(); % Randomised inputs are saved to csf.genInputs


%% == Adaptations for each trial ==
%% Create durations array for adapter
% Note there are infinite ways to create adapter durations array
% should be based on what the tester wants 
adapterDurations = zeros(1, csf.genInputs.numTrials);
gabTestDelay = zeros(1, csf.genInputs.numTrials);

numTrialsBtwAdapt = 3; % Every 3 trials through an adapter
adapterDurations(1) = 5000; % Initial adaptation 5s
gabTestDelay(1) = 2000; % Give 2 seconds after adaptation until trial starts
for i = (1+numTrialsBtwAdapt):numTrialsBtwAdapt:csf.genInputs.numTrials
    if (i ~= csf.genInputs.numTrials)
        % Don't want to have an adapter and the end of the experiment
        adapterDurations(i) = 1000; % 1s shofter adapters after initial adapter
        gabTestDelay(i) = 500; % Delay 500 ms before running trial
    end
end




%% Experimental setup
% Define experimental setup
d = design('contrast-freq');


% Contrast
d.fac1.gabor_test.contrast = csf.genInputs.contrast; 

% Frequency
d.fac1.gabor_test.frequency = csf.genInputs.freq;

% Right or left
d.fac1.gabor_test.X = csf.genInputs.dispX;

% Delay
d.fac1.gabor_test.delay = ones(1, 9) * 1000;

% Adapter
d.fac1.gL_adapt.frequency = 5;
d.fac1.gL_adapt.duration = adapterDurations; % Some reason the adaptation duration plays in the center? instead of at the start

d.randomization = 'SEQUENTIAL'; % Prevent auto randomisation of inputs (as we have alread randomised them) + our adapters won't be all over the place
d.retry = 'RANDOM'; % NOTE THIS MEANS THAT RANDOMLY PLACED ADAPTATIONS WILL APPEAR AFTER FAILED TRIALS + TOPUP MAY BE INSUFFICIENT => WILL HAVE TO DYNAMICALLY ADJUST THIS / OR  MANUALLY ADD MORE TRIALS AFTER FAILED ATTEMPTS


blk = block('contrast-freq',d);
blk.nrRepeats = 1;
csf.cic.subject = 'easyD';
csf.cic.run(blk);

%% Analyse data
% Possible to do live plotting in between trials ?
% Gather data
csfPostProcessing(0, csf.cic);

