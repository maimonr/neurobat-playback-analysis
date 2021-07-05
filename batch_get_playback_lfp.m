function batch_get_playback_lfp(eData)

overwrite_playback_flag = false;
lfp_playback_offset = 3;
t = tic;

switch eData.expType
    
    case 'adult'
        
        T = readtable('Y:\users\maimon\adult_recording\documents\recording_logs.csv');
        idx = strcmp(T.Session,'playback');
        T = T(idx & T.usable,:);
        
        exp_dirs = dir(fullfile(eData.serverPath,'*20*'));
        
        lfp_data_dir = 'E:\ephys\adult_recording\lfp_data\';
        event_file_dir = 'E:\ephys\adult_recording\event_file_data\';
        call_dir = 'E:\ephys\adult_recording\call_data\';
        audio2nlg_str = 'audio2nlg_fit.mat';
        
    case 'adult_social'
        recLogs = readtable(fullfile(eData.serverPath,'documents','recording_logs.csv'));
        s = load(fullfile(eData.serverPath,'playback_data','playback_times_and_ttls.mat'));
        playbackResults = s.playbackResults;
        k = 1;
        sessStr = cell(1,size(playbackResults,1));
        for expDate = playbackResults.expDate'
            idx = find(recLogs.Date == expDate,1,'first');
            sessStr{k} = recLogs.Session{idx};
            k = k + 1;
        end
        assert(length(unique(sessStr)) == 1)
        audio2nlg_str = 'audio2nlg_fit_social';
        exp_dirs = dir(fullfile(eData.serverPath,'*20*'));
        lfp_data_dir = fullfile(eData.serverPath,'lfp_data');
        call_dir = fullfile(eData.serverPath,'call_data');
        
end

all_lfp_dirs = cell(1,length(exp_dirs));
for k = 1:length(exp_dirs)
    all_lfp_dirs{k} = dir(fullfile(exp_dirs(k).folder,exp_dirs(k).name,'lfpformat','*LFP.mat'));
end
all_lfp_dirs = vertcat(all_lfp_dirs{:});
lastProgress = 0;
for k = 1:length(all_lfp_dirs)
    
    exp_day_str = regexp(all_lfp_dirs(k).name,'\d{8}','match');
    exp_day_str = exp_day_str{1};
    
    switch eData.expType
        case 'adult'
            date_idx = T.Date == datetime(exp_day_str,'InputFormat','yyyyMMdd');
            
            batNum = regexp(all_lfp_dirs(k).name,'\d{5}','match');
            batNum = batNum{1};
            
            if isempty(date_idx) || ~(strcmp(num2str(T.Bat_1(date_idx)),batNum) || strcmp(num2str(T.Bat_2(date_idx)),batNum))
                continue
            elseif strcmp(num2str(T.Bat_2(date_idx)),batNum)
                event_file_fname = fullfile(event_file_dir,[num2str(T.Bat_1(date_idx)) '_' exp_day_str '_EVENTS.mat']);
            else
                event_file_fname = fullfile(event_file_dir,[batNum '_' exp_day_str '_EVENTS.mat']);
            end
            playback_files_TTL = 1:400;
            
            [nlg_TTL_durations,nlg_TTL_timestamps] = get_play_events(expType,event_file_fname,playback_files_TTL);
            
        case 'adult_social'
            expDate = datetime(exp_day_str,'InputFormat','yyyyMMdd');
            dateIdx = playbackResults.expDate == expDate;
            if ~any(dateIdx)
                continue
            end
            nlg_TTL_durations = playbackResults.ttlLength{dateIdx};
            nlg_TTL_timestamps = playbackResults.nlg_time{dateIdx};
            
    end
    audio2nlg_fname = fullfile(call_dir,[exp_day_str '_' audio2nlg_str]);
    
    playback_lfp_fname = strrep(all_lfp_dirs(k).name,'.mat','');
    playback_lfp_fname = [playback_lfp_fname '_playback.mat']; %#ok<AGROW>
    playback_lfp_fname = fullfile(lfp_data_dir,playback_lfp_fname);
    
    if exist(playback_lfp_fname,'file') && ~overwrite_playback_flag
        disp('call trig lfp file already exists, continuing')
        continue
    end
    
    lfp_fname = fullfile(all_lfp_dirs(k).folder,all_lfp_dirs(k).name);
    lfpData = matfile(lfp_fname);
    
    get_playback_lfp(eData.expType,lfp_playback_offset,nlg_TTL_durations,nlg_TTL_timestamps,audio2nlg_fname,playback_lfp_fname,lfpData)
    
    progress = 100*(k/length(all_lfp_dirs));
    elapsed_time = round(toc(t));
    if mod(progress,10) < mod(lastProgress,10)
        fprintf('%d %% of directories  processed, %d s elapsed\n',round(progress),elapsed_time);
    end
    lastProgress = progress;
    
end



end