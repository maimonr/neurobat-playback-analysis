function [sigIndv,sigAll] = calculate_sig_playback(playSpikes)
bins = linspace(-2,2,51);
binCenters = round(movmean(bins,2));
binCenters = binCenters(2:end);
dT = mean(diff(binCenters));
plotFlag = false;
minSpikes = 5;
if isa(playSpikes,'containers.Map')
    playSpikes = playSpikes.values;
    playSpikes = cellfun(@(x) x.values,playSpikes,'un',0);
end
sigIndv = nan(length(playSpikes),max(cellfun(@length,playSpikes)));
sigAll = nan(length(playSpikes),1);
for c = 1:length(playSpikes)
    if ~isempty(playSpikes{c})
        if plotFlag
            cla
            hold on
        end
        
        allSpikes = [playSpikes{c}{:}];
        nRep = length(allSpikes);
        allSpikes = [allSpikes{:}];
        sigAll(c) = checkResp(allSpikes,nRep);
        
        for p = 1:length(playSpikes{c})
            allSpikes = [playSpikes{c}{p}{:}];
            nRep = length(allSpikes);
            if sum(allSpikes <0 & allSpikes>=-1) > minSpikes && sum(allSpikes <1 & allSpikes>=0) > minSpikes
                sigIndv(c,p) = checkResp(allSpikes,nRep);
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

function sig = checkResp(allSpikes,nRep)
baseFR = sum(allSpikes <0 & allSpikes>=-1)/nRep;
postFR = sum(allSpikes <1 & allSpikes>=0)/nRep;
sig = postFR< poissinv(0.05,baseFR) || postFR>poissinv(0.95,baseFR);
end