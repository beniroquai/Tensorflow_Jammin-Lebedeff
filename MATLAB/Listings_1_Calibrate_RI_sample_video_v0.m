%% This file tries to recover the OPD of a sample with known reference
% It takes two cellphone images, where one is a known fiber-like object
% Authors: B. Diederich, B. Marsikova, B. Amos, R. Heintzmann
close all

%% Add some parameters here
is_dust_particle_remove = false; % do you want to remove dust particles in the ref. image?
is_regularization = false; % eventually regularize the input image (blur it)
is_raw = false; % is te file a RAW-dng? Experimental since each phone handles it a little different!
is_onesided = 1; % 0=no, -1=upper side, 1=lower side; tis parameter is useful if there is a gradient in the images visible
n_opdsteps = 100;
opdfact = 2; % multiple of lambdas which is coverred by the fiber
lambdaG = 562; % center wavelength
opdmax= opdfact * lambdaG
mygausskerneldim = 0;

% add the library
addpath('./src')

% determine the path for the images
imfolder = './data/VID1/'
f_ref_img = '2019-12-02_17.07.10/cropped000038.png';
f_sample_im = '2019-12-02_17.16.37/cropped000001.png'; % PS stands for DNG-> JPG using Potosop RAW converter

% load the imagefiles
if(is_raw)
    I_ref_raw = flip(uint16(dngRead([imfolder, f_ref_img_raw])));
    I_ref_raw = extracBayerChannel(I_ref_raw);
    I_ref_raw = dip_image(I_ref_raw)/2^8;
else
    I_ref_raw = dip_image(flip(imread([imfolder, f_ref_img])));
    I_ref_raw = JLpreprocessimage(I_ref_raw,mygausskerneldim);
end


%% extract the Ref.-ROI
I_ref = JLextractROI(I_ref_raw);
mysize=size(squeeze(I_ref(:,:,1)));

%% remove dust particles
if(is_dust_particle_remove)
    I_ref = JLremoveDust(I_ref, 0, 51);
end

%% fit the artificial fiber in the experimental dataset
[fiber_shape, theta, mask, mybackgroundval] = JLFitFibre(I_ref, is_onesided);

% Visualize the groundtruth and its measurement
cat(3, I_ref , fiber_shape)

%% Eventually regularize the input data
if(is_regularization)
    I_ref = JLregInputData(I_ref, 5)
end


%% mask image data and GT data
I_ref_masked = I_ref*mask;
fake_fiber= fiber_shape*mask;

cat(3, I_ref, fake_fiber);

%% visualize the sample to see if the OPD is roughly in the estimated range
obj=fake_fiber/max(fake_fiber);
showCol(I_ref)


%% create the LUT for RGB values and their corresponding OPD
[OPDaxis,R,G,B]=JLgetCalibration(obj,I_ref_masked,n_opdsteps,mybackgroundval);

R = R(0,0:end);
G = G(0,0:end);
B = B(0,0:end);
OPDaxis = OPDaxis(0:end);
%%
i_zeroorder = 1;
i_firstorder = 23;
% get values for 1st order of white
R1 = R(0,i_zeroorder:i_firstorder);
G1 = G(0,i_zeroorder:i_firstorder);
B1 = B(0,i_zeroorder:i_firstorder);
OPDaxis1 = OPDaxis(i_zeroorder:i_firstorder);
showCol(repmat(cat(3,R2,G2,B2), [100 1 1]))

% get values for 2nd order of white
R2 = R(0,i_firstorder+1:end);
G2 = G(0,i_firstorder+1:end);
B2 = B(0,i_firstorder+1:end);
OPDaxis2 = OPDaxis(i_firstorder+1:end);

OPDMap1 = JLfindOPD((I_ref_masked),R1,G1,B1,OPDaxis1)
OPDMap2 = JLfindOPD((I_ref_masked),R2,G2,B2,OPDaxis2)


cat(3, OPDMap1, OPDMap2)


% Save the RGB - OPD for Tensorflow
matsavepath = strcat(imfolder,'JL_tensorflow.mat');
R_mat = double(R); G_mat = double(G); B_mat = double(B);
OPD_mat = double(OPDaxis); I_ref_mat = double(I_ref_masked);
OPDMap_mat = double(OPDMap); mask_mat = double(mask);
OPDBackgroundval_mat = double(mybackgroundval);
save(matsavepath, 'R_mat', 'G_mat', 'B_mat', 'OPD_mat', 'I_ref_mat', 'OPDMap_mat', 'mask_mat', 'opdmax', 'OPDBackgroundval_mat', '-v7.3')
%%
figure()
subplot(121)
plot(OPD_mat,R_mat), hold on
plot(OPD_mat,G), plot(OPD_mat,B)
legend('r','g','b')
hold off
subplot(122)
plot3(R_mat, G_mat, B_mat)
xlabel('R')
ylabel('G')
zlabel('B')

figure()
plot(OPDaxis1,R1), hold on
plot(OPDaxis1,G1), plot(OPDaxis1,B1)
plot(OPDaxis2,R2), plot(OPDaxis2,G2), plot(OPDaxis2,B2)
legend('r','g','b')
hold off

%% s-------------------------------------------------------------------------
% REAL DATA Follows here!
%--------------------------------------------------------------------------

% try to apply colormap on specific file
%f_sample_im = 'IMG_20191202_171935_PS2.jpg'


I_smpl = dip_image(flip(imread([imfolder, f_sample_im])));

[I_smpl, ROISize, ROICentre] = JLextractROI(I_smpl);

I_smpl = JLpreprocessimage(I_smpl,mygausskerneldim);


if(0)
%JLnormbackground(I_smpl,R,G,B,OPDaxis);

fh=dipshow(showCol(I_smpl)); % find edges of CC signal
diptruesize(fh, 200);
fprintf('Thank you :-)')
% select the Backgroundvalue 
fprintf('Please select a sample-free background region (i.e. black/dark)')
BackgroundPosition = dipgetcoords(fh,1);
mybackgroundval = mean(extract(I_smpl, [20,20,3], BackgroundPosition),[],[1,2]);


I_smpl(:,:,0) = I_smpl(:,:,0) - mybackgroundval(0) + R(0);
I_smpl(:,:,1) = I_smpl(:,:,1) - mybackgroundval(1) + G(0);
I_smpl(:,:,2) = I_smpl(:,:,2) - mybackgroundval(2) + B(0);
end

%%
%I_smpl = I_smpl_old;
%I_smpl(:,:,0) = I_smpl_old(:,:,0) + .0;
%I_smpl(:,:,1) = I_smpl_old(:,:,1) + .0;
%I_smpl(:,:,2) = I_smpl_old(:,:,2) + .0;

OPDMap1 = JLfindOPD((I_smpl),R1,G1,B1,OPDaxis1);
OPDMap2 = JLfindOPD((I_smpl),R2,G2,R2,OPDaxis2);
cat(3,OPDMap1,OPDMap2)




OPDMap_ob = JLfindOPD(I_smpl,R,G,B,OPDaxis);

% display the result
figure
title(f_sample_im)
subplot(121), imagesc(double(I_smpl)), axis image, colorbar, title 'RGB Intensity Measurement'
subplot(122), imagesc(double(OPDMap_ob)), axis image, colorbar, colormap gray,  title 'Reconstructed OPD AU'




