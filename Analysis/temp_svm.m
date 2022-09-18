t = templateSVM('Standardize',1,'KernelFunction','gaussian');

X=features(:,[1 2]);
Y=classification;

Mdl = fitcecoc(X,Y,'Learners',t,'FitPosterior',1);

xMax = max(X);
xMin = min(X);

x1Pts = linspace(xMin(1),xMax(1));
x2Pts = linspace(xMin(2),xMax(2));
[x1Grid,x2Grid] = meshgrid(x1Pts,x2Pts);

[~,~,~,PosteriorRegion] = predict(Mdl,[x1Grid(:),x2Grid(:)]);

figure;
contourf(x1Grid,x2Grid,...
        reshape(max(PosteriorRegion,[],2),size(x1Grid,1),size(x1Grid,2)));
h = colorbar;
h.YLabel.String = 'Maximum posterior';
h.YLabel.FontSize = 15;
hold on
gh = gscatter(X(:,1),X(:,2),Y,'krk','*xd',8);
gh(2).LineWidth = 2;
gh(3).LineWidth = 2;

title 'Observations and Maximum Posterior';
xlabel 'feature 1';
ylabel 'feature 2';
axis tight
legend(gh,'Location','NorthWest')
hold off


%CVMdl = crossval(Mdl);

%oosLoss = kfoldLoss(CVMdl)

%Mdl = fitcsvm(features(:,1:end),classification);
%CVSVMModel = crossval(Mdl);
%kfoldLoss(CVSVMModel)