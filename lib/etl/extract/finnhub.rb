module Etl
  module Extract
    class Finnhub < Base

      BASE_URL = 'https://finnhub.io/api/v1'
      FINNHUB_KEY = ENV['FINNHUB_KEY']

      def company(symbol)
        get_json(company_url(symbol))
      end

      def peers(symbol)
        get_json(peers_url(symbol))
      end

      def quote(symbol)
        get_json(quote_url(symbol))
      end

      def recommendation(symbol)
        get_json(recommendation_url(symbol))
      end

      def price_target(symbol)
        get_json(price_target_url(symbol))
      end

      def earnings(symbol)
        get_json(earnings_url(symbol))
      end

      def metric(symbol)
        get_json(metric_url(symbol))
      end

      private

      def company_url(symbol)
        "#{BASE_URL}/stock/profile2?symbol=#{esc(symbol)}&token=#{FINNHUB_KEY}"
      end

      def peers_url(symbol)
        "#{BASE_URL}/stock/peers?symbol=#{esc(symbol)}&token=#{FINNHUB_KEY}"
      end

      def quote_url(symbol)
        "#{BASE_URL}/quote?symbol=#{esc(symbol)}&token=#{FINNHUB_KEY}"
      end

      def recommendation_url(symbol)
        "#{BASE_URL}/stock/recommendation?symbol=#{esc(symbol)}&token=#{FINNHUB_KEY}"
      end

      def price_target_url(symbol)
        "#{BASE_URL}/stock/price-target?symbol=#{esc(symbol)}&token=#{FINNHUB_KEY}"
      end

      def earnings_url(symbol)
        "#{BASE_URL}/stock/earnings?symbol=#{esc(symbol)}&token=#{FINNHUB_KEY}"
      end

      def metric_url(symbol)
        "#{BASE_URL}/stock/metric?symbol=#{esc(symbol)}&metric=all&token=#{FINNHUB_KEY}"
      end

    end
  end
end
