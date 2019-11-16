% CSE597C Gabor filter
% Seungkyu Lee

%테스트 - 관절 줄이기: 팔꿈치, 무릎 없애고 찾기
%테스트 - rotation 추가
%테스트 - skeleton end point 높이기

function o = otest

clear all;
dct_driven=1;

skeletonim = imread('person_skeleton5.jpg'); 
%skeletonim = imread('md2.jpg');
%skeletonimage=double(rgb2gray(skeletonim));
skeletonimage=double(skeletonim);
skeletonimage=255-skeletonimage;
skeletonimage=skeletonimage./255;

[imy,imx]=size(skeletonimage);
opt=zeros(imy,imx);

% person 불러오기
person = imread('person_black5.bmp');
personimage = double(person);
personimage = personimage ./ 255;
person_blur = imgaussfilt(personimage, 8);

for i=1:imy
    for j=1:imx
        if skeletonimage(i,j)>0.9
            skeletonimage(i,j)=1;
        else
            skeletonimage(i,j)=0;
        end
    end
end

%skeleton end point 높이기----------------
skeleton_blur = imgaussfilt(skeletonimage, 7);
skeletonimage = skeletonimage - skeleton_blur;
skeletonimage = skeletonimage + 1;
skel_max=0;
for i=1:imy
    for j=1:imx
        if skeletonimage(i,j)>=1
            skeletonimage(i,j)=1;
        else
            if skeletonimage(i,j) > skel_max
                skel_max=skeletonimage(i,j);
            end
        end
    end
end
%---------------------------------------------

%skeleton 두껍게 하기------------------
% se = strel('ball',3,3);
% skeletonimage=imerode(skeletonimage,se);
% 
% maximum=max(max(skeletonimage))
% for i=1:imy
%     for j=1:imx
%         if skeletonimage(i,j)==maximum
%             skeletonimage(i,j)=1;
%         else
%             skeletonimage(i,j)=minimum-0.01;
%         end
%     end
% end
%----------------------------------------

for yy=1:imy
    for xx=1:imx
        if skeletonimage(yy, xx) ~= 1
            person_blur(yy, xx) = skeletonimage(yy, xx);
        end
    end
end

%for문을 이용한 smoothing filter 만들기
sigma=1.0;
s=2.0 * sigma * sigma;
sum_filter=0;
masksize=7;

for a=masksize*(-1):masksize
    for b=masksize*(-1):masksize
        r=sqrt(a*a + b*b);
        Gkernel(a+masksize+1, b+masksize+1)=(exp(-(r*r)/s))/(3.14 * s);
        sum_filter = sum_filter + Gkernel(a+masksize+1, b+masksize+1);
    end
end

for a=1:masksize*2+1
    for b=1:masksize*2+1
        Gkernel(a,b) = Gkernel(a, b) / sum_filter;
    end
end

for a=masksize+1:imy-masksize
    for b=masksize+1:imx-masksize
        sum_gaussian = 0;
        if person_blur(a, b) > skel_max
            for c=masksize*(-1):masksize
                for d=masksize*(-1):masksize
                    sum_gaussian = sum_gaussian + person_blur(a+c, b+d) * Gkernel(c+masksize+1, d+masksize+1);
                end
            end
            
            person_blur(a, b) = sum_gaussian;
        end
        
    end
end

subplot(2,2,1); imagesc(person_blur);colormap('gray');drawnow; %이미지 그리기
wpath  = sprintf('tmp_img');
im0=person_blur;
save(wpath,'im0');
%person_blur=(person_blur-128)/128;

