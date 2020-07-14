module Etl
  module Refresh
    class Iexapis

      def weekly_last_run_at
        Config[:weekly_iexapis_updated_at]
      end

      def weekly_all_stocks?
        updated_at = daily_last_run_at
        updated_at.nil? || updated_at < 1.day.ago
      end

      def weekly_all_stocks!
        Stock.all.each do |stock|
          weekly_one_stock!(stock)
          sleep(1.0 / 30) # Limit up to 30 requests per second
        end
        Config[:weekly_iexapis_updated_at] = DateTime.now
      end

      def weekly_all_stocks
        daily_all_stocks! if daily_all_stocks?
      end

      def weekly_one_stock!(stock)
        json = Etl::Extract::Iexapis.new.dividends(stock.symbol)
        Etl::Transform::Iexapis::new.dividends(stock, json)
      end

    end
  end
end
