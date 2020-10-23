function [acc, bootAcc] = predict_playback_fr(cellSpikes)
[acc, bootAcc] = deal(NaN);

if ~iscell(cellSpikes)
    return
end

call_time_win = [0;1];
winSize = diff(call_time_win);
mdlType = 'glm_fit_log';
nCV = 5;
n_boot_rep = 1e3;

Y = cellfun(@(n,x) n*ones(size(x,2),1),num2cell(0:1),cellSpikes,'un',0);
Y = vertcat(Y{:});
bootAcc = nan(1,n_boot_rep);

X = cellfun(@(fr) cellfun(@(trialSpikes) sum(trialSpikes>call_time_win(1) & trialSpikes<call_time_win(2))/winSize,fr),cellSpikes,'un',0);
X = [X{:}]';
acc = mean(get_cv_id_acc(X,Y,nCV));
parfor boot_k = 1:n_boot_rep
    label_perm_idx = randperm(length(Y));
    Y_perm = Y(label_perm_idx);
    cvAcc = get_cv_id_acc(X,Y_perm,nCV,'mdlType',mdlType);
    bootAcc(boot_k) = mean(cvAcc);
end

end