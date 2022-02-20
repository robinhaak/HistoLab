function RH_reorder_flip_histology_gui(im_path)
% RH_reorder_flip_histology, based on: AP_rotate_histology(im_path)
%
% Robin Haak, Feb '22

slice_dir = dir([im_path filesep '*.tif']);
slice_fn = natsortfiles(cellfun(@(path,fn) [path filesep fn], ...
    {slice_dir.folder},{slice_dir.name},'uni',false));

slice_im = cell(length(slice_fn),1);
for curr_slice = 1:length(slice_fn)
    slice_im{curr_slice} = imread(slice_fn{curr_slice});
end

% Pad all slices centrally to the largest slice and make matrix
slice_size_max = max(cell2mat(cellfun(@size,slice_im,'uni',false)),[],1);
slice_im_pad = ...
    cell2mat(cellfun(@(x) x(1:slice_size_max(1),1:slice_size_max(2),:), ...
    reshape(cellfun(@(im) padarray(im, ...
    [ceil((slice_size_max(1) - size(im,1))./2), ...
    ceil((slice_size_max(2) - size(im,2))./2)],0,'both'), ...
    slice_im,'uni',false),1,1,1,[]),'uni',false));

% Pull up slice viewer to scroll through slices with option to flip

% Create figure, set button functions
gui_fig = figure('KeyPressFcn',@keypress);
gui_data.curr_slice = 1;
gui_data.im_aligned = slice_im_pad;
gui_data.slice_fn = slice_fn;
gui_data.slice_order = 1:length(slice_fn);
gui_data.flipped_lr = zeros(1, length(slice_fn));
gui_data.flipped_ud = zeros(1, length(slice_fn));
gui_data.im_path = im_path;


% Set up axis for histology image
gui_data.histology_ax = axes('YDir','reverse');
hold on; colormap(gray); axis image off;
gui_data.histology_im_h = image(gui_data.im_aligned(:,:,:,1), ...
    'Parent',gui_data.histology_ax);

% Create title to write area in
gui_data.histology_ax_title = title(gui_data.histology_ax, ...
    '1/2: change slice, Shift 1/2: re-order slice, Arrows: flip, Esc: save & quit','FontSize',14);

% Upload gui data
guidata(gui_fig,gui_data);
end


function keypress(gui_fig,eventdata)

shift_on = any(strcmp(eventdata.Modifier,'shift'));

% Get guidata
gui_data = guidata(gui_fig);

switch eventdata.Key
    
    % 1/2: switch slice
    % Shift + 1/2: move slice in stack
    
    case '1'
        if ~shift_on
            gui_data.curr_slice = max(gui_data.curr_slice - 1,1);
            set(gui_data.histology_im_h,'CData',gui_data.im_aligned(:,:,:,gui_data.curr_slice))
            guidata(gui_fig,gui_data);
        elseif shift_on && gui_data.curr_slice ~= 1
            slice_flip = [gui_data.curr_slice-1,gui_data.curr_slice];
            gui_data.im_aligned(:,:,:,slice_flip) = flip(gui_data.im_aligned(:,:,:,slice_flip),4);
            gui_data.slice_order(slice_flip) = flip(gui_data.slice_order(slice_flip));
            gui_data.flipped_lr(slice_flip) = flip(gui_data.flipped_lr(slice_flip));
            gui_data.flipped_ud(slice_flip) = flip(gui_data.flipped_ud(slice_flip));
            gui_data.curr_slice = slice_flip(1);
            guidata(gui_fig,gui_data);
        end
        
    case '2'
        if ~shift_on
            gui_data.curr_slice = ...
                min(gui_data.curr_slice + 1,size(gui_data.im_aligned,4));
            set(gui_data.histology_im_h,'CData',gui_data.im_aligned(:,:,:,gui_data.curr_slice))
            guidata(gui_fig,gui_data);
        elseif shift_on && gui_data.curr_slice ~= size(gui_data.im_aligned,4)
            slice_flip = [gui_data.curr_slice,gui_data.curr_slice+1];
            gui_data.im_aligned(:,:,:,slice_flip) = flip(gui_data.im_aligned(:,:,:,slice_flip),4);
            gui_data.slice_order(slice_flip) = flip(gui_data.slice_order(slice_flip));
            gui_data.flipped_lr(slice_flip) = flip(gui_data.flipped_lr(slice_flip));
            gui_data.flipped_ud(slice_flip) = flip(gui_data.flipped_ud(slice_flip));
            gui_data.curr_slice = slice_flip(2);
            guidata(gui_fig,gui_data);
        end
        
        % Arrow keys: flip slice
    case {'leftarrow','rightarrow'}
        gui_data.im_aligned(:,:,:,gui_data.curr_slice) = ...
            fliplr(gui_data.im_aligned(:,:,:,gui_data.curr_slice));
        if gui_data.flipped_lr(gui_data.curr_slice) == 0
            gui_data.flipped_lr(gui_data.curr_slice) = 1;
        elseif gui_data.flipped_lr(gui_data.curr_slice) == 1
            gui_data.flipped_lr(gui_data.curr_slice) = 0;
        end
        set(gui_data.histology_im_h,'CData',gui_data.im_aligned(:,:,:,gui_data.curr_slice))
        guidata(gui_fig,gui_data);
        
    case {'uparrow','downarrow'}
        gui_data.im_aligned(:,:,:,gui_data.curr_slice) = ...
            flipud(gui_data.im_aligned(:,:,:,gui_data.curr_slice));
        if gui_data.flipped_ud(gui_data.curr_slice) == 0
            gui_data.flipped_ud(gui_data.curr_slice) = 1;
        elseif gui_data.flipped_ud(gui_data.curr_slice) == 1
            gui_data.flipped_ud(gui_data.curr_slice) = 0;
        end
        set(gui_data.histology_im_h,'CData',gui_data.im_aligned(:,:,:,gui_data.curr_slice))
        guidata(gui_fig,gui_data);
        
        % Escape: save and close
    case 'escape'
        opts.Default = 'Yes';
        opts.Interpreter = 'tex';
        user_confirm = questdlg('\fontsize{15} Save and quit?','Confirm exit',opts);
        if strcmp(user_confirm,'Yes')
            %save
            save_fn = [gui_data.im_path filesep 'reorderedflipped_histology.mat'];
            out.slice_order = gui_data.slice_order;
            out.flipped_lr = gui_data.flipped_lr;
            out.flipped_ud = gui_data.flipped_ud;
            gui_data = out;
            save(save_fn, 'gui_data');
            
            close(gui_fig)
        end
end

end




