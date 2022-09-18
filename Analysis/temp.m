close all;

alpha = 0.005;
full_days_amount = floor((timestamp(end)-timestamp(1))/(24*60*60));
for k = 1:full_days_amount
    indices_k = find( ((timestamp-timestamp(1))>=((k-1)*24*60*60)) & ((timestamp-timestamp(1))<(k*24*60*60)) );
    
    if(k<full_days_amount)
        
        x = (timestamp(indices_k)-timestamp(1));
        x = (x - min(x)) / (max(x)-min(x));
        X = [ones(length(x),1) x];
        price_y = price(indices_k);
        price_y = (price_y - min(price_y)) / (max(price_y)-min(price_y));
        price_b = (pinv(X'*X))*X'*price_y;
        
        features(k,1) = price_b(2);        
        features(k,2) = std(price(indices_k))/mean(price(indices_k));
        features(k,3) = std(trade_volume(indices_k))/mean(trade_volume(indices_k));
    
    end
    
    mean_price = mean(price(indices_k));
    
    if(k>1)
        if( (mean_price/mean_price_previous) >= (1+alpha))
            classification(k-1) = 1;
        else
            if( (mean_price/mean_price_previous) < (1-alpha))
                classification(k-1) = 2;
            else
                classification(k-1) = 3;
            end
        end
    end
    
    mean_price_previous = mean_price;
end

colors = lines(size(unique(classification),2));

figure;
subplot(2,2,1)
scatter(features(find(classification==1),1),features(find(classification==1),2),...
                             12,colors(classification(find(classification==1)),:),'filled');
title('Price rising');
xlim([min(features(:,1)) max(features(:,1))]);
ylim([min(features(:,2)) max(features(:,2))]);
                             
subplot(2,2,2)
scatter(features(find(classification==2),1),features(find(classification==2),2),...
                             12,colors(classification(find(classification==2)),:),'filled');
title('Price falling');
xlim([min(features(:,1)) max(features(:,1))]);
ylim([min(features(:,2)) max(features(:,2))]);

subplot(2,2,3)
scatter(features(find(classification==3),1),features(find(classification==3),2),...
                             12,colors(classification(find(classification==3)),:),'filled');
title(strcat('Price stable (~',num2str(alpha*100),'%)'));
xlim([min(features(:,1)) max(features(:,1))]);
ylim([min(features(:,2)) max(features(:,2))]);
                             
subplot(2,2,4)
scatter(features(:,1),features(:,2),12,colors(classification,:),'filled');
title('All in once');
xlim([min(features(:,1)) max(features(:,1))]);
ylim([min(features(:,2)) max(features(:,2))]);


