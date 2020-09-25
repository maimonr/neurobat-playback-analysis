function [nlg_TTL_durations,nlg_TTL_timestamps] = get_play_events(expType,event_file_fname,playback_files_TTL)

all_playback_TTL_durations=unique(playback_files_TTL);

eventData = load(event_file_fname,'event_timestamps_usec','event_types_and_details');

switch expType
    
    case 'juvenile'
        session_strings = {'start_playback','end_playback'};
    case {'adult','adult_social'}
        session_strings = {'start_playback','stop_playback'};
end

index_playback_session_start=find(~cellfun(@isempty,strfind(eventData.event_types_and_details,session_strings{1})),1,'last');
index_playback_session_end=find(~cellfun(@isempty,strfind(eventData.event_types_and_details,session_strings{2})),1,'last');
if any(index_playback_session_start)
    session_start_time=eventData.event_timestamps_usec(index_playback_session_start(end));
else
    disp('couldn''t find playback start time');
    keyboard;
    index_playback_session_start = input('index for session start into event_types_and_details?');
    session_start_time=eventData.event_timestamps_usec(index_playback_session_start(end));
end
if any(index_playback_session_end)
    session_end_time=eventData.event_timestamps_usec(index_playback_session_end);
else
    disp('couldn''t find playback end time');
    keyboard;
    index_playback_session_end = input('index for session start into event_types_and_details?');
    session_end_time=eventData.event_timestamps_usec(index_playback_session_end);
end
event_din_idx = contains(eventData.event_types_and_details,'Digital in');
session_idx = (eventData.event_timestamps_usec>=session_start_time) & (eventData.event_timestamps_usec<=session_end_time);
Nlg_EventTimestamps = eventData.event_timestamps_usec(event_din_idx & session_idx);
Nlg_EventStrings = eventData.event_types_and_details(event_din_idx & session_idx);

Nlg_EventTimestamps=Nlg_EventTimestamps/1000; % convert to ms, without rounding to integer ms

% loop over all event strings and find corresponding falling/rising edges
% and their timestamps; note that a single TTL pulse begins with a
% falling edge
n_events = length(Nlg_EventStrings);
n_TTL_events = 0;
nlg_TTL_timestamps=nan(n_events,1);
nlg_TTL_durations=nan(n_events,1);
for ii_event = 1:n_events
    % find falling edge
    if any(strfind(Nlg_EventStrings{ii_event},'falling'))
        % record new TTL event
        fall_time = Nlg_EventTimestamps(ii_event);
        n_TTL_events = n_TTL_events + 1;
        nlg_TTL_timestamps(n_TTL_events) = fall_time;
        % find next rising edge and store duration of TTL event
        if any(strfind(Nlg_EventStrings{ii_event+1},'rising'))
            rise_time = Nlg_EventTimestamps(ii_event+1);
        elseif any(strfind(Nlg_EventStrings{ii_event+1},'falling')) % two falling edges in a row
            disp(['ERROR: no corresponding rising edge for event at time ' num2str(fall_time) '; TTL duration will be set to 0'])
            rise_time = fall_time; % TTL duration will be set to 0
        elseif ii_event+1 == n_events % overflow: reached end of event list
            disp(['ERROR: rising edge past the end of recording time for event at time ' num2str(fall_time) '; TTL duration will be set to 0'])
            rise_time = fall_time; % TTL duration will be set to 0
        end
        nlg_TTL_durations(n_TTL_events)=round(rise_time-fall_time); % round to integer ms
    end
end
nlg_TTL_timestamps(isnan(nlg_TTL_timestamps))=[];
nlg_TTL_durations(isnan(nlg_TTL_durations))=[];
nlg_TTL_timestamps=round(nlg_TTL_timestamps); % round to integer ms

nlg_orphan_TTL=nlg_TTL_durations(~ismember(nlg_TTL_durations,all_playback_TTL_durations)); % neurologger TTL durations that are not found in the audio playback files
if any(nlg_orphan_TTL)
end
playback_orphan_TTL=all_playback_TTL_durations(~ismember(all_playback_TTL_durations,nlg_TTL_durations)); % neurologger TTL durations that are not found in the audio playback files
if any(playback_orphan_TTL)
end

end