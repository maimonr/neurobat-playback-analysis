function playback_csc_struct = get_playback_lfp(expType,lfp_playback_offset,event_file_fname,audio2nlg_fname,lfp_file_name,lfpData)

overwriteFlag = true;

switch expType
    
    case 'adult'
        playback_files_TTL = 1:400;
        
        [nlg_TTL_durations,nlg_TTL_timestamps] = get_play_events(expType,event_file_fname,playback_files_TTL);
        nlg_TTL_timestamps = nlg_TTL_timestamps';
        if isempty(nlg_TTL_timestamps) || any(isnan(nlg_TTL_timestamps))
            return
        end
        
        lfpData_data_name = 'lfpData';
        fs = lfpData.fs;
        timestamps = lfpData.timestamps;
        
        s = load(audio2nlg_fname);
        timestamps = 1e3*timestamps + s.first_nlg_pulse_time;
        
        outDir = lfp_file_name;
        
    case 'juvenile'

        keyboard
        
end

if ~overwriteFlag
    m = matfile(lfp_file_name);
    varNames = who(m);
    
    if ~overwriteFlag && any(ismember(varNames,'playback_csc_struct'))
        disp('call trig lfp already calculated')
        return
    end
end

notch_filter_60Hz=designfilt('bandstopiir','FilterOrder',2,'HalfPowerFrequency1',59.5,'HalfPowerFrequency2',60.5,'DesignMethod','butter','SampleRate',fs);
notch_filter_120Hz=designfilt('bandstopiir','FilterOrder',2,'HalfPowerFrequency1',119.5,'HalfPowerFrequency2',120.5,'DesignMethod','butter','SampleRate',fs);
filters = {notch_filter_60Hz,notch_filter_120Hz};
%%

n_channel = size(lfpData.(lfpData_data_name),1);

lfp_playback_offset_csc_samples = round(lfp_playback_offset*fs);
n_lfp_samples = 2*lfp_playback_offset_csc_samples + 1;

used_playback_idx = [Inf diff(nlg_TTL_timestamps)] > 1e3*lfp_playback_offset & (nlg_TTL_timestamps-1e3*lfp_playback_offset > min(timestamps)) & (nlg_TTL_timestamps+1e3*lfp_playback_offset < max(timestamps));
nlg_TTL_timestamps = nlg_TTL_timestamps(used_playback_idx);
n_used_playbacks = sum(used_playback_idx);

[timestamps,t_idx] = inRange(timestamps,[min(nlg_TTL_timestamps)-1e3*lfp_playback_offset max(nlg_TTL_timestamps)+1e3*lfp_playback_offset]);
lfpData.(lfpData_data_name) = lfpData.(lfpData_data_name)(:,t_idx);

csc_playback_idx = zeros(1,n_used_playbacks);
for call_k = 1:n_used_playbacks
    [~,csc_playback_idx(call_k)] = min(abs(timestamps - nlg_TTL_timestamps(call_k))); 
end

playback_csc = zeros(n_lfp_samples,n_used_playbacks,n_channel);
parfor ch = 1:n_channel
    lfp_one_channel = lfpData.(lfpData_data_name)(ch,:);
    lfp_one_channel = filtfilt(notch_filter_60Hz,lfp_one_channel);
    lfp_one_channel = filtfilt(notch_filter_120Hz,lfp_one_channel);
    for call_k = 1:n_used_playbacks
        csc_idx = (csc_playback_idx(call_k)-lfp_playback_offset_csc_samples):(csc_playback_idx(call_k)+lfp_playback_offset_csc_samples);
        playback_csc(:,call_k,ch) = lfp_one_channel(csc_idx);
    end
end

playback_csc_struct = struct('playback_csc',playback_csc,'filters',{filters},...
    'lfp_call_offset',lfp_playback_offset,'playback_TTL_durations',nlg_TTL_durations,...
    'playback_TTL_timestamps',nlg_TTL_timestamps);
%%
if exist('outDir','var')
    save(outDir,'-struct','playback_csc_struct')
else
    save(lfp_file_name,'-append','playback_csc_struct')
end

end