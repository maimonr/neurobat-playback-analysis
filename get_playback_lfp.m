function playback_csc_struct = get_playback_lfp(expType,lfp_playback_offset,nlg_TTL_durations,nlg_TTL_timestamps,audio2nlg_fname,lfp_file_name,lfpData)

overwriteFlag = true;

switch expType
    
    case {'adult','adult_social'}
        if isempty(nlg_TTL_timestamps) || any(isnan(nlg_TTL_timestamps))
            return
        end
        
        if size(nlg_TTL_timestamps,2) == 1
            nlg_TTL_timestamps = nlg_TTL_timestamps';
            nlg_TTL_durations = nlg_TTL_durations';
        end
        
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

n_channel = length(lfpData.active_channels);

lfp_playback_offset_csc_samples = round(lfp_playback_offset*fs);
n_lfp_samples = 2*lfp_playback_offset_csc_samples + 1;

used_playback_idx = [Inf diff(nlg_TTL_timestamps)] > 1e3*lfp_playback_offset & (nlg_TTL_timestamps-1e3*lfp_playback_offset > min(timestamps)) & (nlg_TTL_timestamps+1e3*lfp_playback_offset < max(timestamps));
nlg_TTL_timestamps = nlg_TTL_timestamps(used_playback_idx);
n_used_playbacks = sum(used_playback_idx);

playback_csc = zeros(n_lfp_samples,n_used_playbacks,n_channel);
tic;
for call_k = 1:n_used_playbacks
    
    [~,csc_playback_idx] = min(abs(timestamps - nlg_TTL_timestamps(call_k))); 
    
    csc_idx = (csc_playback_idx-lfp_playback_offset_csc_samples):(csc_playback_idx+lfp_playback_offset_csc_samples);
    playback_lfp_data = lfpData.lfpData(:,csc_idx);
    
    for ch = 1:n_channel
        playback_csc(:,call_k,ch) = playback_lfp_data(ch,:);
        playback_csc(:,call_k,ch) = filtfilt(notch_filter_60Hz,playback_csc(:,call_k,ch));
        playback_csc(:,call_k,ch) = filtfilt(notch_filter_120Hz,playback_csc(:,call_k,ch));
    end
end
toc
playback_csc_struct = struct('playback_csc',playback_csc,'filters',{filters},...
    'lfp_call_offset',lfp_playback_offset,'playback_TTL_durations',nlg_TTL_durations,...
    'playback_TTL_timestamps',nlg_TTL_timestamps);
%%

save(outDir,'-struct','playback_csc_struct')


end