%관절 탐색 - 윤민 마음대로~
for joint=1:6
   if joint==1 %머리-어깨중심
       %x0 = [0, -30, 0, -10, 0, 10, -15, -10, 15, -10, -30, -10, 30, -10, -5, 15, 5, 15, -15, 25, 15, 25];
       %x0 = [0, 10, 5, 15, 15, 25, -5, 15, -15, 25];
       x0=[-5, -35, -5, -20, 0];
       ub=[];
       lb=[];
       setGlobalCount(1);
    elseif joint==2 %어깨중심-가랑이
        %x0=[getGlobalSpinShoulderBaseX, getGlobalSpinShoulderBaseY, -10, 5];
        x0=[-10, -10, -5, 10, 0];
        setGlobalCount(2);
    elseif joint==3 %어깨중심-왼쪽손
        x0 = [getGlobalSpinShoulderBaseX, getGlobalSpinShoulderBaseY, getGlobalSpinShoulderBaseX-30, getGlobalSpinShoulderBaseY-3, 0];
        %x0 = [-10, -15, -20, -13];
        setGlobalCount(3);
    elseif joint==4 %어깨중심-오른쪽손
        x0 = [getGlobalSpinShoulderBaseX, getGlobalSpinShoulderBaseY, getGlobalSpinShoulderBaseX+30, getGlobalSpinShoulderBaseY-3, 0];
        %x0 = [10, -15, 20, -13];
        setGlobalCount(4);
    elseif joint==5 %가랑이-왼쪽발
        x0 = [getGlobalSpinBaseX, getGlobalSpinBaseY, getGlobalSpinBaseX-20, getGlobalSpinBaseY+25, 0];
        %x0 = [-10, 10, -12, 20];
        setGlobalCount(5);
    elseif joint==6 %가랑이-오른쪽발
        x0 = [getGlobalSpinBaseX, getGlobalSpinBaseY, getGlobalSpinBaseX+20, getGlobalSpinBaseY+25, 0];
        %x0 = [10, 10, 12, 20];
        setGlobalCount(6);
   end
   
options = optimset('FunValCheck','on');
%[x,resnorm] = lsqnonlin(@myfun_yunmin,x0,lb,ub,options)
[x,resnorm] = fminsearch(@myfun_yunmin,x0, options)
   
if joint==1
    
    if x(2) < x(4)
        setGlobalHead(round(x(1)), round(x(2)));
        setGlobalSpinShoulderBase(round(x(3)), round(x(4)));
    else
        setGlobalHead(round(x(3)), round(x(4)));
        setGlobalSpinShoulderBase(round(x(1)), round(x(2)));
    end
    
elseif joint==2
    
    if x(2) < x(4)
        setGlobalSpinBase(round(x(3)), round(x(4)));
    else
        setGlobalSpinBase(round(x(3)), round(x(4)));
    end
    
elseif joint==3
    
    if x(1) < x(3)
        setGlobalLeftHand(round(x(1)), round(x(2)));
    else
        setGlobalLeftHand(round(x(3)), round(x(4)));
    end
    
elseif joint==4
    
    if x(1) < x(3)
        setGlobalRightHand(round(x(3)), round(x(4)));
    else
        setGlobalRightHand(round(x(1)), round(x(2)));
    end
        
elseif joint==5
    
    if x(2) < x(4)
        setGlobalLeftFoot(round(x(3)), round(x(4)));
    else
        setGlobalLeftFoot(round(x(1)), round(x(2)));
    end
    
elseif joint==6
    if x(2) < x(4)
        setGlobalRightFoot(round(x(3)), round(x(4)));
    else
        setGlobalRightFoot(round(x(1)), round(x(2)));
    end
   
end

x=round(x);
x=x+45
% 
% person_blur2=person_blur.*opt;
% %personimage2=(personimage-opt)*128+128;
% % wpath  = sprintf('tmp_img');
% % im0=personimage2;
% % save(wpath,'im0');

%subplot(2,3,3); imagesc(person_blur);colormap('gray');drawnow;
% subplot(2,3,5); imagesc(opt);colormap('gray');drawnow;
   
end


%modelpath  = sprintf('model_l1');
%load(modelpath,'trans_v','trans_h','theta','d_wei','gamma1','gamma2','opt');

rname  = sprintf('opt_img');
load (rname, 'im_opt');
opt=im_opt;
subplot(2,2,4); imagesc(opt+person_blur);colormap('gray');drawnow;

%윤민맘대로 - 끝

return

function setGlobalCount(val1)
global Count
Count = val1;

