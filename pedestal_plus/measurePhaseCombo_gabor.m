% Written by LZ Mar 2023
clear all
% Prerequisites. 
import neurostim.*

%============= Enter inputs =====================

% background properties
hasBackground = 0;

% pedestal properties
pedestalFrequency = 1;
pedestalContrast  = 0.2; %0.25; %0.3; %0.3;

% test properties
testFreq = pedestalFrequency*3;
contrastList  = logspace(-2, -0.5, 8);          % the contrast of the test pattern
phaseList = [0 7.5 15 30 60 90 180];

% experiment properties
nRepeatsPerCond = 7;    % conditions: phase/Contrast combos
testEccentricity = 5;
testDuration = 500;
nBlocks = 3;

% Setup CIC and the stimuli.
c =  marmolab.rigcfg;   
c.paradigm='PhaseComboGabor';

c.addScript('BeforeTrial',@beginTrial); % Script that varies noise pattern, test location
c.itiClear = 1;
c.iti= 250;
%c.saveEveryN = length(contrastList)*length(phaseList)*nRepeatsPerCond; % only save between blocks
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



% Test gabor to display left or right

g=stimuli.gabor(c,'gabor_test'); % Gabor to display during testing (either left or right) 
g.sigma = 0.9;
g.frequency = testFreq;
g.mask = 'GAUSS';
g.phaseSpeed = 0;
g.orientation = 90;
g.width = 5;
g.height = 5;
g.duration = testDuration;
g.on = 0;
g.X = testEccentricity;
g.Y = 0;
g.contrast = 1;
% create cell array to cycle colour
for iCon = 1:length(contrastList) 
    tmp = [0.5 0.5 0.5 contrastList(iCon)];
   colorList{iCon} = tmp; 
end

% Pedestal gabors
% Any changes should be only made to gL (as gR copies from gL)
% Realisatically, the only changes made should be to frequency,
% contrast (although should be 1) and duration (vector of
% durations)
gL = duplicate(g,'gL_pedestal'); % Additional gabor to display for adapting image (left acts as master)
% Below statement: If duration is 0 (i.e. no adapter), then
% turn the stimuli on immediately (don't wait for fixation) to
% prevent double fixation waiting time
gL.color = [0.5 0.5 0.5 pedestalContrast];
gL.orientation = 90;
gL.duration = testDuration; % Default no adapter
gL.X = -1*testEccentricity;
gL.Y = 0;
gL.contrast = 1;
gL.frequency = pedestalFrequency;

gR = duplicate(gL, 'gR_pedestal'); % Right adapter (duplicates gL)
gR.X = testEccentricity;

% 1/f background noise
bgL = lightweightTexture(c, 'noise_L');
stopLog(c.noise_L.prms.imgMask);
stopLog(c.noise_L.prms.texImg);
bgL.width = 7;
bgL.height = 7; 
bgL.X = -1*testEccentricity;
if hasBackground
    bgL.on = 0;
else
    bgL.on = Inf;
end

bgR = duplicate(bgL, 'noise_R');
stopLog(c.noise_R.prms.imgMask);
stopLog(c.noise_R.prms.texImg);
bgR.X = testEccentricity;
            
%===== Create Behaviours
% Key behaviour (L for left, R for right)
k = behaviors.keyResponse(c,'choice');
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
d{1}.fac1.gabor_test.color = colorList; 
d{1}.fac2.gabor_test.phase = phaseList;

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


function img = getNoiseIm(sz, rg)
    img = makeNoisePatt(sz, 0, 180, 1.5);
    if rg == 2
        % -1-1
        img = img-mean(img(:)); 
        img = img/max(abs(img(:)));
    elseif rg == 255
    % 0-255
        img = img + abs(min(img(:))); 
        img = img/max(abs(img(:)));
        img = img*255;
    end
end


function beginTrial(c)

  %  Screen('BlendFunction', c.window, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    if c.noise_L.on < Inf
        img = getNoiseIm(256, 255); 
        c.noise_L.add(img, 1); 
        c.noise_R.add(img, 1); 
    end

  % Randomise position of gabor_test (left or right)
  
  randLogical = (rand()<0.5); % 1 or 0
  eccentricity = c.gR_pedestal.X;
  c.gabor_test.X = randLogical*eccentricity + ~randLogical * (-1*eccentricity);
  
end