load_data;

ker = 'rbf';

bestcv =0;
best_C =0;
best_g =0;

%figure, imshow(mat2gray(K));

for log2g = -2:1:2,
    K = computeKgm(train,ker,2^log2g);    
    
    for C = 0.008:0.005:0.06
    [svi, alpha,c] = svdd_train(train,K,ker,C,2^log2g); 
    [pred_val] = svdd_predict(train,val,ker,alpha,svi,c,2^log2g);
    ac = sum(target_val == pred_val)/size(target_val,1);
    ac
    if (ac >= bestcv),
          bestcv = ac; best_C = C; best_g = 2^log2g; 
    end
    fprintf('C=%g log2g=%g acc=%g (best C=%g, g=%g, acc=%g) \n', C, log2g, ac, best_C, best_g, bestcv);
    end
end


K = computeKgm(train,ker,best_g);
[svi, alpha,c] = svdd_train(train,K,ker,best_C,best_g);

[pred_train] = svdd_predict(train,train,ker,alpha,svi,c,best_g);
[pred_val] = svdd_predict(train,val,ker,alpha,svi,c,best_g);
[pred_test] =svdd_predict(train,test,ker,alpha,svi,c,best_g);

fprintf('Train confusion matrix')
[C_train,order1] = confusionmat(target_train,pred_train);
C_train

fprintf('Train accuracy %g  \n',sum(target_train == pred_train)/size(target_train,1));
fprintf('Validation confusion matrix')
[C_val,order2] = confusionmat(target_val,pred_val);
C_val

fprintf('Val accuracy %g  \n',sum(target_val == pred_val)/size(target_val,1));
fprintf('Test confusion matrix')
[C_test,order3] = confusionmat(target_test,pred_test);

C_test
fprintf('Test accuracy %g  \n',sum(target_test == pred_test)/size(target_test,1));


% Decn. region.

xrange = [-6 12];
yrange = [-6 12];

inc = 0.1;
[x, y] = meshgrid(xrange(1):inc:xrange(2), yrange(1):inc:yrange(2)); 
image_size = size(x); 
xy = [x(:) y(:)]; % make (x,y) pairs as a bunch of row vectors.

%Scale xy
for i=1:size(xy,2)
    xy(:,i) = (xy(:,i)-min_coord(i))/(max_coord(i)-min_coord(i));
end

pred = svdd_predict(train,xy,ker,alpha,svi,c,best_g);


figure;
decisionmap = reshape(pred, image_size);
imagesc(xrange,yrange,decisionmap);
hold on;
set(gca,'ydir','normal');
cmap = [1 0.8 0.8; 0.95 1 0.95; 0.9 0.9 1; 0.6 0.7 1];
colormap(cmap);


plot(train_unscaled(:,1),train_unscaled(:,2),'b.');

a = xlabel('$x_1$');
b = ylabel('$x_2$');
set(a,'Interpreter','latex');
set(b,'Interpreter','latex');
title('Decision region plot showing boundary between normal and abnormal classes');


epsilon = svtol(best_C);
%epsilon = 10^-4;

svii = find( alpha > epsilon & alpha < (best_C - epsilon));
hold on;
plot(train_unscaled(svii,1),train_unscaled(svii,2),'k.');

svi_bdd = find(alpha > best_C-epsilon & alpha < best_C+epsilon);
plot(train_unscaled(svi_bdd,1),train_unscaled(svi_bdd,2),'g.');
hold on;
plot(x_hat(1),x_hat(2),'r.');
%svi_bdd