function r = getGlobalCount
global Count
r = Count;

function setGlobalHead(val1, val2)
global Head
Head = [val1, val2];

function r = getGlobalHeadX
global Head
r = Head(1);

function r = getGlobalHeadY
global Head
r = Head(2);

function setGlobalSpinShoulderBase(val1, val2)
global SpinShoulderbase
SpinShoulderbase = [val1, val2];

function r = getGlobalSpinShoulderBaseX
global SpinShoulderbase
r = SpinShoulderbase(1);

function r = getGlobalSpinShoulderBaseY
global SpinShoulderbase
r = SpinShoulderbase(2);

function setGlobalSpinBase(val1, val2)
global SpinBase
SpinBase = [val1, val2];

function r = getGlobalSpinBaseX
global SpinBase
r = SpinBase(1);

function r = getGlobalSpinBaseY
global SpinBase
r = SpinBase(2);

function setGlobalLeftHand(val1, val2)
global LeftHand
LeftHand = [val1, val2];

function r = getGlobalLeftHandX
global LeftHand
r = LeftHand(1);

function r = getGlobalLeftHandY
global LeftHand
r = LeftHand(2);

function setGlobalRightHand(val1, val2)
global RightHand
RightHand = [val1, val2];

function r = getGlobalRightHandX
global RightHand
r = RightHand(1);

function r = getGlobalRightHandY
global RightHand
r = RightHand(2);

function setGlobalRightFoot(val1, val2)
global RightFoot
RightFoot = [val1, val2];

function r = getGlobalRightFootX
global RightFoot
r = RightFoot(1);

function r = getGlobalRightFootY
global RightFoot
r = RightFoot(2);

function setGlobalLeftFoot(val1, val2)
global LeftFoot
LeftFoot = [val1, val2];

function r = getGlobalLeftFootX
global LeftFoot
r = LeftFoot(1);

function r = getGlobalLeftFootY
global LeftFoot
r = LeftFoot(2);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% modeling
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function F = myfun_yunmin(x)
rname  = sprintf('tmp_img');
load (rname, 'im0');
person_blur=im0;
%subplot(2,3,6); imagesc(skeletonimage);colormap('gray');drawnow;
%skeletonim = imread('face.png');
%skeletonimage=double(rgb2gray(skeletonim));
[imy,imx]=size(person_blur);
opt=zeros(imy,imx);

x1=round(x(1));
y1=round(x(2));
x2=round(x(3));
y2=round(x(4));
rotation=x(5);

sum_score=0;
sum_count=0;
half_imy=(imy-1)/2;
half_imx=(imx-1)/2;
    
