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

%점수 매기기 - 주변 8개 픽셀의 평균(값이 0이라면)
for col=2:imy-1
    for row=round(imx/2):imx-1
        if skeletonimage(col, row)==0
            sum=skeletonimage(col-1,row-1)+skeletonimage(col,row-1)+skeletonimage(col+1,row-1)+skeletonimage(col-1,row)+skeletonimage(col+1,row)+skeletonimage(col-1,row+1)+skeletonimage(col,row+1)+skeletonimage(col+1,row+1);
            skeletonimage(col,row)=sum/8;
        end
    end
    
    for row=round(imx/2):-1:2
        if skeletonimage(col,row)==0
            sum=skeletonimage(col-1,row-1)+skeletonimage(col,row-1)+skeletonimage(col+1,row-1)+skeletonimage(col-1,row)+skeletonimage(col+1,row)+skeletonimage(col-1,row+1)+skeletonimage(col,row+1)+skeletonimage(col+1,row+1);
            skeletonimage(col,row)=sum/8;
        end
    end
end

skeletonimage = skeletonimage ./ 255;

subplot(2,3,1); imagesc(firstimage);colormap('gray');drawnow; %이미지 그리기
wpath  = sprintf('tmp_img');
im0=firstimage;
save(wpath,'im0');

%관절 샘플 점
opt(45 * imy + 16) = 1;
opt(15 * imy + 36) = 1;
opt(30 * imy + 36) = 1;
opt(45 * imy + 36) = 1;
opt(60 * imy + 36) = 1;
opt(75 * imy + 36) = 1;
opt(45 * imy + 61) = 1;
opt(30 * imy + 76) = 1;
opt(60 * imy + 71) = 1;
opt(15 * imy + 81) = 1;
opt(75 * imy + 81) = 1;

wwpath = sprintf('tmp_opt');
im1=opt;
save(wwpath, 'im1');

%관절끼리 연결
drawSkeleton([46, 16], [46, 36]);
drawSkeleton([46, 36], [31, 36]);
drawSkeleton([31, 36], [16, 36]);
drawSkeleton([46, 36], [61, 36]);
drawSkeleton([61, 36], [76, 36]);
drawSkeleton([46, 36], [46, 61]);
drawSkeleton([46, 61], [31, 71]);
drawSkeleton([31, 71], [16, 81]);
drawSkeleton([46, 61], [61, 71]);
drawSkeleton([61, 71], [76, 81]);

rname  = sprintf('tmp_opt');
load (rname, 'im1');
opt=im1;

subplot(2,3,2); imagesc(opt);colormap('gray');drawnow; %이미지 그리기

% subplot(2,3,1); imagesc(firstimage);colormap('gray');drawnow; %이미지 그리기
% wpath  = sprintf('tmp_img');
% im0=firstimage;
% save(wpath,'im0');
% firstimage=(firstimage-128)/128;

%관절 탐색 - 윤민 마음대로~
x0 = [45*imy+16, 15*imy+36, 30*imy+36, 45*imy+36, 60*imy+36, 75*imy+36, 45*imy+61, 30*imy+71, 60*imy+71, 15*imy+81, 75*imy+81];
ub = x0 + x0;
lb = x0 - x0;

options = optimset('FunValCheck','on');
[x,resnorm] = lsqnonlin(@myfun_yunmin,x0,lb,ub,options)

rname  = sprintf('tmp_opt');
load (rname, 'im1');
opt=im1;
   
head=round(x(1))
lefthand=round(x(2))
leftelbow=round(x(3))
spinshoulderbase=round(x(4))
rightelbow=round(x(5))
righthand=round(x(6))
spinbase=round(x(7))
leftknee=round(x(8))
rightknee=round(x(9))
leftfoot=round(x(10))
rightfoot=round(x(11))


%modelpath  = sprintf('model_l1');
%load(modelpath,'head','lefthand','leftelbow','spinshoulderbase','rightelbow','righthand','spinbase', 'leftknee', 'rightknee', 'leftfoot', 'rightfoot', 'opt');

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
firstimage=im0;

%subplot(2,3,6); imagesc(firstimage);colormap('gray');drawnow;
%firstim = imread('face.png');
%firstimage=double(rgb2gray(firstim));
[imy,imx]=size(firstimage);
opt_yunmin=zeros(imy,imx);

head=round(x(1));
lefthand=round(x(2));
leftelbow=round(x(3));
spinshoulderbase=round(x(4));
rightelbow=round(x(5));
righthand=round(x(6));
spinbase=round(x(7));
leftknee=round(x(8));
rightknee=round(x(9));
leftfoot=round(x(10));
rightfoot=round(x(11));

%점점 끌려가도록 하기
move_size=2;
[yy,xx]=figureoutXY(head);
max_value=firstimage(head);
maxX=xx; maxY=yy;
for i=yy-move_size:yy+move_size
    for j=xx-move_size:xx+move_size
        if firstimage((j-1)*91+i)>=max_value
            max_value=firstimage((j-1)*91+i);
            maxX=j; maxY=i;
        end
    end
