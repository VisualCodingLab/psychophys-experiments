% Written by LZ Mar 2023
% Edited by IHT Nov 2023

clear all

% Prerequisites. 
import neurostim.*

method = 'STAIRCASE'; % Set this to QUEST or STAIRCASE
pianola = false; % Did not include the simulated observe code, always set to 'false'

%% ====== Setup CIC and the stimuli ====== %
syncVariance = 8e-04;
Screen('Preference','SyncTestSettings', syncVariance);


c =  myRig;   
c.paradigm='PhaseComboGabor';
c.addScript('BeforeTrial',@beginTrial); % Script that varies noise pattern, test location
c.addScript('AfterTrial',@afterTrialFunc); % Script that varies noise pattern, test location
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
fix.to              = '@gabor_test3.duration'; % Require fixation until the choice is done.
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
testFreq3 = pedestalFrequency*3;
testFreq5 = pedestalFrequency*5;
phaseList = [0, 90, 180];

% set to 1 as each phase reaches reversal count
c.addProperty('phaseDone', zeros(size(phaseList))); 

% experiment properties
nRepeatsPerCond = 12; % phaseList*nRepeatsPerCond=blockLength
testEccentricity = 5;
testDuration = 500;
nBlocks = 10;

% initialisation of result array
maxTrialNo = nBlocks * nRepeatsPerCond * length(phaseList);
c.addProperty('staircaseResults', NaN(length(phaseList), maxTrialNo));
c.addProperty('staircaseIndexes', ones(length(phaseList), 1));




%% ====== Test gabor properties ====== %
g3=stimuli.gabor(c,'gabor_test3'); % Gabor to display during testing (either left or right) 
g3.sigma = 0.9;
g3.frequency = testFreq3;
g3.mask = 'GAUSS';
g3.phaseSpeed = 0;
g3.orientation = 90;
g3.width = 5;
g3.height = 5;
g3.duration = testDuration;
g3.on = 0;
g3.X = testEccentricity;
g3.Y = 0;
g3.contrast = 1;
g3.color = [0.5 0.5 0.5 1];

g5=stimuli.gabor(c,'gabor_test5'); % Gabor to display during testing (either left or right) 
g5.sigma = 0.9;
g5.frequency = testFreq5;
g5.mask = 'GAUSS';
g5.phaseSpeed = 0;
g5.orientation = 90;
g5.width = 5;
g5.height = 5;
g5.duration = testDuration;
g5.on = 0;
g5.X = testEccentricity;
g5.Y = 0;
g5.contrast = 1;
g5.color = [0.5 0.5 0.5 0.5];




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

gL=stimuli.gabor(c,'gL_pedestal'); % Gabor to display during testing (either left or right) 
gL.sigma = 0.9;
gL.frequency = pedestalFrequency;
gL.mask = 'GAUSS';
gL.phaseSpeed = 0;
gL.orientation = 90;
gL.width = 5;
gL.height = 5;
gL.duration = testDuration;
gL.on = 0;
gL.X = -1*testEccentricity;
gL.Y = 0;
gL.contrast = 1;
gL.color = [0.5 0.5 0.5 pedestalContrast];


