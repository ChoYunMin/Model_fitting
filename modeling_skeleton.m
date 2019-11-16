% CSE597C Gabor filter
% Seungkyu Lee
function o = otest

clear all;
dct_driven=1;

firstim = imread('person.bmp');
%firstim = imread('md2.jpg');
firstimage=double(rgb2gray(firstim));
[imy,imx]=size(firstimage);
opt=zeros(imy,imx);

% skeleton 불러오기
skeleton = imread('person_skeleton.jpg');
skeletonimage = double(skeleton);
%skeletonimage = skeletonimage ./ 255;

% subplot(2,3,1); imagesc(firstimage);colormap('gray');drawnow; %이미지 그리기
% wpath  = sprintf('tmp_img');
% im0=firstimage;
% save(wpath,'im0');

%점수 매기기 - 주변 8개 픽셀의 평균(값이 0이라면)
for col=2:imy-1
    for row=round(imx/2):imx-1
        if skeletonimage(col, row)==0
            sum_skeletonimage=skeletonimage(col-1,row-1)+skeletonimage(col,row-1)+skeletonimage(col+1,row-1)+skeletonimage(col-1,row)+skeletonimage(col+1,row)+skeletonimage(col-1,row+1)+skeletonimage(col,row+1)+skeletonimage(col+1,row+1);
            skeletonimage(col,row)=sum_skeletonimage/8;
        end
    end
    
    for row=round(imx/2):-1:2
        if skeletonimage(col,row)==0
            sum_skeletonimage=skeletonimage(col-1,row-1)+skeletonimage(col,row-1)+skeletonimage(col+1,row-1)+skeletonimage(col-1,row)+skeletonimage(col+1,row)+skeletonimage(col-1,row+1)+skeletonimage(col,row+1)+skeletonimage(col+1,row+1);
            skeletonimage(col,row)=sum_skeletonimage/8;
        end
    end
end

subplot(2,3,1); imagesc(skeletonimage);colormap('gray');drawnow; %이미지 그리기
wpath  = sprintf('tmp_img');
im0=skeletonimage;
save(wpath,'im0');
skeletonimage=(skeletonimage-128)/128;

%관절 탐색 - 윤민 마음대로~
for joint=1:11
   if joint==1
       x0 = [0 -30 pi/2 0.1  3  3];
       ub = [5 -25 2*pi 1    12  12];
       lb = [-5 -35 -2*pi 0   2  2];
   elseif joint==2
       x0 = [-30 -10 pi/2 0.5  6  6];
       ub = [-25 -5 2*pi 1    12  12];
       lb = [-35 -15 -2*pi 0   2  2];
   elseif joint==3
       x0 = [-15 -10 pi/2 0.5  6  6];
       ub = [-10 -5 2*pi 1    12  12];
       lb = [-20 -15 -2*pi 0   2  2];
   elseif joint==4
       x0 = [0 -10 pi/2 0.5  6  6];
       ub = [5 -5 2*pi 1    12  12];
       lb = [-5 -15 -2*pi 0   2  2];
   elseif joint==5
       x0 = [15 -10 pi/2 0.5  6  6];
       ub = [20 -5 2*pi 1    12  12];
       lb = [10 -15 -2*pi 0   2  2];
   elseif joint==6
       x0 = [30 -10 pi/2 0.5  6  6];
       ub = [35 -5 2*pi 1    12  12];
       lb = [25 -15 -2*pi 0   2  2];
   elseif joint==7
       x0 = [0 0 pi/2 0.5  6  6];
       ub = [5 5 2*pi 1    12  12];
       lb = [-5 -5 -2*pi 0   2  2];
   elseif joint==8
       x0 = [-15 10 pi/2 0.5  6  6];
       ub = [-10 15 2*pi 1    12  12];
       lb = [-20 5 -2*pi 0   2  2];
   elseif joint==9
       x0 = [15 10 pi/2 0.5  6  6];
       ub = [20 15 2*pi 1    12  12];
       lb = [10 5 -2*pi 0   2  2];
   elseif joint==10
       x0 = [-30 20 pi/2 0.1  3  3];
       ub = [-25 25 2*pi 1    12  12];
       lb = [-35 15 -2*pi 0   2  2];
   elseif joint==11
       x0 = [30 20 pi/2 0.1  3  3];
       ub = [35 25 2*pi 1    12  12];
       lb = [25 15 -2*pi 0   2  2];
   end
   
options = optimset('FunValCheck','on');
[x,resnorm] = lsqnonlin(@myfun_yunmin,x0)
   
