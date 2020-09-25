function sig = calculate_sig_playback(playSpikes)
bins = linspace(-2,2,51);
binCenters = round(movmean(bins,2));
binCenters = binCenters(2:end);
dT = mean(diff(binCenters));
plotFlag = false;
minSpikes = 5;
sig = nan(length(playSpikes),max(cellfun(@length,playSpikes)));
for c = 1:length(playSpikes)
    if ~isempty(playSpikes{c})
        if plotFlag
            cla
            hold on
        end
        for p = 1:length(playSpikes{c})
            allSpikes = [playSpikes{c}{p}{:}];
            if sum(allSpikes <0 & allSpikes>=-1) > minSpikes && sum(allSpikes <1 & allSpikes>=0) > minSpikes
                baseFR = sum(allSpikes <0 & allSpikes>=-1)/length(playSpikes{c}{p});
                postFR = sum(allSpikes <1 & allSpikes>=0)/length(playSpikes{c}{p});
                sig(c,p) = postFR< poissinv(0.05,baseFR) || postFR>poissinv(0.95,baseFR);
                if plotFlag
                    N = histcounts(allSpikes,bins)./dT;
                    plot(smoothdata(N,'gaussian',10));
                end
            end
        end
        if plotFlag
            input('?')
        end
    end
end
end