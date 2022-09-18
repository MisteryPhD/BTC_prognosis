%% Preparations
% Clear all: workspace, figures, command window
clear all;
close all;
clc;
 
% Load the dataset
% (btc/usd price and volume data)
btc_usd_data=dlmread('bitstampUSD.csv');
 
% Take only part of the data to work (fresher part of the data)
timestamp    = btc_usd_data(ceil(end*0.6):end,1);
price        = btc_usd_data(ceil(end*0.6):end,2);
trade_volume = btc_usd_data(ceil(end*0.6):end,3);
 
% Plot the working data
figure;
subplot(2,1,1);
plot(timestamp,price);
ylabel('BTC price (USD)');
ax = gca;
t = datetime(timestamp, 'ConvertFrom', 'epochtime', 'Epoch', 0,'Format', 'd-MMM-y'); 
ax.XTick = linspace(min(timestamp), max(timestamp), 3);
ax.XTickLabel = char(linspace(t(1), t(end), 3));
 
subplot(2,1,2);
plot(timestamp,trade_volume);
ylabel('Trade volume, BTC')
ax = gca;
t = datetime(timestamp, 'ConvertFrom', 'epochtime', 'Epoch', 0,'Format', 'd-MMM-y'); 
ax.XTick = linspace(min(timestamp), max(timestamp), 3);
ax.XTickLabel = char(linspace(t(1), t(end), 3));
 
% Extract features/classes from data
    % alpha is the price threshold that would be used
    % to distinguish the price behavior: 
    % * if the price change in more then 1+alpha times 
    %   then count it as "price rising";
    % * if the price change in less then 1-alpha times
    %   then count it as "price falling";
    % * if the price changes lies in 1-alpha to 1+alpha
    %  corridor, count it as "stagnation within alpha corridor"
alpha = 0.005;
 