% Below statement: If duration is 0 (i.e. no adapter), then
% turn the stimuli on immediately (don't wait for fixation) to
% prevent double fixation waiting time


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
k.from = '@gabor_test3.on'; % Only start recording after test turns on
k.maximumRT= Inf; % Allow inf time for a response
k.keys = {'a' 'l'}; % Press 'A' for "left" gabor, 'L' for "right" gabor 
                                                    
k.correctFun = '@(gabor_test3.X > 0) + 1'; % Function returns the index of the correct response (i.e., key 1 -> L or 2 -> R)
k.required = false; % Do not repeat if incorrect response

% Define trial duration
c.trialDuration = '@choice.stopTime'; % End the trial as soon as the 2AFC response is made.
k.failEndsTrial = false;
k.successEndsTrial  = false;
           
if ~ismac
    plugins.sound(c); 
    s= plugins.soundFeedback(c,'soundFeedback');
    % s.add('waveform','skCorrect.wav','when','afterTrial','criterion','@ choice.correct');
    % s.add('waveform','skIncorrect.wav','when','afterTrial','criterion','@ ~choice.correct');
end 

%% ====== Setup the conditions in a design object ====== %

d{1}=design('phase'); % Can change to orientation/phase/frequency
d{1}.fac1.gabor_test3.phase = phaseList;
nrLevels = d{1}.nrLevels;

if strcmpi(method,'QUEST')
    
    i2p = @(x) (min(10.^x,1)); % Map Quest intensity to contrast values in [0 , 1]
    p2i = @(x) (log10(x));
     
    adpt = plugins.quest(c, '@choice.correct','guess',p2i(0.25),'guessSD',4,'i2p',i2p,'p2i',p2i);
    % adpt.requiredBehaviors = 'fixation'; % Comment for piloting
    d{1}.conditions(:,1).gabor_test3.contrast = duplicate(adpt,[nrLevels 1]);  
    
elseif strcmpi(method,'STAIRCASE')
    adpt = staircaseStopCase(c,'@choice.correct',0.2, 'n',3,'min',0,'max',1,'weights',[2 1],'delta',0.015); % [up, down], 0.01 step-size
    % adpt.requiredBehaviors = 'fixation'; % Comment for piloting
    d{1}.conditions(:,1).gabor_test3.contrast = duplicate(adpt,[nrLevels 1]);
end

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

figure;hold on;
thresh = zeros(length(phaseList), 1);
legendStr = [];

for i=1:length(phaseList)
    legendStr = [legendStr sprintf("%i", phaseList(i))];

    x = 1:c.staircaseIndexes(i)-1;
    y = c.staircaseResults(i, x);
    plot(x,y)

    thresh(i) = c.staircaseResults(i, x(end));

end
xlabel 'Trial'
ylabel 'Contrast '
title ([method ' in action...'])
legend(legendStr)

sprintf('%1.4f, ', thresh)


% phase = get(c.gabor_test.prms.phase,'after','startTime');
% contrast = get(c.gabor_test.prms.contrast,'after','startTime');
% if iscell(phase) 
%     hasNoData = cellfun(@isempty, phase);
%     phase = [phase{~hasNoData}];
%     contrast = contrast(~hasNoData); 
% end
% uV = unique(phase);
% figure;
% hold on
% a=1;
% for u=uV(:)'
%     stay = phase ==u;
%     plot(contrast(stay),'.-');
%     tmp = contrast(stay);
%     thresh(a) = tmp(end);
%     a = a+1;
% end
% 
% xlabel 'Trial'
% ylabel 'Contrast '
% title ([method ' in action...'])
% legend(num2str(uV(:)))
% 
% sprintf('%1.4f, ', thresh)

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

  if c.phaseDone(c.condition)
    c.endTrial()
  end 

%     Screen('BlendFunction', c.window, GL_DST_ALPHA, GL_ONE_MINUS_DST_ALPHA );
    if c.noise_L.on < Inf
        img = getNoiseIm(256, 255); 
        c.noise_L.add(img, 1); 
        c.noise_R.add(img, 1); 
    end

  % Randomise position of gabor_test3 AND gabor_test5 (left or right)
  
  randLogical = (rand()<0.5); % 1 or 0
  eccentricity = c.gR_pedestal.X;
  c.gabor_test3.X = randLogical*eccentricity + ~randLogical * (-1*eccentricity);
  c.gabor_test5.X = c.gabor_test3.X;

  c.gabor_test5.phase = c.gabor_test3.phase;

  c.gabor_test5.contrast = c.gabor_test3.contrast * 3/5;

%   c.gabor_test3.color = [0.5 0.5 0.5 c.gabor_test3.alphaaa];
%   c.gabor_test5.color = [0.5 0.5 0.5 c.gabor_test3.alphaaa * 3/5];

%   ped_alpha = 0.5; % pedestal_contrast
%   g3_alpha = c.gabor_test3.color(4)
%   g5_alpha = c.gabor_test5.color(4)
%   new_alpha = ped_alpha + g3_alpha*(1-ped_alpha);
%   new_alpha = new_alpha + g5_alpha*(1-new_alpha)

%   if (randLogical)
%       % t on right, gL needs altering
%       a = 'left'
%       c.gL_pedestal.color = [0.5 0.5 0.5 new_alpha]
%   else
%     % t on left, gR needs altering
%       a = 'right'
%     c.gR_pedestal.color = [0.5 0.5 0.5 new_alpha]
%   end



end



function afterTrialFunc(c)

%   disp(c.phaseDone)

  if all(c.phaseDone)
        c.cic.endExperiment() 
  end

end
