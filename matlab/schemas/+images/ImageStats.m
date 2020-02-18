%{
# Image statistics
-> stimulus.StaticImageImage
---
channel_mean             : tinyblob      # frame mean
channel_std              : tinyblob      # frame standard deviation
channel_kurtosis         : tinyblob      # frame kurtosis
frame_mean_diff          : double        # difference in mean between channels
frame_corr               : double        # channel correlation
frame_std_diff           : double        # difference in std between channels
%}

classdef ImageStats < dj.Imported
    methods(Access=protected)
        function makeTuples(obj,key) 
            im = fetch1(stimulus.StaticImageImage & key,'image');
            im = single(im);
            
            for ichan = 1:size(im,3)
                key.channel_mean(ichan) = mean(reshape(im(:,:,ichan),[],1));
                key.channel_std(ichan)  = std(reshape(im(:,:,ichan),[],1));
                key.channel_kurtosis(ichan)  = kurtosis(reshape(im(:,:,ichan),[],1));
            end
            
            cmb = combnk(1:size(im,3),2);
            for icmb = 1:size(cmb,1)
                md(icmb) =  key.channel_mean(cmb(icmb,1)) - key.channel_mean(cmb(icmb,2));
                sd(icmb) =  key.channel_mean(cmb(icmb,1)) - key.channel_mean(cmb(icmb,2));
                cr(icmb) =  mean(corr(reshape(im(:,:,cmb(icmb,1)),[],1),reshape(im(:,:,cmb(icmb,2)),[],1)));
            end
            
            key.frame_mean_diff = mean(md);
            key.frame_std_diff = mean(sd);
            key.frame_corr = mean(cr);

            insert( obj, key );
        end
    end
    
end