end
head=(maxX-1)*91+maxY;

[yy,xx]=figureoutXY(spinshoulderbase);
max_value=firstimage(spinshoulderbase);
maxX=xx; maxY=yy;
for i=yy-move_size:yy+move_size
    for j=xx-move_size:xx+move_size
        if firstimage((j-1)*91+i)>=max_value
            max_value=firstimage((j-1)*91+i);
            maxX=j; maxY=i;
        end
    end
end
spinshoulderbase=(maxX-1)*91+maxY;

[yy,xx]=figureoutXY(leftelbow);
max_value=firstimage(leftelbow);
maxX=xx; maxY=yy;
for i=yy-move_size:yy+move_size
    for j=xx-move_size:xx+move_size
        if firstimage((j-1)*91+i)>=max_value
            max_value=firstimage((j-1)*91+i);
            maxX=j; maxY=i;
        end
    end
end
leftelbow=(maxX-1)*91+maxY;

[yy,xx]=figureoutXY(lefthand);
max_value=firstimage(lefthand);
maxX=xx; maxY=yy;
for i=yy-move_size:yy+move_size
    for j=xx-move_size:xx+move_size
        if firstimage((j-1)*91+i)>=max_value
            max_value=firstimage((j-1)*91+i);
            maxX=j; maxY=i;
        end
    end
end
lefthand=(maxX-1)*91+maxY;

[yy,xx]=figureoutXY(rightelbow);
max_value=firstimage(rightelbow);
maxX=xx; maxY=yy;
for i=yy-move_size:yy+move_size
    for j=xx-move_size:xx+move_size
        if firstimage((j-1)*91+i)>=max_value
            max_value=firstimage((j-1)*91+i);
            maxX=j; maxY=i;
        end
    end
end
rightelbow=(maxX-1)*91+maxY;

[yy,xx]=figureoutXY(righthand);
max_value=firstimage(righthand);
maxX=xx; maxY=yy;
for i=yy-move_size:yy+move_size
    for j=xx-move_size:xx+move_size
        if firstimage((j-1)*91+i)>=max_value
            max_value=firstimage((j-1)*91+i);
            maxX=j; maxY=i;
        end
    end
end
righthand=(maxX-1)*91+maxY;

[yy,xx]=figureoutXY(spinbase);
max_value=firstimage(spinbase);
maxX=xx; maxY=yy;
for i=yy-move_size:yy+move_size
    for j=xx-move_size:xx+move_size
        if firstimage((j-1)*91+i)>=max_value
            max_value=firstimage((j-1)*91+i);
            maxX=j; maxY=i;
        end
    end
end
spinbase=(maxX-1)*91+maxY;

[yy,xx]=figureoutXY(leftknee);
max_value=firstimage(leftknee);
maxX=xx; maxY=yy;
for i=yy-move_size:yy+move_size
    for j=xx-move_size:xx+move_size
        if firstimage((j-1)*91+i)>=max_value
            max_value=firstimage((j-1)*91+i);
            maxX=j; maxY=i;
        end
    end
end
leftknee=(maxX-1)*91+maxY;

[yy,xx]=figureoutXY(leftfoot);
max_value=firstimage(leftfoot);
maxX=xx; maxY=yy;
for i=yy-move_size:yy+move_size
    for j=xx-move_size:xx+move_size
        if firstimage((j-1)*91+i)>=max_value
            max_value=firstimage((j-1)*91+i);
            maxX=j; maxY=i;
        end
    end
end
leftfoot=(maxX-1)*91+maxY;

[yy,xx]=figureoutXY(rightknee);
max_value=firstimage(rightknee);
maxX=xx; maxY=yy;
for i=yy-move_size:yy+move_size
    for j=xx-move_size:xx+move_size
        if firstimage((j-1)*91+i)>=max_value
            max_value=firstimage((j-1)*91+i);
            maxX=j; maxY=i;
        end
    end
end
rightknee=(maxX-1)*91+maxY;

[yy,xx]=figureoutXY(rightfoot);
max_value=firstimage(rightfoot);
maxX=xx; maxY=yy;
for i=yy-move_size:yy+move_size
    for j=xx-move_size:xx+move_size
        if firstimage((j-1)*91+i)>=max_value
            max_value=firstimage((j-1)*91+i);
            maxX=j; maxY=i;
        end
    end
end
rightfoot=(maxX-1)*91+maxY;

%관절 샘플 점
opt_yunmin(head) = 1;
opt_yunmin(lefthand) = 1;
opt_yunmin(leftelbow) = 1;
opt_yunmin(spinshoulderbase) = 1;
opt_yunmin(rightelbow) = 1;
opt_yunmin(righthand) = 1;
opt_yunmin(spinbase) = 1;
opt_yunmin(leftknee) = 1;
opt_yunmin(rightknee) = 1;
opt_yunmin(leftfoot) = 1;
opt_yunmin(rightfoot) = 1;

mpath  = sprintf('tmp_opt_yunmin');
im2=opt_yunmin;
save(mpath,'im2');

