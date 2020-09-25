function [playSpikes, playbackOrder, sig, playback_bat_nums] = batch_get_playback_spikes(cell_stability_info,baseDir,expType)

offset = 2000;
cellInfo = {cell_stability_info.cellInfo};
batNums = {cell_stability_info.batNum};
all_bat_nums = unique(batNums);

date_str_regexp = '\d{8}';

switch expType
    
    case 'juvenile'
        playback_dir_strs = {'playback_files','playback','playback','playback_files'};
        
    case 'adult'
        T = readtable('Y:\users\maimon\adult_recording\documents\recording_logs.csv');
        idx = strcmp(T.Session,'playback');
        T = T(idx & T.usable,:);
        audio2nlg_str = '_audio2nlg_fit';
    case 'adult_social'
        recLogs = readtable('Z:\users\Maimon\adult_social_recording\documents\recording_logs.csv');
        s = load(fullfile(baseDir,'playback_data','playback_times_and_ttls.mat'));
        playbackResults = s.playbackResults;
        bat_duration_map = s.bat_duration_map;
        k = 1;
        sessStr = cell(1,size(playbackResults,1));
        for expDate = playbackResults.expDate'
            idx = find(recLogs.Date == expDate,1,'first');
            sessStr{k} = recLogs.Session{idx};
            k = k + 1;
        end
        assert(length(unique(sessStr)) == 1)
        audio2nlg_str = '_audio2nlg_fit_social';
end

[playSpikes,playbackOrder,playback_bat_nums] = deal(cell(1,length(cellInfo)));

for cell_k = 1:length(cellInfo)
    b = find(strcmp(batNums{cell_k},all_bat_nums));
    exp_date_str = regexp(cellInfo{cell_k},date_str_regexp,'match');
    switch expType
        
        case 'juvenile'
            if strcmp(batNums{cell_k},'71319')
                playback_files_TTL = 1:6;
            else
                audioDir = [baseDir 'bat' batNums{cell_k} filesep 'neurologger_recording' exp_date_str filesep playback_dir_strs{b} filesep]; % directory where playback files are stored
                playback_files_TTL = loadPlayback(audioDir);
            end
            
            event_file_fname = [baseDir 'bat' batNums{cell_k} filesep 'neurologger_recording' exp_date_str filesep 'nlxformat\EVENTS.mat'];
            
            tt_base_dir = 'C:\Users\phyllo\Documents\Maimon\ephys\Data_processed\';
            spikeFname = fullfile(tt_base_dir,['bat' batNums{cell_k}],exp_date_str,[cellInfo{cell_k} '.ntt']);
            
            [nlg_TTL_durations,nlg_TTL_timestamps] = get_play_events(expType,event_file_fname,playback_files_TTL);
        case 'adult'
            exp_date_str = exp_date_str{1};
            expDate = datetime(exp_date_str,'InputFormat','yyyyMMdd');
            
            if ~any(T.Bat_1==str2double(batNums{cell_k}) & T.Date == expDate)
                playSpikes{cell_k} = [];
                playbackOrder{cell_k} = [];
                continue
            end
            
            playback_files_TTL = 1:400;
            event_file_fname = fullfile(baseDir,'event_file_data',[batNums{cell_k} '_' exp_date_str '_EVENTS.mat']);
            spikeFname = fullfile(baseDir,'spike_data',[batNums{cell_k} '_' cellInfo{cell_k} '.csv']);
            [nlg_TTL_durations,nlg_TTL_timestamps] = get_play_events(expType,event_file_fname,playback_files_TTL);
            
        case 'adult_social'
            exp_date_str = exp_date_str{1};
            expDate = datetime(exp_date_str,'InputFormat','yyyyMMdd');
            dateIdx = playbackResults.expDate == expDate;
            if ~any(dateIdx)
                continue
            end
            nlg_TTL_durations = playbackResults.ttlLength{dateIdx};
            nlg_TTL_timestamps = playbackResults.nlg_time{dateIdx};
            playback_files_TTL = unique(nlg_TTL_durations);
            spikeFname = fullfile(baseDir,'spike_data',[batNums{cell_k} '_' cellInfo{cell_k} '.csv']);
            playback_bat_nums{cell_k} = cellfun(@(ttl) bat_duration_map(ttl),num2cell(playback_files_TTL));
    end
    
    stabilityBounds = [cell_stability_info(cell_k).tsStart cell_stability_info(cell_k).tsEnd];
    
    if any(strcmp(expType,{'adult','adult_social'}))
        audio2nlg_fname = fullfile(baseDir,'call_data',[exp_date_str audio2nlg_str '.mat']);
        audio2nlg = load(audio2nlg_fname);
        nlg_TTL_timestamps = nlg_TTL_timestamps - audio2nlg.first_nlg_pulse_time;
    end
    
    [playSpikes{cell_k}, playbackOrder{cell_k}] = get_play_spikes(expType,spikeFname,stabilityBounds,offset,playback_files_TTL,nlg_TTL_durations,nlg_TTL_timestamps);
    
    if strcmp(expType,'adult_social')
        current_bat_nums = unique(playback_bat_nums{cell_k})';
        current_play_spikes = cell(1,length(current_bat_nums));
        k = 1;
        for bNum = current_bat_nums
            current_play_spikes{k} = [playSpikes{cell_k}{playback_bat_nums{cell_k} == bNum}];
            k = k + 1;
        end
        playSpikes{cell_k} = current_play_spikes;
        playback_bat_nums{cell_k} = current_bat_nums;
    end
end

sig = calculate_sig_playback(playSpikes);

end

function playback_files_TTL = loadPlayback(audioDir)

fsWav = 250e3;

avi_wav_bits = 16;
wav2bit_factor = 2^(avi_wav_bits-1);

playback_file_list=dir([audioDir 'playback*.wav']); % '.wav' here is not case-sensitive

playback_files_TTL=zeros(1,length(playback_file_list));

for file_i=1:length(playback_file_list)
    data = audioread([audioDir playback_file_list(file_i).name]);
    wav_TTL_samples = bitand(data*wav2bit_factor + wav2bit_factor,1);
    falling_samples=find(diff(wav_TTL_samples)==-1);
    if wav_TTL_samples(1)==0
        falling_samples=[0; falling_samples];
    end
    rising_samples=find(diff(wav_TTL_samples)==1);
    Ts=1e3*1/fsWav; % sampling period in ms
    playback_files_TTL(file_i)=round((rising_samples-falling_samples)*Ts); % round to whole ms
end

end