trans_v(joint)=x(1);
trans_h(joint)=x(2);
theta(joint)=x(3);
wei(joint)=x(4);
gamma1(joint)=x(5);
gamma2(joint)=x(6);
gamma3=sqrt(gamma1(joint)^2+gamma2(joint)^2);
   
%G2 = zeros(imy,imx);
for i = -floor(imy/2):floor(imy/2)
    for j = -floor(imx/2):floor(imx/2)
        xx=(j-trans_v(joint))*cos(theta(joint)) + (i-trans_h(joint))*sin(theta(joint));
        yy=(i-trans_h(joint))*cos(theta(joint)) - (j-trans_v(joint))*sin(theta(joint));
        G2(i+floor(imy/2)+1,j+floor(imx/2)+1,joint) = (1/(2*pi*gamma3^2))*exp(-.5*((xx/gamma1(joint))^2+(yy/gamma2(joint))^2))*sin(pi*(xx)/gamma3^2);
    end
end

G2_masks = 1 - roicolor(G2(:,:,joint),-0.00001,0.00001);
G2(:,:,joint)=G2_masks.*G2(:,:,joint);

g_max=max(max(G2(:,:,joint)));
G2_test(:,:,joint)=(G2(:,:,joint)./g_max)*wei(joint);
%%% dual wavelet for weight
clear wei_mat;
clear wei_mat_inv;
for i=1:joint
    for j=1:joint
        wei_mat(i,j)=sum(sum((G2_test(:,:,i).*G2_test(:,:,j))));
    end
end
wei_mat
wei_mat_inv = inv(wei_mat);

for i=1:joint
    in_pro(i) = sum(sum((G2_test(:,:,i).*(skeletonimage))));
end

for i=1:joint
    d_wei(i) = sum(wei_mat_inv(i,:).*in_pro);
end

wei
d_wei
d_wei=wei.*d_wei;

for i=1:joint
    g_max_t=max(max(G2(:,:,i)));    
    G2_test2(:,:,i)=(G2(:,:,i)./g_max_t)*d_wei(i);
end

opt=sum(G2_test2,3);
subplot(2,3,2); imagesc(opt);colormap('gray');drawnow;
skeletonimage2=(skeletonimage-opt)*128+128;
wpath  = sprintf('tmp_img');
im0=skeletonimage2;
save(wpath,'im0');

subplot(2,3,3); imagesc(skeletonimage2);colormap('gray');drawnow;
subplot(2,3,5); imagesc(opt);colormap('gray');drawnow;
   
end

modelpath  = sprintf('model_l1');
load(modelpath,'trans_v','trans_h','theta','d_wei','gamma1','gamma2','opt');

subplot(2,3,6); imagesc(opt);colormap('gray');drawnow;

%윤민맘대로 - 끝

