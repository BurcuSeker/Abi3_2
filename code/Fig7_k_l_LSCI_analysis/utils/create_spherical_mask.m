function imgMask = create_spherical_mask(diameter, radius)
% function imgMask = create_spherical_mask(diameter)
%
% Function creates mask image with equal edge length (diameter) and spherical
% ROI, devided in 4 quadrants
%
% NOTE: diameter should be even numbered!
%
%%
if ~exist('radius', 'var')
    radius = diameter(1)/2 + 0.5;
    centroid = radius;
else
    centroid = diameter(1)/2 + 0.5;
end

%%
imgMask = zeros(diameter, diameter);

%%
if mod(diameter, 2)== 1
    
    %--- create mask for skull ROI with 4 quadrants
    warning('for odd numberd diameters, binary spherical mask will be created without quadrands')
    for i=1:diameter
        for j=1:diameter
            dist = sum(([i j]-centroid).^2)^.5;
            if dist <= radius
                imgMask(i,j) = 1;
            end
        end
    end
    
else
    
    %--- create mask for skull ROI with 4 quadrants
    for i=1:diameter
        for j=1:diameter
            dist = sum(([i j]-centroid).^2)^.5;
            if dist <= radius
                if i<centroid && j<centroid
                    imgMask(i,j) = 1;
                elseif i>centroid && j<centroid
                    imgMask(i,j) = 2;
                elseif i>centroid && j>centroid
                    imgMask(i,j) = 3;
                elseif i<centroid && j>centroid
                    imgMask(i,j) = 4;
                end
            end
        end
    end

end