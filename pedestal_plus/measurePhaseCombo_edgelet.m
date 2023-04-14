% Written by LZ Mar 2023
clear all
% Prerequisites. 
import neurostim.*

%============= Enter inputs =====================

% background properties
hasBackground = 1;

% pedestal properties
pedestalFrequency = 0.5;
pedestalContrast  = 0.5;

% test properties
testFrequency = pedestalFrequency;
contrastList   = logspace(-0.5, 0, 4);          % the contrast of the test pattern
phaseList = [0 2.5 5 10 20 45 90 180];          % width of phase randomness

% experiment properties
nRepeatsPerCond = 2;    % conditions: phase/Contrast combos
testEccentricity = 6;
testDuration = 1000;
nBlocks = 2;

% Setup CIC and the stimuli.
c =  marmolab.rigcfg;   


c.addScript('BeforeTrial',@beginTrial); % Script that varies noise pattern, test location
c.itiClear = 0;
c.trialDuration = Inf; % A trial can only be ended by a mouse click
c.cursor = 'none'; % hide? 
c.screen.color.background = 0.5*ones(1,3);

            
%===== Create Stimuli
% Add center point fixation 
% Note: Could possible add eye tracker to see if participant
% is looking at the center point fixation
f = stimuli.fixation(c,'centerPoint');       % Add a fixation point stimulus
f.shape             = 'ABC';
f.color             = [1 1 1];
f.color2            = c.screen.color.background;
f.size              = 0.75; 
f.size2             = 0.15;
f.X                 = 0;
f.Y                 = 0;
f.on                = 0;                % Always on
f.duration          = Inf;

% 1/f background noise
bgL = lightweightTexture(c, 'noise_L');
bgL.width = 7;
bgL.height = 7; 
bgL.X = -1*testEccentricity;
if hasBackground
    bgL.on = 0;
else
    bgL.on = Inf;
end

bgR = duplicate(bgL, 'noise_R');
bgR.X = testEccentricity;


% Test edgelet to display left or right
g=nWave(c,'edgelet_test'); % Gabor to display during testing (either left or right) 
g.color = [0.5 0.5 0.5];
g.frequency = testFrequency;
g.phaseSpeed = 0;
g.orientation = 90;
g.width = 6;
g.height = 6;
g.mask ='GAUSS3';
g.duration = testDuration;
g.on = 0;
g.type = 'PSSquare';
g.harmonics = 1:2:20; % the pedestal is the fundamental
g.multiGaborsN = 5; % how many harmonics to draw?
g.X = testEccentricity;
g.Y = 2;

% Pedestal gabors
% Any changes should be only made to gL (as gR copies from gL)
% Realisatically, the only changes made should be to frequency,
% contrast (although should be 1) and duration (vector of
% durations)
gL = stimuli.gabor(c,'gL_pedestal'); % Additional gabor to display for adapting image (left acts as master)
% Below statement: If duration is 0 (i.e. no adapter), then
% turn the stimuli on immediately (don't wait for fixation) to
% prevent double fixation waiting time
gL.sigma = 0.75;
gL.orientation = g.orientation; 
gL.phaseSpeed = g.phaseSpeed;
gL.width = g.width;
gL.height = g.height; 
gL.mask = g.mask;
gL.on = g.on;
gL.color = [0.5 0.5 0.5 pedestalContrast];
gL.duration = testDuration; % Default no adapter
gL.X = -1*testEccentricity;
gL.Y = 0;
gL.contrast = 1;
gL.frequency = pedestalFrequency;

gR = duplicate(gL, 'gR_pedestal'); % Right adapter (duplicates gL)
gR.X = testEccentricity;
            
%===== Create Behaviours
% Key behaviour (L for left, R for right)
k = behaviors.keyResponse(c,'choice');
k.verbose = false;
k.from = '@edgelet_test.on'; % Only start recording after test turns on
k.maximumRT= Inf;                   %Allow inf time for a response
k.keys = {'a' 'l'};                                 %Press 'A' for "left" gabor, 'L' for "right" gabor -> 
                                                    %Note: This was changed
                                                    %from R & L because R
                                                    %is on the left side of
                                                    %the keyboard and L is
                                                    %on the right side of
                                                    %the keyboard
k.correctFun = '@(edgelet_test.X > 0) + 1';   %Function returns the index of the correct response (i.e., key 1 -> L or 2 -> R)
k.required = false; % Do not repeat if incorrect response
% Define trial duration
c.trialDuration = '@choice.stopTime';       %End the trial as soon as the 2AFC response is made.
k.failEndsTrial = false;
k.successEndsTrial  = false;
           
if ~ismac
    plugins.sound(c); 
    s= plugins.soundFeedback(c,'soundFeedback');
    s.add('waveform','skCorrect.wav','when','afterTrial','criterion','@ choice.correct');
    s.add('waveform','skIncorrect.wav','when','afterTrial','criterion','@ ~choice.correct');
end 


% Experimental setup
% Define experimental setup
d{1}= design('Pedestal-Test');
d{1}.fac1.edgelet_test.contrast = contrastList; 
d{1}.fac2.edgelet_test.phaseWindow = phaseList;

% load designs into blocks

for i=1:nBlocks
    myBlock{i}=block([d{1}.name num2str(i)],d{1});             %Create a block of trials using the factorial. Type "help neurostim/block" for more options.
    myBlock{i}.nrRepeats=nRepeatsPerCond;
    myBlock{i}.afterMessage = 'Take a break!';
    myBlock{i}.beforeMessage = ['Block ', num2str(i) ' of ' num2str(nBlocks)];
end

%%
c.run(myBlock{:});

%% Functions

function img = getNoiseIm(sz)
    img = makeNoisePatt(sz, 0, 180, 1.4);
    img = img + abs(min(img(:))); 
    img = img/max(abs(img(:)));
    img = img*255;
end

function beginTrial(c)
    
    if c.noise_L.on < Inf
        img = getNoiseIm(256); 
        c.noise_L.add(img, 1); 
        c.noise_R.add(img, 1); 
    end

  % Randomise position of edgelet_test (left or right)
  randLogical = (rand()<0.5); % 1 or 0
  eccentricity = c.gR_pedestal.X;
  c.edgelet_test.X = randLogical*eccentricity + ~randLogical * (-1*eccentricity);
  
end