k_rising =[137 138];
k_falling=[146 147];
k_stagnation=[163 164];
for k =1 %[k_rising k_falling k_stagnation]
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
    % done using normlized price and time values
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
    mean_price_next = mean(price(indices_k));
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