%{
# masks created manually
-> reso.Segmentation
---
%}


classdef SegmentationManual < dj.Computed
    
    properties
        popRel  = reso.SummaryImagesAverage
    end
    
    methods(Access=protected)
        function makeTuples(self, key)
            images = ne7.mat.normalize(fetch1(reso.SummaryImagesAverage & key, 'average_image'));
            
            % add second channel info
            key2 = key;
            channels = [1 2];
            key2.channel = channels(key.channel~=channels);
            if exists(reso.SummaryImagesAverage & key2);
               images = repmat(images,1,1,3);
               image2 = ne7.mat.normalize(fetch1(reso.SummaryImagesAverage & key2, 'average_image'));
               images(:,:,:,2) = repmat(image2,1,1,3);
               images(:,:,channels(key.channel~=channels),3) = images(:,:,1,1);
               images(:,:,channels(key.channel==channels),3) = image2;
            end
            
            % remove baseline
            masks = ne7.ui.paintMasks(images);
            assert(~isempty(masks), 'user aborted segmentation')
            key.segmentation_method = 1;
            r_key = rmfield(key,'pipe_version');
            r_key.compartment = 'unknown';
            
            % insert parents
            insert(reso.SegmentationTask,r_key);
            insert(reso.Segmentation,key);
            self.insert(key)
            
            % Insert Masks
            unique_masks = unique(masks);
            key.mask_id = 0;
            for mask = unique_masks(unique_masks>0)'
                key.mask_id = key.mask_id+1;
                key.pixels = find(masks==mask);
                key.weights = ones(size(key.pixels));
                insert(reso.SegmentationMask,key)
            end
        end 
    end
    
    methods
        function populateAll(self,keys)
            keys = fetch(experiment.Scan - (reso.Segmentation & keys) & keys);
            for key = keys'
                channels = unique(fetchn(reso.SummaryImagesAverage & key,'channel'));
                key.channel = channels(1);
                populate(self,key)
                
                if length(channels)>1
                    % insert parents
                    tuple = fetch(reso.SegmentationTask & key,'*');
                    tuple.channel = channels(2);
                    insert(reso.SegmentationTask,tuple);

                    tuple = fetch(reso.Segmentation & key,'*');
                    tuple.channel = channels(2);
                    insert(reso.Segmentation,tuple);

                    tuple = fetch(self & key,'*');
                    tuple.channel = channels(2);
                    self.insert(tuple)

                    % Insert Masks
                    keys = fetch(reso.SegmentationMask & key,'*');
                    for tuple = keys'
                        tuple.channel = channels(2);
                        insert(reso.SegmentationMask,tuple)
                    end
                end
            end
        end
        
        function plot(self)
            
            keys = fetch(self);
            for k = keys'
                figure

                [masks ,tkeys]= fetchn(reso.SegmentationMask & k,'pixels');
                images = fetchn(reso.SummaryImagesAverage & k, 'average_image', 'ORDER BY channel');
                mask = zeros(size(images{1}));
                for imask = 1:length(masks)
                    mask(masks{imask}) = tkeys(imask).mask_id;
                end
                [w,mw] = fetch1(reso.ScanInfo & k,'px_width','um_width');   

                % plot masks
                un = unique(mask(:));
                nmask = zeros(size(mask));
                for i = 1:length(un)
                    nmask(mask==un(i)) = i;
                end

                colors = [0 0 0;[linspace(0,1,length(masks))' ones(length(masks),1)*0.8 ones(length(masks),1)*0.8]];
                im = images{1};
                ul = prctile(im(:),99);
                im(im>ul) = ul;

                map = zeros(size(im,1),size(im,2),3);
                map(:,:,1) = reshape(colors(nmask,1),size(map(:,:,1)));
                map(:,:,2) = 0.5*(mask>0);
                map(:,:,3) = normalize(im);

                image(hsv2rgb(map))
                axis image
                axis off
                hold on
                plot(size(map,2)*0.1+[0 w/mw*50],size(map,1)*0.9*[1 1],'-w','LineWidth',2)
                text(mean(size(map,2)*0.1+[0 w/mw*50]),size(map,1)*0.9,'50um','Color',[1 1 1],'FontSize',12,'VerticalAlignment','top')
                shg
                set(gcf,'name',sprintf('Masks %d %d %d',k.animal_id,k.session,k.scan_idx))
            end
        end
    end
end

