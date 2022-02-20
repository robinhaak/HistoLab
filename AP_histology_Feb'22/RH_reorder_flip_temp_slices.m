function RH_reorder_flip_temp_slices(im_path)

slice_dir = dir([im_path filesep '*.tif']);
slice_fn = natsortfiles(cellfun(@(path,fn) [path filesep fn], ...
    {slice_dir.folder},{slice_dir.name},'uni',false));

slice_im = cell(length(slice_fn),1);
for i = 1:length(slice_fn)
   slice_im{i} = imread(slice_fn{i});  
end

% load new order/flip info
load(fullfile(im_path, 'reorderedflipped_histology.mat'));

% save
for i = 1:length(slice_fn)
   curr_im = slice_im{i};
   if gui_data.flipped_lr(i) == 1
       curr_im = fliplr(curr_im);
   end
   if gui_data.flipped_ud(i) == 1
       curr_im = flipud(curr_im);
   end
   curr_im_fn = [im_path filesep num2str(gui_data.slice_order(i)) '.tif'];
   imwrite(curr_im, curr_im_fn);
end
% see if they laod correctly
slice_dir = dir([im_path filesep '*.tif']);
slice_fn = natsortfiles(cellfun(@(path,fn) [path filesep fn], ...
    {slice_dir.folder},{slice_dir.name},'uni',false));

slice_im = cell(length(slice_fn),1);
for curr_slice = 1:length(slice_fn)
    slice_im{curr_slice} = imread(slice_fn{curr_slice});
end

montage(slice_im(1:length(slice_fn),:));
       
end