% x,y,theth,wei,gamma
% for yloc=1:4
% for xloc=1:4
% if yloc==1
%     x0 = [xloc*16-40 yloc*16-40 pi/2 0.5  6  6]; 
%     ub = [xloc*16-32 yloc*16-36 2*pi 1    12  12];
%     lb = [xloc*16-46 yloc*16-44 -2*pi 0   2  2];
% elseif yloc==4
%     x0 = [xloc*8-20 (yloc-2)*12   pi/2 0.5  5  6]; 
%     ub = [xloc*8-2 (yloc-2)*12+28 2*pi 1    8  8];
%     lb = [xloc*8-38 (yloc-2)*12-18 -2*pi  0 1  1];
% elseif yloc==3
%     x0 = [xloc*16-40 (yloc-2)*12   -pi/2   0.5  5  5]; 
%     ub = [xloc*16-22 (yloc-2)*12+12 2*pi 1     8  8];
%     lb = [xloc*16-50 (yloc-2)*12-12 -2*pi    0 1  1];     
% else
%     if xloc==1 | xloc==4
%         x0 = [xloc*8-20 (yloc-2)*12-12   pi/2   0.5  5  5]; 
%         ub = [xloc*8-2 (yloc-2)*12 2*pi 1      8  8];
%         lb = [xloc*8-38 (yloc-2)*12-30 -2*pi    0 3  3];         
%     else
%         x0 = [xloc*8-20 (yloc-2)*12   pi/4   0.5  5  5]; 
%         ub = [xloc*8-2 (yloc-2)*12+12 2*pi 1      8  8];
%         lb = [xloc*8-38 (yloc-2)*12-12 -2*pi    0 3  3];   
%     end
% end
% 
% options = optimset('FunValCheck','on');
% %options = optimset('DerivativeCheck','on');
% %options = optimset('LevenbergMarquardt','on');
% %options.Algorithm = 'levenberg-marquardt';
% [x,resnorm] = lsqnonlin(@myfun,x0,lb,ub,options)
% 
% trans_v(xloc+(yloc-1)*4)=x(1);
% trans_h(xloc+(yloc-1)*4)=x(2);
% theta(xloc+(yloc-1)*4)=x(3);
% wei(xloc+(yloc-1)*4)=x(4);
% gamma1(xloc+(yloc-1)*4)=x(5);
% gamma2(xloc+(yloc-1)*4)=x(6);
% gamma3=sqrt(gamma1(xloc+(yloc-1)*4)^2+gamma2(xloc+(yloc-1)*4)^2);
% 
% %G2 = zeros(imy,imx);
% for i = -floor(imy/2):floor(imy/2)
%     for j = -floor(imx/2):floor(imx/2)
%         xx=(j-trans_v(xloc+(yloc-1)*4))*cos(theta(xloc+(yloc-1)*4)) + (i-trans_h(xloc+(yloc-1)*4))*sin(theta(xloc+(yloc-1)*4));
%         yy=(i-trans_h(xloc+(yloc-1)*4))*cos(theta(xloc+(yloc-1)*4)) - (j-trans_v(xloc+(yloc-1)*4))*sin(theta(xloc+(yloc-1)*4));
%         G2(i+floor(imy/2)+1,j+floor(imx/2)+1,xloc+(yloc-1)*4) = (1/(2*pi*gamma3^2))*exp(-.5*((xx/gamma1(xloc+(yloc-1)*4))^2+(yy/gamma2(xloc+(yloc-1)*4))^2))*sin(pi*(xx)/gamma3^2);
%     end
% end
% 
% G2_masks = 1 - roicolor(G2(:,:,xloc+(yloc-1)*4),-0.00001,0.00001);
% G2(:,:,xloc+(yloc-1)*4)=G2_masks.*G2(:,:,xloc+(yloc-1)*4);
% 
% g_max=max(max(G2(:,:,xloc+(yloc-1)*4)));
% G2_test(:,:,xloc+(yloc-1)*4)=(G2(:,:,xloc+(yloc-1)*4)./g_max)*wei(xloc+(yloc-1)*4);
% %%% dual wavelet for weight
% clear wei_mat;
% clear wei_mat_inv;
% for i=1:xloc+(yloc-1)*4
%     for j=1:xloc+(yloc-1)*4
%         wei_mat(i,j)=sum(sum((G2_test(:,:,i).*G2_test(:,:,j))));
%     end
% end
% wei_mat
% wei_mat_inv = inv(wei_mat);
% 
% for i=1:xloc+(yloc-1)*4
%     in_pro(i) = sum(sum((G2_test(:,:,i).*(firstimage))));
% end
% 
% for i=1:xloc+(yloc-1)*4
%     d_wei(i) = sum(wei_mat_inv(i,:).*in_pro);
% end
% 
% wei
% d_wei
% d_wei=wei.*d_wei;
% 
% for i=1:xloc+(yloc-1)*4
%     g_max_t=max(max(G2(:,:,i)));    
%     G2_test2(:,:,i)=(G2(:,:,i)./g_max_t)*d_wei(i);
% end
% 
% opt=sum(G2_test2,3);
% subplot(2,3,2); imagesc(opt);colormap('gray');drawnow;
% firstimage2=(firstimage-opt)*128+128;
% wpath  = sprintf('tmp_img');
% im0=firstimage2;
% save(wpath,'im0');
% 
% subplot(2,3,3); imagesc(firstimage2);colormap('gray');drawnow;
% subplot(2,3,5); imagesc(opt);colormap('gray');drawnow;
% end
% end
% 
% modelpath  = sprintf('model_l1');
% save(modelpath,'trans_v','trans_h','theta','d_wei','gamma1','gamma2','opt');
% 
% 
% 
% 
% 
% 
% 
% 
% clear all;
% 
% rname  = sprintf('tmp_img');
% load (rname, 'im0');
% firstimage=im0;
% subplot(2,3,1); imagesc(firstimage);colormap('gray');drawnow;
% [imy,imx]=size(firstimage);
% opt2=zeros(imy,imx);
% firstimage=(firstimage-128)/128;
% 
% 
% 
% % x,y,theth,wei,gamma
% for yloc=1:6
% for xloc=1:6
% 
%     if yloc<4
%         x0 = [xloc*10-34 yloc*10-34 pi/2 0.5  3 3 ]; 
%         ub = [xloc*10-22 yloc*10-22 2*pi 1    4 4 ];
%         lb = [xloc*10-46 yloc*10-46 0    0    2 2 ];
%     else
%         x0 = [xloc*5-17 yloc*8-17 pi/2 0.5  3 3 ]; 
%         ub = [xloc*5-5 yloc*8-5 2*pi 1    4 4 ];
%         lb = [xloc*5-29 yloc*8-29 0    0    2 2 ]; 
%     end
% 
% options = optimset('FunValCheck','on');
% %options = optimset('DerivativeCheck','on');
% %options = optimset('LevenbergMarquardt','on');
% %options.Algorithm = 'levenberg-marquardt';
% [x,resnorm] = lsqnonlin(@myfun,x0,lb,ub,options)
% 
% trans_v(xloc+(yloc-1)*6)=x(1);
% trans_h(xloc+(yloc-1)*6)=x(2);
% theta(xloc+(yloc-1)*6)=x(3);
% wei(xloc+(yloc-1)*6)=x(4);
% gamma1(xloc+(yloc-1)*6)=x(5);
% gamma2(xloc+(yloc-1)*6)=x(6);
% gamma3=sqrt(gamma1(xloc+(yloc-1)*6)^2+gamma2(xloc+(yloc-1)*6)^2);
% 
% for i = -floor(imy/2):floor(imy/2)
%     for j = -floor(imx/2):floor(imx/2)
%         xx=(j-trans_v(xloc+(yloc-1)*6))*cos(theta(xloc+(yloc-1)*6)) + (i-trans_h(xloc+(yloc-1)*6))*sin(theta(xloc+(yloc-1)*6));
%         yy=(i-trans_h(xloc+(yloc-1)*6))*cos(theta(xloc+(yloc-1)*6)) - (j-trans_v(xloc+(yloc-1)*6))*sin(theta(xloc+(yloc-1)*6));
%         G2(i+floor(imy/2)+1,j+floor(imx/2)+1,xloc+(yloc-1)*6) = (1/(2*pi*gamma3^2))*exp(-.5*((xx/gamma1(xloc+(yloc-1)*6))^2+(yy/gamma2(xloc+(yloc-1)*6))^2))*sin(pi*(xx)/gamma3^2);
%     end
% end
% 
% G2_masks = 1 - roicolor(G2(:,:,xloc+(yloc-1)*6),-0.00001,0.00001);
% G2(:,:,xloc+(yloc-1)*6)=G2_masks.*G2(:,:,xloc+(yloc-1)*6);
% 
% g_max=max(max(G2(:,:,xloc+(yloc-1)*6)));
% G2_test(:,:,xloc+(yloc-1)*6)=(G2(:,:,xloc+(yloc-1)*6)./g_max)*wei(xloc+(yloc-1)*6);
% %%% dual wavelet for weight
% clear wei_mat;
% clear wei_mat_inv;
% for i=1:xloc+(yloc-1)*6
%     for j=1:xloc+(yloc-1)*6
%         wei_mat(i,j)=sum(sum((G2_test(:,:,i).*G2_test(:,:,j))));
%     end
% end
% wei_mat;
% wei_mat_inv = inv(wei_mat);
% 
% for i=1:xloc+(yloc-1)*6
%     in_pro(i) = sum(sum((G2_test(:,:,i).*(firstimage))));
% end
% 
% for i=1:xloc+(yloc-1)*6
%     d_wei(i) = sum(wei_mat_inv(i,:).*in_pro);
% end
% 
% wei
% d_wei
% d_wei=wei.*d_wei;
% 
% for i=1:xloc+(yloc-1)*6
%     g_max_t=max(max(G2(:,:,i)));    
%     G2_test2(:,:,i)=(G2(:,:,i)./g_max_t)*d_wei(i);
% end
% 
% opt2=sum(G2_test2,3);
% subplot(2,3,2); imagesc(opt2);colormap('gray');drawnow;
% firstimage2=(firstimage-opt2)*128+128;
% wpath  = sprintf('tmp_img');
% im0=firstimage2;
% save(wpath,'im0');
% 
% subplot(2,3,3); imagesc(firstimage2);colormap('gray');drawnow;
% %subplot(2,3,5); surf(opt2);colormap('gray');drawnow;
% end
% end
% 
% modelpath  = sprintf('model_l2');
% save(modelpath,'trans_v','trans_h','theta','d_wei','gamma1','gamma2','opt2');
% 
% 
% modelpath  = sprintf('model_l1');
% load(modelpath,'trans_v','trans_h','theta','d_wei','gamma1','gamma2','opt');
% 
% 
% subplot(2,3,6); imagesc(opt+opt2);colormap('gray');drawnow;