%관절끼리 연결
[a,b]=figureoutXY(head); [c,d]=figureoutXY(spinshoulderbase);
drawSkeleton_optim([a,b],[c,d]);

[a,b]=figureoutXY(spinshoulderbase); [c,d]=figureoutXY(leftelbow);
drawSkeleton_optim([a,b],[c,d]);

[a,b]=figureoutXY(leftelbow); [c,d]=figureoutXY(lefthand);
drawSkeleton_optim([a,b],[c,d]);

[a,b]=figureoutXY(spinshoulderbase); [c,d]=figureoutXY(rightelbow);
drawSkeleton_optim([a,b],[c,d]);

[a,b]=figureoutXY(rightelbow); [c,d]=figureoutXY(righthand);
drawSkeleton_optim([a,b],[c,d]);

[a,b]=figureoutXY(spinshoulderbase); [c,d]=figureoutXY(spinbase);
drawSkeleton_optim([a,b],[c,d]);

[a,b]=figureoutXY(spinbase); [c,d]=figureoutXY(leftknee);
drawSkeleton_optim([a,b],[c,d]);

[a,b]=figureoutXY(leftknee); [c,d]=figureoutXY(leftfoot);
drawSkeleton_optim([a,b],[c,d]);

[a,b]=figureoutXY(spinbase); [c,d]=figureoutXY(rightknee);
drawSkeleton_optim([a,b],[c,d]);

[a,b]=figureoutXY(rightknee); [c,d]=figureoutXY(rightfoot);
drawSkeleton_optim([a,b],[c,d]);

rname  = sprintf('tmp_opt_yunmin');
load (rname, 'im2');
opt_yunmin=im2;

subplot(2,3,4); imagesc(opt_yunmin);colormap('gray');drawnow;
subplot(2,3,5); imagesc(firstimage+opt_yunmin);colormap('gray');drawnow;
F=firstimage+opt_yunmin;

%aaa=x(7)
%G2 = zeros(imy,imx);
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
% skeletonimage=G2_masks.*skeletonimage;
% %firstimage_mean=mean(mean(firstimage));
% %firstimage=firstimage-firstimage_mean;
% %firstimage_max=max(max(firstimage));
% %firstimage_min=min(min(firstimage));
% 
% g_max=max(max(G2));
% G2=(G2./g_max).*wei;
% 
% subplot(2,3,4); imagesc(skeletonimage);colormap('gray');drawnow;
% %subplot(2,3,5); imagesc(G2);colormap('gray');drawnow;
% 
% %F = var(var((firstimage-G2)));
% F = ((abs(skeletonimage-G2)));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%skeleton sample 그리기
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function []=drawSkeleton(a, b)
rname  = sprintf('tmp_opt');
load (rname, 'im1');
opt=im1;
[imy,imx]=size(opt);

if a(1)==b(1)
    for y=a(2):b(2)
        opt((a(1)-1)*imy+y)=1;
    end
elseif a(2)==b(2)
    if a(1)>b(1)
        for x=a(1):-1:b(1)
            opt((x-1)*imy+a(2))=1;
        end
    else
        for x=a(1):b(1)
            opt((x-1)*imy+a(2))=1;
        end
    end
else
    gradient=(a(2)-b(2))/(a(1)-b(1));
    if a(1)>b(1)
        for x=a(1):-1:b(1)
            yy = gradient*(x-a(1))+a(2);
            yy=round(yy);
            opt((x-1)*imy+yy)=1;
        end
    else
        for x=a(1):b(1)
            yy = gradient*(x-a(1))+a(2);
            yy=round(yy);
            opt((x-1)*imy+yy)=1;
        end
    end
    
end

wpath  = sprintf('tmp_opt');
im1=opt;
save(wpath,'im1');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%skeleton sample 그리기 - optimization용
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function []=drawSkeleton_optim(a, b)
rname  = sprintf('tmp_opt_yunmin');
load (rname, 'im2');
opt_yunmin=im2;
[imy,imx]=size(opt_yunmin);

if a(1)==b(1)
    for y=a(2):b(2)
        opt_yunmin((a(1)-1)*imy+y)=1;
    end
elseif a(2)==b(2)
    if a(1)>b(1)
        for x=a(1):-1:b(1)
            opt_yunmin((x-1)*imy+a(2))=1;
        end
    else
        for x=a(1):b(1)
            opt_yunmin((x-1)*imy+a(2))=1;
        end
    end
else
    gradient=(a(2)-b(2))/(a(1)-b(1));
    if a(1)>b(1)
        for x=a(1):-1:b(1)
            yy = gradient*(x-a(1))+a(2);
            yy=round(yy);
            opt_yunmin((x-1)*imy+yy)=1;
        end
    else
        for x=a(1):b(1)
            yy = gradient*(x-a(1))+a(2);
            yy=round(yy);
            opt_yunmin((x-1)*imy+yy)=1;
        end
    end
    
end

mpath  = sprintf('tmp_opt_yunmin');
im2=opt_yunmin;
save(mpath,'im2');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%좌표알아내기
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [y,x]=figureoutXY(a)
y=a-(fix(a/91)*91);
x=fix(a/91)+1;



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


