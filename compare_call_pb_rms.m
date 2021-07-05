function [rmsCall,rmsPB] = compare_call_pb_rms
baseDir = 'Z:\users\Maimon\adult_social_recording';
call_data_dir = fullfile(baseDir,'call_data');
expDates = datetime(2020,7,28):datetime(2020,8,14);
rmsThresh = 0.75e-4;
minLength = 0.5;
[rmsCall,rmsPB] = deal(cell(1,length(expDates)));
for exp_k = 1:length(expDates)
    exp_date_str = datestr(expDates(exp_k),'mmddyyyy');
    pbDir = fullfile(baseDir,exp_date_str,'audio','playback','ch1');
    exp_date_str = datestr(expDates(exp_k),'yyyymmdd');
    call_data_fname = fullfile(call_data_dir,[exp_date_str '_cut_call_data.mat']);
    if isfolder(pbDir) && isfile(call_data_fname)
        fNames = dir(fullfile(pbDir,'*.wav'));
        rmsPB{exp_k} = nan(1,length(fNames));
        if nargin == 2
            for f_k = 1:length(fNames)
                [data,fs] = audioread(fullfile(fNames(f_k).folder,fNames(f_k).name));
                r = sqrt(movmean(data.^2,1e3));
                rmsIdx = r > rmsThresh;
                if sum(rmsIdx)/fs > minLength
                    rmsPB{exp_k}(f_k) = sqrt(mean(data(rmsIdx).^2));
                end
            end
        end
        s = load(call_data_fname,'cut_call_data');
        f_nums = cellfun(@min,{s.cut_call_data.f_num});
        idx = findgroups(f_nums);
%         rmsCall{exp_k} = splitapply(@(x) sqrt(mean(vertcat(x{:}).^2)),{s.cut_call_data.cut},idx);
        rmsCall{exp_k} = arrayfun(@(x) sqrt(mean(x.cut.^2)),s.cut_call_data);
    end
end