return



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% modeling
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function F = myfun_yunmin(x)
rname  = sprintf('tmp_img');
load (rname, 'im0');
skeletonimage=im0;
%subplot(2,3,6); imagesc(firstimage);colormap('gray');drawnow;
%firstim = imread('face.png');
%firstimage=double(rgb2gray(firstim));
[imy,imx]=size(skeletonimage);
opt=zeros(imy,imx);

trans_v=x(1);
trans_h=x(2);
theta=x(3);
wei=x(4);
gamma1=x(5);
gamma2=x(6);
gamma3=sqrt(gamma1^2+gamma2^2);

%aaa=x(7)
%G2 = zeros(imy,imx);
for i = -floor(imy/2):floor(imy/2)
    for j = -floor(imx/2):floor(imx/2)
        xx=(j-trans_v)*cos(theta) + (i-trans_h)*sin(theta);
        yy=(i-trans_h)*cos(theta) - (j-trans_v)*sin(theta);
        G2(i+floor(imy/2)+1,j+floor(imx/2)+1) = (1/(2*pi*gamma3^2))*exp(-.5*((xx/gamma1)^2+(yy/gamma2)^2))*sin((pi*2/2)*(xx)/gamma3^2);
    end
end

G2_masks = 1 - roicolor(G2,-0.0001,0.0001);
G2=G2_masks.*G2;
skeletonimage=G2_masks.*skeletonimage;
skeletonimage=(skeletonimage-128)/128;
%firstimage_mean=mean(mean(firstimage));
%firstimage=firstimage-firstimage_mean;
%firstimage_max=max(max(firstimage));
%firstimage_min=min(min(firstimage));