% The BTC-USD data would be analyzed by days - each day is one observation
% that is characterized by features and class.
full_days_amount = floor((timestamp(end)-timestamp(1))/(24*60*60));
for k = 1:full_days_amount
    % Get the indices that correspond to the specific day (k day)
    indices_k = find( ((timestamp-timestamp(1))>=((k-1)*24*60*60)) ...
                    & ((timestamp-timestamp(1))< (   k *24*60*60)) );
    
    % To estimate the observation class it is needed to operate by the
    % next day data (to identify the price changing behavior) so
    % observations features/class would be gathered for all "full days"
    % chunks from the working data except the last full day.
    if( k < full_days_amount ) 
        % The first feature is the day price trend direction, that is 
        % given by the slope of line approximation(interpolation) of the
        % price for given day.
        % Approximation of the price as function of time for given day is
        % done using normalized price and time values
        x = (timestamp(indices_k)-timestamp(1));
        x = (x - min(x)) / (max(x)-min(x));
        X = [ones(length(x),1) x];
        price_y = price(indices_k);
        price_y = (price_y - min(price_y)) / (max(price_y)-min(price_y));        
        % (Trend is estimated using Least Square Estimator)
        price_b = (pinv(X'*X))*X'*price_y;
        
        % The first feature - this day price trend slope
        features(k,1) = price_b(2);
        
        % The second feature - normalized by mean of the price
        % standard deviation of the price (will show the "volatility")
        features(k,2) = std(price(indices_k))/mean(price(indices_k));
        
        % The extra features:
        features(k,3) = std(trade_volume(indices_k))/mean(trade_volume(indices_k));
        features(k,4) = price_b(1);
        
    end
    
    % Estimate the mean of the given day price to compare it with mean
    % price for the next day and classify the given day (observation) in
    % terms of price changing
    mean_price = mean(price(indices_k));
    
    % May provide a classification only in case of accumulated mean prices
    % for two days (here it will classify the previous day based on the mean 
    % prices for the previous day accumulated in "mean_price_previous" and
    % the mean price for the give day accumulated in mean_price).
    if( k > 1 )
        if( (mean_price/mean_price_previous) >= (1+alpha))
            classification(k-1) = 1;      % Price rising
        else
            if( (mean_price/mean_price_previous) < (1-alpha))
                classification(k-1) = 2;  % Price fallling
            else
                classification(k-1) = 3;  % Price stagnation
            end
        end
    end
    
    % Save the given day mean price to be used for classification as was
    % mentioned above.
    mean_price_previous = mean_price;
end
 
% Visualize "features extraction process"
k_rising =[137 138];
k_falling=[146 147];
k_stagnation=[163 164];
for k = [k_rising k_falling k_stagnation]
    % Visualize "features extraction process"
    % Get the indices that correspond to the specific day (k day)
    indices_k = find( ((timestamp-timestamp(1))>=((k-1)*24*60*60)) ...
                    & ((timestamp-timestamp(1))< (   k *24*60*60)) );
    % ...and the next to it day.
    indices_k_next = find( ((timestamp-timestamp(1))>=( k   *24*60*60)) ...
                         & ((timestamp-timestamp(1))< ((k+1)*24*60*60)) );
 
    % The first feature is the day price trend direction, that is 
    % given by the slope of line approximation(interpolation) of the
    % price for given day.
    % Approximation of the price as function of time for given day is
    % done using normalized price and time values
    x = (timestamp(indices_k)-timestamp(1));
    x = (x - min(x)) / (max(x)-min(x));
    X = [ones(length(x),1) x];
    price_y = price(indices_k);
    price_y = (price_y - min(price_y)) / (max(price_y)-min(price_y));        
    % (Trend is estimated using Least Square Estimator)
    price_b = (pinv(X'*X))*X'*price_y;
 
    % The first feature - this day price trend slope
    features_example(1) = price_b(2);
 
    % The second feature - normalized by mean of the price
    % standard deviation of the price (will show the "volatility")
    features_example(2) = std(price(indices_k))/mean(price(indices_k));
 
    % The extra features:
    features_example(3) = std(trade_volume(indices_k))/mean(trade_volume(indices_k));
    features_example(4) = price_b(1);
 
    % Estimate the mean of the given day price to compare it with mean
    % price for the next day and classify the given day (observation) in
    % terms of price changing
    mean_price = mean(price(indices_k));
    mean_price_next = mean(price(indices_k_next));
    % May provide a classification only in case of accumulated mean prices
    % for two days (here it will classify the previous day based on the mean 
    % prices for the previous day accumulated in "mean_price_previous" and
    % the mean price for the give day accumulated in mean_price).
    if( (mean_price_next/mean_price) >= (1+alpha))
        classification_example = 1;      % Price rising
    else
        if( (mean_price_next/mean_price) < (1-alpha))
            classification_example = 2;  % Price fallling
        else
            classification_example = 3;  % Price stagnation
        end
    end
 
    fig=figure;
    subplot(2,2,1);
    plot(timestamp(indices_k),price(indices_k));
    ylabel('BTC price (USD)');
    ylim([min(price([indices_k' indices_k_next'])) max(price([indices_k' indices_k_next']))])
    ax = gca;
    t = datetime(timestamp(indices_k), 'ConvertFrom', 'epochtime', 'Epoch', 0); 
    ax.XTick = linspace(min(timestamp(indices_k)), max(timestamp(indices_k)), 2);
    ax.XTickLabel = char(linspace(t(1), t(end), 2));
    title('Processing day');
    text(min(timestamp(indices_k))+0.02*(max(timestamp(indices_k))-min(timestamp(indices_k))),...
         min(price([indices_k' indices_k_next']))+    0.9*(max(price([indices_k' indices_k_next']))-min(price([indices_k' indices_k_next']))),...
                   strcat('feature 1 [',num2str(features_example(1)),']'),...
                           'Color','r','FontName','FixedWidth','FontSize',10,'FontWeight','bold' );
    text(min(timestamp(indices_k))+0.02*(max(timestamp(indices_k))-min(timestamp(indices_k))),...
         min(price([indices_k' indices_k_next']))+    0.8*(max(price([indices_k' indices_k_next']))-min(price([indices_k' indices_k_next']))),...
                   strcat('feature 2 [',num2str(features_example(2)),']'),...
                           'Color','r','FontName','FixedWidth','FontSize',10,'FontWeight','bold' );
    text(min(timestamp(indices_k))+0.02*(max(timestamp(indices_k))-min(timestamp(indices_k))),...
         min(price([indices_k' indices_k_next']))+    0.6*(max(price([indices_k' indices_k_next']))-min(price([indices_k' indices_k_next']))),...
                   strcat('feature 3 [',num2str(features_example(3)),']'),...
                           'Color','r','FontName','FixedWidth','FontSize',10,'FontWeight','bold' );   
    text(min(timestamp(indices_k))+0.02*(max(timestamp(indices_k))-min(timestamp(indices_k))),...
         min(price([indices_k' indices_k_next']))+    0.7*(max(price([indices_k' indices_k_next']))-min(price([indices_k' indices_k_next']))),...
                   strcat('feature 4 [',num2str(features_example(4)),']'),...
                           'Color','r','FontName','FixedWidth','FontSize',10,'FontWeight','bold' );
 
    text(min(timestamp(indices_k))+0.5*(max(timestamp(indices_k))-min(timestamp(indices_k))),...
         min(price([indices_k' indices_k_next']))+    0.2*(max(price([indices_k' indices_k_next']))-min(price([indices_k' indices_k_next']))),...
                   strcat('mean     [',num2str(mean(price(indices_k))),']'),...
                           'Color','g','FontName','FixedWidth','FontSize',10,'FontWeight','bold' );
    text(min(timestamp(indices_k))+0.5*(max(timestamp(indices_k))-min(timestamp(indices_k))),...
         min(price([indices_k' indices_k_next']))+    0.12*(max(price([indices_k' indices_k_next']))-min(price([indices_k' indices_k_next']))),...
                   strcat('std      [',num2str(std(price(indices_k))),']'),...
                           'Color','g','FontName','FixedWidth','FontSize',10,'FontWeight','bold' );           
    text(min(timestamp(indices_k))+0.5*(max(timestamp(indices_k))-min(timestamp(indices_k))),...
         min(price([indices_k' indices_k_next']))+    0.04*(max(price([indices_k' indices_k_next']))-min(price([indices_k' indices_k_next']))),...
                   strcat('std/mean [',num2str(std(price(indices_k))/mean(price(indices_k))),']'),...
                           'Color','r','FontName','FixedWidth','FontSize',10,'FontWeight','bold' ); 
 
    subplot(2,2,2);
    plot(timestamp(indices_k_next),price(indices_k_next));
    ylabel('BTC price (USD)');
    ylim([min(price([indices_k' indices_k_next'])) max(price([indices_k' indices_k_next']))])
    ax = gca;
    t = datetime(timestamp(indices_k_next), 'ConvertFrom', 'epochtime', 'Epoch', 0); 
    ax.XTick = linspace(min(timestamp(indices_k_next)), max(timestamp(indices_k_next)), 2);
    ax.XTickLabel = char(linspace(t(1), t(end), 2));
    title('Next after the processing day');
    text(min(timestamp(indices_k_next))+0.5*(max(timestamp(indices_k_next))-min(timestamp(indices_k_next))),...
         min(price([indices_k' indices_k_next']))+    0.12*(max(price([indices_k' indices_k_next']))-min(price([indices_k' indices_k_next']))),...
                   strcat('mean            [',num2str(mean(price(indices_k_next))),']'),...
                           'Color','g','FontName','FixedWidth','FontSize',10,'FontWeight','bold' );
    text(min(timestamp(indices_k_next))+0.5*(max(timestamp(indices_k_next))-min(timestamp(indices_k_next))),...
         min(price([indices_k' indices_k_next']))+    0.04*(max(price([indices_k' indices_k_next']))-min(price([indices_k' indices_k_next']))),...
                   strcat('mean/mean(day-1)[',num2str(mean(price(indices_k_next))/mean(price(indices_k))),']'),...
                           'Color','k','FontName','FixedWidth','FontSize',10,'FontWeight','bold' );
    subplot(2,2,3);
    hold on;
    plot(x,price_y);
    plot(x,X*price_b,'r');
    ylabel('normalized BTC price');
    xlabel('normalized time');
    legend({'data','linear fit'});
    text(0.02, 0.7, strcat('Intercept: [',num2str(price_b(1)),']'),...
        'Color','r','FontName','FixedWidth','FontSize',10,'FontWeight','bold' );
    text(0.02, 0.6, strcat('Slope:     [',num2str(price_b(2)),']'),...
        'Color','r','FontName','FixedWidth','FontSize',10,'FontWeight','bold' );
 
    subplot(2,2,4);
    plot(timestamp(indices_k),trade_volume(indices_k));
    ylabel('Trade volume, BTC')
    ax = gca;
    t = datetime(timestamp(indices_k), 'ConvertFrom', 'epochtime', 'Epoch', 0); 
    ax.XTick = linspace(min(timestamp(indices_k)), max(timestamp(indices_k)), 2);
    ax.XTickLabel = char(linspace(t(1), t(end), 2));
 
    text(min(timestamp(indices_k))+0.02*(max(timestamp(indices_k))-min(timestamp(indices_k))),...
         min(trade_volume(indices_k))+    0.9*(max(trade_volume(indices_k))-min(trade_volume(indices_k))),...
                   strcat('mean     [',num2str(mean(trade_volume(indices_k))),']'),...
                           'Color','g','FontName','FixedWidth','FontSize',10,'FontWeight','bold' );
    text(min(timestamp(indices_k))+0.02*(max(timestamp(indices_k))-min(timestamp(indices_k))),...
         min(trade_volume(indices_k))+    0.8*(max(trade_volume(indices_k))-min(trade_volume(indices_k))),...
                   strcat('std      [',num2str(std(trade_volume(indices_k))),']'),...
                           'Color','g','FontName','FixedWidth','FontSize',10,'FontWeight','bold' );           
    text(min(timestamp(indices_k))+0.02*(max(timestamp(indices_k))-min(timestamp(indices_k))),...
         min(trade_volume(indices_k))+    0.7*(max(trade_volume(indices_k))-min(trade_volume(indices_k))),...
                   strcat('std/mean [',num2str(std(trade_volume(indices_k))/mean(trade_volume(indices_k))),']'),...
                           'Color','r','FontName','FixedWidth','FontSize',10,'FontWeight','bold' );
    
    % Place the classification result                   
    ah=gca;
    axes('position',[0,0,1,1],'visible','off');
    if(classification_example==1)
        text(.45,.5,'Rising',...
        'Color','r','FontName','FixedWidth','FontSize',15,'FontWeight','bold' );
    else
        if(classification_example==2)
             text(.45,.5,'Falling',...
        'Color','r','FontName','FixedWidth','FontSize',15,'FontWeight','bold' );
        else
             text(.45,.5,'Stagnation',...
        'Color','r','FontName','FixedWidth','FontSize',15,'FontWeight','bold' );
        end
    end
    axes(ah);
end
 
%% Present observations (features/classification)
% Define colors for different classes
colors = lines(size(unique(classification),2));
 
% Define the figure, where observations would be shown 
figure;
    % On the first subplot - only the first class observation would be
    % shown
subplot(2,2,1)
scatter(features(find(classification==1),1),features(find(classification==1),2),...
                             12,colors(classification(find(classification==1)),:),'filled');
title('Price rising');
xlim([min(features(:,1)) max(features(:,1))]);
ylim([min(features(:,2)) max(features(:,2))]);
xlabel('Trend slope');
ylabel('Price deviation');
             
    % On the second subplot - only the second class observation would be
    % shown
subplot(2,2,2)
scatter(features(find(classification==2),1),features(find(classification==2),2),...
                             12,colors(classification(find(classification==2)),:),'filled');
title('Price falling');
xlim([min(features(:,1)) max(features(:,1))]);
ylim([min(features(:,2)) max(features(:,2))]);
xlabel('Trend slope');
ylabel('Price deviation');
 
    % On the third subplot - only the third class observation would be
    % shown
subplot(2,2,3)
scatter(features(find(classification==3),1),features(find(classification==3),2),...
                             12,colors(classification(find(classification==3)),:),'filled');
title(strcat('Price stagnation (~',num2str(alpha*100),'%)'));
xlim([min(features(:,1)) max(features(:,1))]);
ylim([min(features(:,2)) max(features(:,2))]);
xlabel('Trend slope');
ylabel('Price deviation');
                
    % On the fourth subplot - all observations would be shown
subplot(2,2,4)
scatter(features(:,1),features(:,2),12,colors(classification,:),'filled');
title('All in once');
xlim([min(features(:,1)) max(features(:,1))]);
ylim([min(features(:,2)) max(features(:,2))]);
xlabel('Trend slope');
ylabel('Price deviation');
 
%% Build the classifier (SVM)
 
% At first, will use only the first two features and check the result.
t = templateSVM('Standardize',1,'KernelFunction','gaussian');
SVM = fitcecoc(features(:,[1 2]),classification,'Learners',t,'FitPosterior',1);
    % Estimate the quality of SVM training using 10-fold cross-validation
    % technique.
SVM_cross_val = crossval(SVM);
SVM_cross_val_error = kfoldLoss(SVM_cross_val);
fprintf(1,'The error of SVM training using the first two features: %f\n',...
                                                      SVM_cross_val_error);
    % Plot the posterior probabilities 
    %(another training quality metric)
xMax = max(features(:,[1 2]));
xMin = min(features(:,[1 2]));
 
x1Pts = linspace(xMin(1),xMax(1));
x2Pts = linspace(xMin(2),xMax(2));
[x1Grid,x2Grid] = meshgrid(x1Pts,x2Pts);
 
[~,~,~,PosteriorRegion] = predict(SVM,[x1Grid(:),x2Grid(:)]);
 
figure;
contourf(x1Grid,x2Grid,...
        reshape(max(PosteriorRegion,[],2),size(x1Grid,1),size(x1Grid,2)));
h = colorbar;
h.YLabel.String = 'Maximum posterior';
h.YLabel.FontSize = 15;
hold on
gh = gscatter(features(:,1),features(:,2),classification,'krk','*xd',8);
gh(2).LineWidth = 2;
gh(3).LineWidth = 2;
 
title('Observations and Maximum Posterior');
xlabel('Trend slope');
ylabel('Price deviation');
axis tight
legend({'Posterior probability','price rising','price falling','price stagnation'},'Location','NorthWest');
hold off
 
% Finally, will use all features and check the result.
SVM_all = fitcecoc(features,classification,'Learners',t,'FitPosterior',1);
    % Estimate the quality of SVM training using 10-fold cross-validation
    % technique.
SVM_all_cross_val = crossval(SVM_all);
SVM_all_cross_val_error = kfoldLoss(SVM_all_cross_val);
fprintf(1,'The error of SVM training using all features: %f\n',...
                                                  SVM_all_cross_val_error);


