

function imgOut = sc_cropTopography(img)
    
    %%% Function iused to crop and trim Topoplots that it will express ONLY scalp and
    %%% the topolots. Necessery for model training and inference 
    %%%
    %%% ~ MD 

    % Convert to grayscale
    gray = rgb2gray(img);

    % Threshold for non-white pixels
    mask = gray < 245;   % adjust if needed

    % If the mask is empty, return as is
    if ~any(mask(:))
        imgOut = img;
        return;
    end

    % Bounding box of the non-white region
    props = regionprops(mask, 'BoundingBox');
    bbox = round(props(1).BoundingBox);

    % Crop image
    cropped = imcrop(img, bbox);

    % Make it square by padding
    h = size(cropped,1);
    w = size(cropped,2);
    dim = max(h,w);

    padTop = floor((dim-h)/2);
    padBottom = dim - h - padTop;

    padLeft = floor((dim-w)/2);
    padRight = dim - w - padLeft;

    imgOut = padarray(cropped,[padTop padLeft],255,'pre');
    imgOut = padarray(imgOut,[padBottom padRight],255,'post');

end


