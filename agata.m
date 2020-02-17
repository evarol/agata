%% AGATA.m


clear
clc
close all

addpath(genpath('./'));
warning('off');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%USER PARAMETERS%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

erosion_radius = 1;
erosion_number = 8;
grid_size=25;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


[file,path]=uigetfile('Select images to analyze','MultiSelect','on','s','*`');


if ~iscell(file)
    tmp=file;
    clear file
    file{1}=tmp;
end

for i=1:length(file)
    close all
    I=imread([path file{i}]);
    scale=input('Enter scale (px/um): ');
    
    BW = rgb2gray(I);
    BW_erode=imerode(BW,strel('disk',erosion_radius,erosion_number));
    
    crop_true=input('Do you want to crop the image?[y/n]','s');
    if strcmpi(crop_true,'y');
        exclusion_done='n';
        while strcmpi(exclusion_done,'n')
            figure(1)
            imshow(BW_erode)
            title('Please draw rectangle to crop')
            rect=getrect;
            
            im_candidate = BW_erode(rect(2):rect(2)+rect(4),rect(1):rect(1)+rect(3));
            imshow(im_candidate);
            exclusion_done=input('Are you finished excluding areas?[y/n]','s');
        end
        BW_erode_crop=im_candidate;
    end
    
    BW_erode_crop_grid=BW_erode_crop;
    [rows, columns] = size(BW_erode_crop);
    for row = 1 : grid_size : rows %can make it even with linspace
        BW_erode_crop_grid(row, :) = max(BW_erode_crop_grid(:));
    end
    for col = 1 : grid_size : columns
        BW_erode_crop_grid(:, col) = max(BW_erode_crop_grid(:));
    end
    imshow(BW_erode_crop_grid);
    selection_done='n';
    while strcmpi(selection_done,'n')
        figure(1)
        imshow(BW_erode_crop_grid)
        title('Please click on aggregates (double click final point to finish)')
        [x,y]=getpts;
        selection_done=input('Are you finished clicking on aggregates?[y/n]','s');
    end
    pts=[x y];
    pts(end,:)=[];
    imshow(BW_erode_crop_grid)
    hold on
    plot(pts(:,1),pts(:,2),'ro','MarkerSize',20);
    
    
    %% COMPUTE STATS
    
    image_area = (size(BW_erode_crop_grid,1)/scale)*(size(BW_erode_crop_grid,2)/scale);
    number_of_aggregates = size(pts,1);
    grid_size_um = grid_size/scale;
    number_of_aggregates_per_area = number_of_aggregates/ (image_area/(grid_size_um^2));
    %% WRITE TO EXCEL FILE
    try
        existing_data=table2cell(readtable('agata.xls'));
    end
    
    headers=[{'Image'},{'Image area (um^2)'},{'Number of aggregates'},{'Number counted per area (#/grid)'}];
    data=[file{i},num2cell(image_area),num2cell(number_of_aggregates),num2cell(number_of_aggregates_per_area)];
    
    try
        T=table([headers;existing_data;data]);
    catch
        T=table([headers;data]);
    end
    writetable(T,'agata.xls','WriteVariableNames',false);
    
    %% SAVING IMAGES
    close all
    figure(1)
    imshow(I)
    export_fig([path file{i} '_original.png']);
    figure(2)
    imshow(BW_erode_crop)
    export_fig([path file{i} '_BW_crop.png']);
    figure(3)
    imshow(BW_erode_crop_grid)
    hold on
    plot(pts(:,1),pts(:,2),'ro','MarkerSize',20);
    export_fig([path file{i} '_aggregates.png']);
end

