clc;
clear all;
close all;
q=1;
w=1;
row=1;
column=1;
a=imread('gs.bmp');
b=double(zeros(8,8,4096));
c=double(zeros(8,8,4096));
for k=1:4096
 for i=row:(row+7)
 for j=column:(column+7)
 b(q,w,k)=a(i,j);
 w=w+1;
 if(w==9)
 w=1;
 end
 end
 q=q+1;
 if(q==9)
 q=1;
 end
 end
 row=i+1;
 if(row==513)
 row=1;
 column=j+1;
 end
end
figure, imshow(a);
b=b-128;
for k=1:4096
 c(:,:,k)=dct2(b(:,:,k));
end
s1=double(zeros(512,512));
row=1;
q=1;
w=1;
column=1;
for k=1:4096
 for i=row:(row+7)
 for j=column:(column+7)
 s1(i,j)=c(q,w,k);
 w=w+1;
 if(w==9)
 w=1;
 end
 end
 q=q+1;
 if(q==9)
q=1;
 end
 end
 row=i+1;
 if(row==513)
 row=1;
 column=j+1;
 end
end
figure,imshow(s1);
m=[16 11 10 16 24 40 51 61; 12 12 14 19 26 58 60 55; 14 13 16 24 40 57 69
56; 14 17 22 29 51 87 80 62; 18 22 37 56 68 109 103 77; 24 35 55 64 81 104
113 92; 49 64 78 87 103 121 120 101; 72 92 95 98 112 100 103 99];
m=double(m);
d=double(zeros(8,8,4096));
d=double(c);
for k=1:4096
 d(:,:,k)=round(c(:,:,k)./m);
end
c=d;
e=d;
for k=1:4096
 e(:,:,k)=round(d(:,:,k).*m);
end
f=double(zeros(8,8,4096));
for k=1:4096
 f(:,:,k)=idct2(e(:,:,k));
end
f=f+128;
s2=double(zeros(512,512));
row=1;
q=1;
w=1;
column=1;
for k=1:4096
 for i=row:(row+7)
 for j=column:(column+7)
 s2(i,j)=round(f(q,w,k));
 w=w+1;
 if(w==9)
 w=1;
 end
 end
 q=q+1;
 if(q==9)
 q=1;
 end
 end
 row=i+1;
 if(row==513)
 row=1;
 column=j+1;
end
end
figure,imshow(s2);
s3=double(zeros(512,512));
s3=s2+128;
s3=uint8(s3);
figure, imshow(s3);
figure, imshow(s3-a);