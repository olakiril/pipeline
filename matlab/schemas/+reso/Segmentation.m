%{
# Different mask segmentations.
-> reso.MotionCorrection
-> reso.SegmentationTask
---
segmentation_time=CURRENT_TIMESTAMP: timestamp              # automatic
%}


classdef Segmentation < dj.Computed

	methods(Access=protected)

		function makeTuples(self, key)
		%!!! compute missing fields for key here
% 			 self.insert(key)
		end
    end

    methods
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