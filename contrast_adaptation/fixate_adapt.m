% fixate_adapt
% Custom eye movement behaviour that tracks if the eye is
% in the required zone for a duration. If the eye is not in the zone, there
% is an extended beep sound that is played
%
% Key props
% on: When to start measuring fixation/freeviewing
% from: When to start playing the beeping sound if not fixating
% to: When to stop playing beeping sound 
% 
% Key outputs
% @obj.startTime.initialFixate: The first time the user fixates
% @obj.startTime.fixating: The last time the user fixated
%
% States
% initialFreeViewing: Start state at each trial
% initialFixate: Next state in each trial
% fixating: State that records fixating after initialFixate
% freeViewing: State that records freeviewing after initialFreeViewing
% 
% Possible Additions:
% -Measure and log duration of fixation (i.e. summing the time
% in the fixation/initialFixation)
% -Measure and log average eye distance away from center

classdef fixate_adapt  < neurostim.behaviors.eyeMovement
    properties (Dependent)
       isFreeViewing;
       isFixating;
    end

    properties 
        player
        storedDistances
        recordedDistances
        recordedDurations
        durStart
        durStop
    end
    
    % State functions
    methods
        % In the constructor, a behavior must define the beforeTrialState -
        % the state where each trial will start.
        function o = fixate_adapt(c,name)
            import neurostim.*
            o = o@neurostim.behaviors.eyeMovement(c,name);
            o.beforeTrialState = @o.initialFreeViewing; % Initial state at the start of each trial
            %o.player = audioplayer(cos(1:0.5:10^3), 10000); % Sound
            %doesn't work
            o.cic = c;
            o.addProperty('recordedDistance',0,'validate',@isnumeric);  % log recorded distance
            o.addProperty('recordedDuration',0,'validate',@isnumeric);  % log recorded duration
            o.storedDistances = [];
            o.recordedDistances = [];
            o.recordedDurations = [];
            o.durStart = [0];
            o.durStop = [];
        end

        function afterTrial(o)
            o.recordedDistance = mean(o.storedDistances);
            o.recordedDistances = [o.recordedDistances mean(o.storedDistances)];


            % Test for uneven stop/start - means that missing end
            if (length(o.durStart) ~= length(o.durStop))
                o.durStop = [o.durStop o.cic.trialTime];
            end
            
            o.durStop = o.durStop(o.durStop > o.from);
            o.durStart = o.durStart(o.durStart > o.from);
            if (length(o.durStop) ~= length(o.durStart))
                o.durStart = [o.from o.durStart];
            end 

            o.durStop = o.durStop(o.durStop < o.to);
            o.durStart = o.durStart(o.durStart < o.to);
            if (length(o.durStop) ~= length(o.durStart))
                o.durStop = [o.durStop o.to];
            end 

            totalAccumDur = sum(o.durStop - o.durStart) / 1000;

            o.recordedDuration = totalAccumDur;
            o.recordedDurations = [o.recordedDurations totalAccumDur];

            o.storedDistances = []; % CALCULATE MEANS OF STORED DISTANCES + MEASURE DURATIONS 
            o.durStart = [0];
            o.durStop = [];
        end
        
        %% States
        % Each state is a member function that takes trial time (t) and an
        % event (e) as its input. The function inspects the event or the
        % time and then decides whether a transition to a new state is in
        % order
        % In addition to regular events (e.isRegular) states also receive
        % events that signal that a state is about to begin (e.isEntry) or
        % end (e.isExit). By checking for these events, the state can do
        % some setup - most states don't have to do anything. 
        

        % Use initialFreeViewing state as a quick&dirty fix to the recursion
        % checks that neurostim/ptb does (i.e. if trial ends on
        % freeviewing, then an error will be thrown because the starting
        % state will be freeviewing, so it doesn't like
        % freeviewing->freeviewing so instead it'll be
        % freeviewing->initialFreeViewing->freeviewing
        % Additionally, it allows to define a new startTime (to ensure it
        % isn't reset)
        function initialFreeViewing(o, t, e)
            if ~e.isRegular; return; end % No Entry/exit needed.
            if (t > o.on && t < o.to)
                o.measureDistance(t,e);
                [inside,isAllowedBlink] = isInWindow(o,e);  
                if inside && ~isAllowedBlink
                    o.durStop = [o.durStop t];
                    transition(o,@o.initialFixate,e);  % Note that there is no restriction on t so fixation can start any time after t.on (which is when the behavior starts running)      
                    %stop(o.player);
                    o.setWhite;
                else
                    % Maintain freeViewing characteristics
                    o.whileFreeviewing(t, e);
                end
            end
        end
        
        % The first fixation will come here, so we can record the startTime
        % In this way, we are not rewriting the startTime with each
        % fixation. Could be a potential behaviour we want however...
        function initialFixate(o, t, e)
            if (t > o.to) 
                @o.success; 
                %stop(o.player)
                o.setWhite;
            end
            if ~e.isRegular; return; end % No Entry/exit needed.

            if (t > o.on && t < o.to)
                o.measureDistance(t,e);
                [inside,isAllowedBlink] = isInWindow(o,e);  
                if ~inside && ~isAllowedBlink
                    o.durStart = [o.durStart t];
                    transition(o,@o.freeViewing,e); % return to FREEVIEWING, no penalty
                    o.whileFreeviewing(t, e);
                else
                    % Stay in fixating -> do fixating stuff
                end
            end
        end


        function freeViewing(o,t,e)
            if (t > o.to)
                @o.fail; 
%                 stop(o.player);
                  o.setWhite;
            end
            if ~e.isRegular; return; end % No Entry/exit needed.
            if (t > o.on && t < o.to)
                o.measureDistance(t,e);
                [inside,isAllowedBlink] = isInWindow(o,e);  
                if inside && ~isAllowedBlink
                    o.durStop = [o.durStop t];
                    transition(o,@o.fixating,e);  % Note that there is no restriction on t so fixation can start any time after t.on (which is when the behavior starts running)      
%                     stop(o.player);
                    o.setWhite;
                else
                    % Stay in freeviewing -> do freeviewing stuff
                    o.whileFreeviewing(t, e); 
                end
            end
        end
        
        % A second state.  Note that there is no if(fixating) code; the only
        % time that this code is called is when the state is 'fixating'. We
        % only have to look forward (where to transition to), it does not
        % matter where we came from.
        function fixating(o,t,e)
            if (t > o.to) 
                @o.success; 
%                 stop(o.player)
                  o.setWhite;
            end
            if ~e.isRegular; return; end % No Entry/exit needed.

            if (t > o.on && t < o.to)
                o.measureDistance(t,e);
                [inside,isAllowedBlink] = isInWindow(o,e);  
                if ~inside && ~isAllowedBlink
%                    remove(o.iStartTime,o.stateName); % clear FIXATING startTime
                    o.durStart = [o.durStart t];
                    transition(o,@o.freeViewing,e); % return to FREEVIEWING, no penalty
                    o.whileFreeviewing(t, e);
                else
                    % Stay in fixating -> do fixating stuff
                end
            end
        end

        function measureDistance(o, t, e)
            if (t > o.from && t < o.to)
                XY = [+o.X +o.Y];
                distance = sqrt(sum(([e.X e.Y] - XY).^2));
                o.storedDistances = [o.storedDistances distance];
                %o.recordedDistance = average;
            end
        end

        


        function whileFreeviewing(o, t,e)
            if (t > o.from && t < o.to)
%                 play(o.player); % Keeps playing to ensure length

                   if (isequal(o.cic.centerPoint.color, [1 1 1]))
                       o.cic.centerPoint.color = [1 0 0];
                   end
            else
%                 stop(o.player)
                  o.setWhite;
            end
        end
        
        function setWhite(o)
           if (~isequal(o.cic.centerPoint.color, [1 1 1]))
               o.cic.centerPoint.color = [1 1 1];
           end
        end
       
    end % methods
    
    methods % get methods
        function v = get.isFreeViewing(o)
          v = strcmpi(o.stateName,'FREEVIEWING');
        end

        function v = get.isFixating(o)
            v = strcmpi(o.stateName,'FIXATING');
        end
    end
  
end % classdef