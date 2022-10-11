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

classdef fixate_adapt  < neurostim.behaviors.eyeMovement
    properties (Dependent)
       isFreeViewing;
       isFixating;
    end

    properties 
        player
    end
    
    % State functions
    methods
        % In the constructor, a behavior must define the beforeTrialState -
        % the state where each trial will start.
        function o = fixate_adapt(c,name)
            o = o@neurostim.behaviors.eyeMovement(c,name);
            o.beforeTrialState = @o.initialFreeViewing; % Initial state at the start of each trial 
            o.player = audioplayer(cos(1:0.5:10^5), 10000);

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
                [inside,isAllowedBlink] = isInWindow(o,e);  
                if inside && ~isAllowedBlink
                    transition(o,@o.initialFixate,e);  % Note that there is no restriction on t so fixation can start any time after t.on (which is when the behavior starts running)      
                    stop(o.player);
                else
                    % Maintain freeViewing characteristics
                    o.whileFreeviewing(t);
                end
            end
        end
        
        % The first fixation will come here, so we can record the startTime
        % In this way, we are not rewriting the startTime with each
        % fixation. Could be a potential behaviour we want however...
        function initialFixate(o, t, e)
            if (t > o.to) 
                @o.success; 
                stop(o.player)
            end
            if ~e.isRegular; return; end % No Entry/exit needed.

            if (t > o.on && t < o.to)
                [inside,isAllowedBlink] = isInWindow(o,e);  
                if ~inside && ~isAllowedBlink
                    transition(o,@o.freeViewing,e); % return to FREEVIEWING, no penalty
                    o.whileFreeviewing(t);
                else
                    % Stay in fixating -> do fixating stuff
                end
            end
        end


        function freeViewing(o,t,e)
            if (t > o.to)
                @o.fail; 
                stop(o.player);
            end
            if ~e.isRegular; return; end % No Entry/exit needed.
            if (t > o.on && t < o.to)
                [inside,isAllowedBlink] = isInWindow(o,e);  
                if inside && ~isAllowedBlink
                    transition(o,@o.fixating,e);  % Note that there is no restriction on t so fixation can start any time after t.on (which is when the behavior starts running)      
                    stop(o.player);
                else
                    % Stay in freeviewing -> do freeviewing stuff
                    o.whileFreeviewing(t);
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
                stop(o.player)
            end
            if ~e.isRegular; return; end % No Entry/exit needed.

            if (t > o.on && t < o.to)
                [inside,isAllowedBlink] = isInWindow(o,e);  
                if ~inside && ~isAllowedBlink
%                    remove(o.iStartTime,o.stateName); % clear FIXATING startTime
                    transition(o,@o.freeViewing,e); % return to FREEVIEWING, no penalty
                    o.whileFreeviewing(t);
                else
                    % Stay in fixating -> do fixating stuff
                end
            end
        end

        function whileFreeviewing(o, t)
            if (t > o.from && t < o.to)
                 play(o.player); % Keeps playing to ensure length
            else
                stop(o.player)
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