g_max=max(max(G2));
G2=(G2./g_max).*wei;

subplot(2,3,4); imagesc(skeletonimage);colormap('gray');drawnow;
%subplot(2,3,5); imagesc(G2);colormap('gray');drawnow;

%F = var(var((skeletonimage-G2)));
F = ((abs(skeletonimage-G2)));



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% modeling
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function F = myfun(x)
% rname  = sprintf('tmp_img');
% load (rname, 'im0');
% firstimage=im0;
% %subplot(2,3,6); imagesc(firstimage);colormap('gray');drawnow;
% %firstim = imread('face.png');
% %firstimage=double(rgb2gray(firstim));
% [imy,imx]=size(firstimage);
% opt=zeros(imy,imx);
% 
% trans_v=x(1);
% trans_h=x(2);
% theta=x(3);
% wei=x(4);
% gamma1=x(5);
% gamma2=x(6);
% gamma3=sqrt(gamma1^2+gamma2^2);
% 
% %aaa=x(7)
% %G2 = zeros(imy,imx);
% for i = -floor(imy/2):floor(imy/2)
%     for j = -floor(imx/2):floor(imx/2)
%         xx=(j-trans_v)*cos(theta) + (i-trans_h)*sin(theta);
%         yy=(i-trans_h)*cos(theta) - (j-trans_v)*sin(theta);
%         G2(i+floor(imy/2)+1,j+floor(imx/2)+1) = (1/(2*pi*gamma3^2))*exp(-.5*((xx/gamma1)^2+(yy/gamma2)^2))*sin((pi*2/2)*(xx)/gamma3^2);
%     end
% end
% 
% G2_masks = 1 - roicolor(G2,-0.0001,0.0001);
% G2=G2_masks.*G2;
% firstimage=G2_masks.*firstimage;
% firstimage=(firstimage-128)/128;
% %firstimage_mean=mean(mean(firstimage));
% %firstimage=firstimage-firstimage_mean;
% %firstimage_max=max(max(firstimage));
% %firstimage_min=min(min(firstimage));
% 
% g_max=max(max(G2));
% G2=(G2./g_max).*wei;
% 
% subplot(2,3,4); imagesc(firstimage);colormap('gray');drawnow;
% %subplot(2,3,5); imagesc(G2);colormap('gray');drawnow;
% 
% %F = var(var((firstimage-G2)));
% F = ((abs(firstimage-G2)));