for a=1:getGlobalCount

    if getGlobalCount==2
        if round(x(2)) < round(x(4))
            distanceX=round(x(1))-getGlobalSpinShoulderBaseX;
            distanceY=round(x(2))-getGlobalSpinShoulderBaseY;
        else
            distanceX=round(x(3))-getGlobalSpinShoulderBaseX;
            distanceY=round(x(4))-getGlobalSpinShoulderBaseY;
        end
    elseif getGlobalCount==3
        if round(x(1)) < round(x(3))
            distanceX=round(x(3))-getGlobalSpinShoulderBaseX;
            distanceY=round(x(4))-getGlobalSpinShoulderBaseY;
        else
            distanceX=round(x(1))-getGlobalSpinShoulderBaseX;
            distanceY=round(x(2))-getGlobalSpinShoulderBaseY;
        end
         
    elseif getGlobalCount==4
        if round(x(1)) < round(x(3))
            distanceX=round(x(1))-getGlobalSpinShoulderBaseX;
            distanceY=round(x(2))-getGlobalSpinShoulderBaseY;
        else
            distanceX=round(x(3))-getGlobalSpinShoulderBaseX;
            distanceY=round(x(4))-getGlobalSpinShoulderBaseY;
        end
    elseif getGlobalCount==5
        if round(x(2)) < round(x(4))
            distanceX=round(x(1))-getGlobalSpinBaseX;
            distanceY=round(x(2))-getGlobalSpinBaseY;
        else
            distanceX=round(x(3))-getGlobalSpinBaseX;
            distanceY=round(x(4))-getGlobalSpinBaseY;
        end
    elseif getGlobalCount==6
        if round(x(2)) < round(x(4))
            distanceX=round(x(1))-getGlobalSpinBaseX;
            distanceY=round(x(2))-getGlobalSpinBaseY;
        else
            distanceX=round(x(3))-getGlobalSpinBaseX;
            distanceY=round(x(4))-getGlobalSpinBaseY;
        end
    end

    if a==2
            x1 = round(getGlobalHeadX+distanceX);
            y1 = round(getGlobalHeadY+distanceY);
            x2 = round(getGlobalSpinShoulderBaseX+distanceX);
            y2 = round(getGlobalSpinShoulderBaseY+distanceY);
    elseif a==3
            x1 = round(getGlobalSpinShoulderBaseX+distanceX);
            y1 = round(getGlobalSpinShoulderBaseY+distanceY);
            x2 = round(getGlobalSpinBaseX+distanceX);
            y2 = round(getGlobalSpinBaseY+distanceY);
    elseif a==4
            x1 = round(getGlobalSpinShoulderBaseX+distanceX);
            y1 = round(getGlobalSpinShoulderBaseY+distanceY);
            x2 = round(getGlobalLeftHandX+distanceX);
            y2 = round(getGlobalLeftHandY+distanceY);
    elseif a==5
            x1 = round(getGlobalSpinShoulderBaseX+distanceX);
            y1 = round(getGlobalSpinShoulderBaseY+distanceY);
            x2 = round(getGlobalRightHandX+distanceX);
            y2 = round(getGlobalRightHandY+distanceY);
    elseif a==6
            x1 = round(getGlobalSpinBaseX+distanceX);
            y1 = round(getGlobalSpinBaseY+distanceY);
            x2 = round(getGlobalLeftFootX+distanceX);
            y2 = round(getGlobalLeftFootY+distanceY);
    end
    
    %rotation 파트---------------------
    if a==1
        if x1 < 1-half_imx
            x1=1-half_imx;
        elseif x1 > imx-half_imx
            x1=imx-half_imx;
        end
    
        if y1 < 1-half_imy
            y1=1-half_imy;
        elseif y1 > imy-half_imy
            y1=imy-half_imy;
        end
    
        if x2 < 1-half_imx
            x2=1-half_imx;
        elseif x2 > imx-half_imx
            x2=imx-half_imx;
        end
    
        if y2 < 1-half_imy
            y2=1-half_imy;
        elseif y2 > imy-half_imy
            y2=imy-half_imy;
        end
    
        min_pixel=1; %rotation을 위해 추가
        if x1==x2
            for i=min(y1,y2):max(y1,y2)
                if min_pixel >= person_blur(half_imy+i, half_imx+x1)
                    min_pixel = person_blur(half_imy+i, half_imx+x1);
                    min_x=half_imx+x1; min_y=half_imy+i;
                end
            end
        
        else
            gradient=(y2-y1)/(x2-x1);
            if gradient > 0
                if y2 > y1
                    for j=x1:x2
                        y=gradient*(j-x1)+y1;
                        
                        if min_pixel >= person_blur(half_imy+round(y),half_imx+j)
                            min_pixel = person_blur(half_imy+round(y),half_imx+j);
                            min_x=j; min_y=round(y);
                        end
                        
                        if j>x1
                            if abs(pastY-round(y))>sqrt(2)
                               for k=pastY:round(y)
                                   if min_pixel >= person_blur(half_imy+k, half_imx+j)
                                        min_pixel = person_blur(half_imy+k, half_imx+j);
                                        min_x=j; min_y=k;
                                   end
                               end
                            end
                        end
                        pastY=round(y);
                    end
                else
                    for j=x2:x1
                        y=gradient*(j-x1)+y1;
                        
                        if min_pixel >= person_blur(half_imy+round(y),half_imx+j)
                            min_pixel = person_blur(half_imy+round(y),half_imx+j);
                            min_x=j; min_y=round(y);
                        end
                        
                        if j>x2
                            if abs(pastY-round(y))>sqrt(2)
                               for k=pastY:round(y)
                                   if min_pixel >= person_blur(half_imy+k,half_imx+j)
                                        min_pixel = person_blur(half_imy+k,half_imx+j);
                                        min_x=j; min_y=k;
                                   end
                               end
                            end
                        end
                        pastY=round(y);
                    end
                end
            else
                if y2 > y1
                    for j=x2:x1
                        y=gradient*(j-x1)+y1;
                        
                        if min_pixel >= person_blur(half_imy+round(y),half_imx+j)
                            min_pixel = person_blur(half_imy+round(y),half_imx+j);
                            min_x=j; min_y=round(y);
                        end
                        
                        if j>x2
                            if abs(pastY-round(y))>sqrt(2)
                               for k=round(y):pastY
                                   if min_pixel >= person_blur(half_imy+k,half_imx+j)
                                        min_pixel = person_blur(half_imy+k,half_imx+j);
                                        min_x=j; min_y=k;
                                   end
                               end
                            end
                        end
                        pastY=round(y);
                    end
                elseif y1 > y2
                    for j=x1:x2
                        y=gradient*(j-x1)+y1;
                        
                        if min_pixel >= person_blur(half_imy+round(y),half_imx+j)
                            min_pixel = person_blur(half_imy+round(y),half_imx+j);
                            min_x=j; min_y=round(y);
                        end
                        
                        if j>x1
                            if abs(pastY-round(y))>sqrt(2)
                               for k=round(y):pastY
                                   if min_pixel >= person_blur(half_imy+k,half_imx+j)
                                        min_pixel = person_blur(half_imy+k,half_imx+j);
                                        min_x=j; min_y=k;
                                   end
                               end
                            end
                        end
                        pastY=round(y);
                    end
                else
                    if x1 > x2
                        for j=x2:x1
                            y=gradient*(j-x1)+y1;
                        
                            if min_pixel >= person_blur(half_imy+round(y),half_imx+j)
                                min_pixel = person_blur(half_imy+round(y),half_imx+j);
                                min_x=j; min_y=round(y);
                            end
                        end
                    else
                        for j=x1:x2
                            y=gradient*(j-x1)+y1;
                        
                            if min_pixel >= person_blur(half_imy+round(y),half_imx+j)
                                min_pixel = person_blur(half_imy+round(y),half_imx+j);
                                min_x=j; min_y=round(y);
                            end
                        end
                    end
                end
            end
        end
    
        x1=round((x1-min_x)*cos(rotation)-(y1-min_y)*sin(rotation) + min_x);
        y1=round((x1-min_x)*sin(rotation)+(y1-min_y)*cos(rotation) + min_y);
        x2=round((x2-min_x)*cos(rotation)-(y2-min_y)*sin(rotation) + min_x);
        y2=round((x2-min_x)*sin(rotation)+(y2-min_y)*cos(rotation) + min_y);
    end
    %------------------------------------------------------------------
    
    %실제 라인 최소값 계산 파트------------------------------------------
    if x1 < 1-half_imx
        x1=1-half_imx;
    elseif x1 > imx-half_imx
        x1=imx-half_imx;
    end
    
    if y1 < 1-half_imy
        y1=1-half_imy;
    elseif y1 > imy-half_imy
        y1=imy-half_imy;
    end
    
    if x2 < 1-half_imx
        x2=1-half_imx;
    elseif x2 > imx-half_imx
        x2=imx-half_imx;
    end
    
    if y2 < 1-half_imy
        y2=1-half_imy;
    elseif y2 > imy-half_imy
        y2=imy-half_imy;
    end
    
    if x1==x2
        for i=min(y1,y2):max(y1,y2)
            sum_score=sum_score+person_blur(half_imy+i,half_imx+x1);
            sum_count=sum_count+1;
            opt(half_imy+i,half_imx+x1)=1;
        end
    else
        gradient=(y2-y1)/(x2-x1);
        if gradient > 0
            if y2 > y1
                    for j=x1:x2
                        y=gradient*(j-x1)+y1;
                        sum_score=sum_score+person_blur(half_imy+round(y),half_imx+j);
                        sum_count=sum_count+1;
                        opt(half_imy+round(y),half_imx+j)=1;
                        
                        if j>x1
                            if abs(pastY-round(y))>sqrt(2)
                               for k=pastY:round(y)
                                   sum_score=sum_score+person_blur(half_imy+k, half_imx+j);
                                   sum_count=sum_count+1;
                                   opt(half_imy+k, half_imx+j)=1;
                               end
                            end
                        end
                        pastY=round(y);
                    end
            else
                    for j=x2:x1
                        y=gradient*(j-x1)+y1;
                        sum_score=sum_score+person_blur(half_imy+round(y),half_imx+j);
                        sum_count=sum_count+1;
                        opt(half_imy+round(y),half_imx+j)=1; 
                        
                        if j>x2
                            if abs(pastY-round(y))>sqrt(2)
                               for k=pastY:round(y)
                                   sum_score=sum_score+person_blur(half_imy+k, half_imx+j);
                                   sum_count=sum_count+1;
                                   opt(half_imy+k, half_imx+j)=1;
                               end
                            end
                        end
                        pastY=round(y);
                    end
            end
        else
            if y2 > y1
                    for j=x2:x1
                        y=gradient*(j-x1)+y1;
                        sum_score=sum_score+person_blur(half_imy+round(y),half_imx+j);
                        sum_count=sum_count+1;
                        opt(half_imy+round(y),half_imx+j)=1;
                        
                        if j>x2
                            if abs(pastY-round(y))>sqrt(2)
                               for k=round(y):pastY
                                   sum_score=sum_score+person_blur(half_imy+k, half_imx+j);
                                   sum_count=sum_count+1;
                                   opt(half_imy+k, half_imx+j)=1;
                               end
                            end
                        end
                        pastY=round(y);
                    end
            elseif y1 > y2
                    for j=x1:x2
                        y=gradient*(j-x1)+y1;
                        sum_score=sum_score+person_blur(half_imy+round(y),half_imx+j);
                        sum_count=sum_count+1;
                        opt(half_imy+round(y),half_imx+j)=1;
                        
                        if j>x1
                            if abs(pastY-round(y))>sqrt(2)
                               for k=round(y):pastY
                                   sum_score=sum_score+person_blur(half_imy+k, half_imx+j);
                                   sum_count=sum_count+1;
                                   opt(half_imy+k, half_imx+j)=1;
                               end
                            end
                        end
                        pastY=round(y);
                    end
            else
                if x1 > x2
                    for j=x2:x1
                        y=gradient*(j-x1)+y1;
                        sum_score=sum_score+person_blur(half_imy+round(y),half_imx+j);
                        sum_count=sum_count+1;
                        opt(half_imy+round(y),half_imx+j)=1;
                    end
                else
                    for j=x1:x2
                        y=gradient*(j-x1)+y1;
                        sum_score=sum_score+person_blur(half_imy+round(y),half_imx+j);
                        sum_count=sum_count+1;
                        opt(half_imy+round(y),half_imx+j)=1;
                    end
                end
            end
        end
    end
    %----------------------------------------------------------------------
    
    if a==2
        setGlobalHead(x1, y1);
        setGlobalSpinShoulderBase(x2, y2);
    elseif a==3
        setGlobalSpinBase(x2, y2);
    elseif a==4
        setGlobalLeftHand(x2, y2);
    elseif a==5
        setGlobalRightHand(x2, y2);
    elseif a==6
        setGlobalLeftFoot(x2, y2);
    end
end


aver=sum_score / sum_count;

% 
subplot(2,2,2); imagesc(opt);colormap('gray');drawnow;
%subplot(2,3,5); imagesc(G2);colormap('gray');drawnow;

optpath  = sprintf('opt_img');
im_opt=opt;
save(optpath,'im_opt');

%F = var(var((personimage-G2)));
%F = ((abs(person_blur-opt)));
F=aver;
