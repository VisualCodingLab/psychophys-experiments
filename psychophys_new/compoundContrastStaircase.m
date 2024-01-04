% Written by LZ Mar 2023
% Edited by IHT Nov 2023

clear all

% Prerequisites. 
import neurostim.*


%% ====== Setup CIC and the stimuli ====== %

c =  marmolab.rigcfg;   
c.paradigm='PhaseComboGabor';
c.addScript('BeforeTrial',@beginTrial); % Script that varies noise pattern, test location
c.itiClear = 1;
c.iti= 250;
%c.saveEveryN = length(contrastList)*length(phaseList)*nRepeatsPerCond; % only save between blocks
c.trialDuration = Inf; % A trial can only be ended by a mouse click
c.cursor = 'none'; % Hide? 
c.screen.color.background = 0.5*ones(1,3);
%c.subjectNr= 0; % Gives a subject code, turn off to manually input

%% ====== Enforce Fixation ====== %

f = stimuli.fixation(c,'centerPoint'); % Add a fixation point stimulus
f.shape             = 'ABC';
f.color             = [1 1 1];
f.color2            = c.screen.color.background; 
f.size              = 0.75; 
f.size2             = 0.15;
f.X                 = 0;
f.Y                 = 0;
f.on                = 0; % Always on
f.duration          = Inf;

% Make sure there is an eye tracker (or at least a virtual one)

if isempty(c.pluginsByClass('eyetracker'))
    e = neurostim.plugins.eyetracker(c); % Eye tracker plugin not yet added, so use the virtual one. Mouse is used to control gaze position (click)
    e.useMouse = true;
end

fix = behaviors.fixate(c,'fixation');
fix.from            = 500; % If fixation has not been achieved at this time, move to the next trial
fix.to              = '@gabor_f1.duration'; % Require fixation until the choice is done.
fix.X               = 0;
fix.Y               = 0; 
fix.tolerance       = 2;
fix.failEndsTrial  = false; % Make false during piloting

%% ====== Enter inputs ====== %

% background properties (noise background)
hasBackground = 0;

% pedestal properties
pedestalFrequency = 1;
%pedestalContrast  = 0.2; 

% test properties
testFreq = pedestalFrequency*3;
phaseList = 0; %[0 7.5 15 30 60 90 120 150 165 172.5 180];

% experiment properties
nRepeatsPerCond = 12; % phaseList*nRepeatsPerCond=blockLength
testEccentricity = 5;
testDuration = 500;
nBlocks = 10;

%% ====== Test gabor properties ====== %

p=stimuli.gabor(c,'gabor_f1'); % Gabor to display during testing (either left or right) 
p.sigma = 0.9;
p.frequency = pedestalFrequency;
p.mask = 'GAUSS';
p.phaseSpeed = 0;
p.orientation = 90;
p.width = 5;
p.height = 5;
p.duration = testDuration;
p.on = 0;
p.X = testEccentricity;
p.Y = 0;
p.contrast = 1;

g= duplicate(p,'gabor_f3'); % Gabor to display during testing (either left or right) 
g.frequency = p.frequency*3;
g.contrast = 1;
g.color = [0.5 0.5 0.5 p.contrast/3];
  
%% ===== Create Behaviours =====%

% Key behaviour (L for left, R for right)

k = behaviors.keyResponse(c,'choice');
k.verbose = false;
k.from = '@gabor_f1.on'; % Only start recording after test turns on
k.maximumRT= Inf; % Allow inf time for a response
k.keys = {'a' 'l'}; % Press 'A' for "left" gabor, 'L' for "right" gabor 
                                                    
k.correctFun = '@(gabor_f1.X > 0) + 1'; % Function returns the index of the correct response (i.e., key 1 -> L or 2 -> R)
k.required = false; % Do not repeat if incorrect response

% Define trial duration
c.trialDuration = '@choice.stopTime'; % End the trial as soon as the 2AFC response is made.
k.failEndsTrial = false;
k.successEndsTrial  = false;
           
if ~ismac
    plugins.sound(c); 
    s= plugins.soundFeedback(c,'soundFeedback');
    s.add('waveform','skCorrect.wav','when','afterTrial','criterion','@ choice.correct');
    s.add('waveform','skIncorrect.wav','when','afterTrial','criterion','@ ~choice.correct');
end 

%% ====== Setup the conditions in a design object ====== %

d{1}=design('phase'); % Can change to orientation/phase/frequency
d{1}.fac1.gabor_f3.phase = phaseList;
nrLevels = d{1}.nrLevels;

adpt = staircaseStopCase(c,'@choice.correct',0.2, 'n',3,'min',0,'max',1,'weights',[2 1],'delta',0.015); % [up, down], 0.01 step-size
%adpt.requiredBehaviors = 'fixation'; % Comment for piloting
d{1}.conditions(:,1).gabor_f1.contrast = duplicate(adpt,[nrLevels 1]);


% This is blocking code from the demo. One block only.
% myBlock=block('myBlock',d{1});
% myBlock.nrRepeats = 50; % Because the design has X conditions, this results in X*nrRepeats trials.
% c.run(myBlock);

% Create a block for this design and specify the repeats per design
for i=1:nBlocks
    myBlock{i}=block([d{1}.name num2str(i)],d{1}); % Create a block of trials using the factorial. Type "help neurostim/block" for more options.
    myBlock{i}.nrRepeats=nRepeatsPerCond;
    myBlock{i}.afterMessage = 'Take a break!';
    myBlock{i}.beforeMessage = ['Block ', num2str(i) ' of ' num2str(nBlocks)];
end

%%
c.run(myBlock{:});

%% ====== Do some analysis on the data ====== %

% Visualise the staircase in action

import neurostim.utils.*;

% Retrieve orientation and contrast settings for each trial. Trials in
% which those parameters did not change willl not have an entry in the log,
% so we have to fill-in the values (e..g if there is no entry in the log
% for trial N, take the value set in trial N-1.

% Because the parameter can be assigned different values (e.g. the default
% value) at some earlier point in the trial; we only want to retrieve the
% value immediately after the stimulus appeared on the screen. Because this is logged
% by the startTime event, we use the 'after' option of the parameters.get
% member function

phase = get(c.gabor_f3.prms.phase,'after','startTime');
contrast = get(c.gabor_f1.prms.contrast,'after','startTime');
if iscell(phase) 
    hasNoData = cellfun(@isempty, phase);
    phase = [phase{~hasNoData}];
    contrast = contrast(~hasNoData); 
end
uV = unique(phase);
figure;
hold on
a=1;
for u=uV(:)'
    stay = phase ==u;
    plot(contrast(stay),'.-');
    tmp = contrast(stay);
    thresh(a) = tmp(end);
    a = a+1;
end
xlabel 'Trial'
ylabel 'Contrast '
title ([method ' in action...'])
legend(num2str(uV(:)))

sprintf('%1.4f, ', thresh)

%% ====== Functions ====== %



function beginTrial(c)

  % Randomise position of gabor_test (left or right)
  
  randLogical = (rand()<0.5); % 1 or 0
  eccentricity = c.gabor_f1.X;
  c.gabor_f1.X = randLogical*eccentricity + ~randLogical * (-1*eccentricity);
  c.gabor_f3.X = c.gabor_f1.X;
  c.gabor_f3.contrast = 1;
  c.gabor_f3.color = [0.5 0.5 0.5 c.gabor_f1.contrast/3];
end
