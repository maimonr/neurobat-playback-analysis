function [playSpikes, playbackOrder] = get_play_spikes(expType,spikeFname,stabilityBounds,offset,playback_files_TTL,nlg_TTL_durations,nlg_TTL_timestamps)

switch expType
    case 'juvenile'
        Timestamps=Nlx2MatSpike(spikeFname,[1 0 0 0 0],0,1,[]);
        spike_times=Timestamps/1000; % spike times in ms
        
    case {'adult','adult_social'}
        try
            spike_times = csvread(spikeFname);
        catch err
            
            if strcmp(err.identifier,'MATLAB:textscan:EmptyFormatString')
                playSpikes = [];
                playbackOrder = [];
                return
            else
                rethrow(err)
            end
        end
        
        if size(spike_times,1) ~= 1
            spike_times = spike_times';
        end
end

playSpikes = cell(1,length(playback_files_TTL));
playbackOrder = [];

for audio_file_i=1:length(playback_files_TTL)
    current_file_TTL=playback_files_TTL(audio_file_i); % for files that contain a sequence of calls, only take the TTL duration of the first call
    current_nlg_indices=find(nlg_TTL_durations==current_file_TTL); % all indices where the pulse duration matches the one in the current playback file
    playbackOrder = [playbackOrder current_nlg_indices'];
    playSpikes{audio_file_i} = cell(1,length(current_nlg_indices));
    for trial_i=1:size(current_nlg_indices,1)
        time0=nlg_TTL_timestamps(current_nlg_indices(trial_i)); % time 0 is the time of the last sample before TTL pulse onset (ie. the last 1 before the falling edge)
        if time0 > stabilityBounds(1) && time0 < stabilityBounds(2)
            playSpikes{audio_file_i}{trial_i} = 1e-3* (spike_times(spike_times<=(time0+offset) & spike_times>(time0-offset))-time0);
        else
            playSpikes{audio_file_i}{trial_i} = nan;
        end
    end
    playSpikes{audio_file_i}(cellfun(@(x) any(isnan(x)),playSpikes{audio_file_i})) = [];
end

end