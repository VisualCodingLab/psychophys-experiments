% Written by LZ Mar 2023
% Edited by IHT Nov 2023

clear all

% Prerequisites. 
import neurostim.*

method = 'QUEST'; % Set this to QUEST or STAIRCASE
pianola = false; % Did not include the simulated observe code, always set to 'false'

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
fix.to              = '@choice.stopTime'; % Require fixation until the choice is done.
fix.X               = 0;
fix.Y               = 0; 
fix.tolerance       = 2;
fix.failEndsTrial  = false; % Make false during piloting

%% ====== Enter inputs ====== %

% background properties (noise background)
hasBackground = 0;

% pedestal properties
pedestalFrequency = 1;
pedestalContrast  = 0.2; 

% test properties
testFreq = pedestalFrequency*3;
phaseList = [0 90 180];

% experiment properties
nRepeatsPerCond = 5; % phaseList*nRepeatsPerCond=blockLength
testEccentricity = 5;
testDuration = 500;
nBlocks = 3;

%% ====== Test gabor properties ====== %

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

% % create cell array to cycle colour
% for iCon = 1:length(contrastList) 
%     tmp = [0.5 0.5 0.5 contrastList(iCon)];
%    colorList{iCon} = tmp; 
% end

%% ====== Pedestal gabor properties ====== %

% Any changes should be only made to gL (as gR copies from gL)
% Realistically, the only changes made should be to frequency,
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

%% ====== 1/f background noise ====== %

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
            
%% ===== Create Behaviours =====%

% Key behaviour (L for left, R for right)

k = behaviors.keyResponse(c,'choice');
k.verbose = false;
k.from = '@gabor_test.on'; % Only start recording after test turns on
k.maximumRT= Inf; % Allow inf time for a response
k.keys = {'a' 'l'}; % Press 'A' for "left" gabor, 'L' for "right" gabor 
                                                    
k.correctFun = '@(gabor_test.X > 0) + 1'; % Function returns the index of the correct response (i.e., key 1 -> L or 2 -> R)
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
d{1}.fac1.gabor_test.phase = phaseList;
nrLevels = d{1}.nrLevels;

if strcmpi(method,'QUEST')
  % To estimate threshold adaptively, the Quest method can be used. We need
    % to define two functions to map the random intensity variable with values between
    % -Inf and Inf that Quest "optimizes" to a meaningful contrast value. We'll
    % assume that the Quest intensity models the log10 of the contrast. i2p and
    % p2i implement that mapping.
    
    i2p = @(x) (min(10.^x,1)); % Map Quest intensity to contrast values in [0 , 1]
    p2i = @(x) (log10(x));
    
  % Define a quest procedure with an initial guess, and our confidence in
    % that guess, and tell the Quest procedure which function to evaluate to
    % determine whether the response was correct or not. To setup Quest to use
    % the subject's responses, use the following:
    
    % Note again the .conditions usage that applies the Quest plugin to each level of the first factor.
    % An important difference with the Jitter parameter above is that we
    % want to have a separate quest for the two orientations. To achieve
    % that we could explicitly create two Quest plugins and assign those to the
    % conditions(:,1).grat ing.contrast = {quest1,quest2}, but in the current example both Quests have
    % identical parameters, so it is easier to duplicate them using the duplicate function.
     
    adpt = plugins.quest(c, '@choice.correct','guess',p2i(0.25),'guessSD',4,'i2p',i2p,'p2i',p2i);
    adpt.requiredBehaviors = 'fixation';
    d{1}.conditions(:,1).grating.contrast = duplicate(adpt,[nrLevels 1]);  
    
elseif strcmpi(method,'STAIRCASE')
    adpt = plugins.nDown1UpStaircase(c,'@choice.correct',rand,'min',0,'max',1,'weights',[2 3],'delta',0.01); % [up, down], 0.01 step-size
    % adpt.requiredBehaviors = 'fixation'; % Comment for piloting
    d{1}.conditions(:,1).gabor_test.contrast = duplicate(adpt,[nrLevels 1]);
end

myBlock=block('myBlock',d{1});
myBlock.nrRepeats = 50; % Because the design has X conditions, this results in X*nrRepeats trials.
c.run(myBlock);

% Create a block for this design and specify the repeats per design
% for i=1:nBlocks
%     myBlock{i}=block([d{1}.name num2str(i)],d{1}); % Create a block of trials using the factorial. Type "help neurostim/block" for more options.
%     myBlock{i}.nrRepeats=nRepeatsPerCond;
%     myBlock{i}.afterMessage = 'Take a break!';
%     myBlock{i}.beforeMessage = ['Block ', num2str(i) ' of ' num2str(nBlocks)];
% end

%%
% c.run(myBlock{:});

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

orientation = get(c.gabor_test.prms.phase,'after','startTime');
contrast = get(c.gabor_test.prms.contrast,'after','startTime');
uV = unique(orientation);
figure;
hold on
for u=uV(:)'
    stay = orientation ==u;
    plot(contrast(stay),'.-');
end
xlabel 'Trial'
ylabel 'Contrast '
title ([method ' in action...'])
legend(num2str(uV(:)))

%% ====== Functions ====== %

% Must be at the end

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
