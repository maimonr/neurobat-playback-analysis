function [acc,bootAcc,p] = calculate_playback_id_prediction(bat_id_pred_vocal,play_spikes_map)
p_vocal = rowfun(@(x,y) 1 - sum(x>y)/length(y),bat_id_pred_vocal,'InputVariables',{'acc','bootAcc'});
p_vocal = p_vocal.Var1;
idx = find(p_vocal<0.05)';
k = 1;
p = nan(1,length(idx));
for cell_k = idx
    bat_cell_key = strjoin({bat_id_pred_vocal.batNum{cell_k},bat_id_pred_vocal.cellInfo{cell_k}},'-');
    target_bat_num = str2double(bat_id_pred_vocal.targetBNum{cell_k});
    
    if isKey(play_spikes_map,bat_cell_key) && isKey(play_spikes_map(bat_cell_key),target_bat_num)
        cell_play_spikes = play_spikes_map(bat_cell_key);
        cellFR = cell(1,2);
        cellFR{1} = cell_play_spikes(target_bat_num);
        target_bat_keys = setdiff(cell2mat(cell_play_spikes.keys),target_bat_num);
        for batNum = target_bat_keys
            cellFR{2} = [cellFR{2} cell_play_spikes(batNum)];
        end
        [acc, bootAcc] = predict_playback_fr(cellFR);
        p(k) = min(1 - (sum(acc>bootAcc')/1e3));
    end
    k = k + 1;
end

end