module Etl
  module Transform
    class Finnhub < Base

      def company(stock, json)
        return if json.blank?

        stock.ipo = json['ipo']
        stock.logo = json['logo']
        stock.exchange ||= Exchange.find_by(finnhub_code: json['exchange']) if json['exchange'].present?

        stock.save
      end

      def peers(stock, json)
        return if json.blank?

        stock.peers = json
      end

      def quote(stock, json)
        return if json.blank?

        stock.current_price = json['c']
        stock.prev_close_price = json['pc']
        stock.open_price = json['o']
        stock.day_low_price = json['l']
        stock.day_high_price = json['h']

        stock.update_prices!
      end

      def recommendation(stock, json)
        json ||= []

        json.sort_by! { |row| Date.parse(row['period']) }
        json = json[-4..-1] if json.size > 4

        hash = {}
        json.each do |row|
          hash[Date.parse(row['period'])] = [
            row['strongBuy'],
            row['buy'],
            row['hold'],
            row['sell'],
            row['strongSell']
          ]
        end

        stock.finnhub_rec_details = hash
        stock.finnhub_rec = recommendation_mean(stock.finnhub_rec_details)
        stock.save
      end

      def price_target(stock, json)
        stock.finnhub_price_target =
          if json.present? &&
              json['targetHigh'] > 0 && json['targetLow'] > 0 &&
              json['targetMean'] > 0 && json['targetMedian'] > 0
            {
              high: json['targetHigh'],
              low: json['targetLow'],
              mean: json['targetMean'],
              median: json['targetMedian'],
            }
          else
            nil
          end

        stock.save
      end

      def earnings(stock, json)
        stock.earnings =
          if json.present?
            json.map do |row|
              row.delete('symbol')
              row['estimate'] = row['estimate'].round(4) if row['estimate']
              row
            end
          else
            nil
          end

        stock.save
      end

      def metric(stock, json)
        json ||= {}
        data = json['metric'] || {}
        stock.finnhub_beta = data['beta']
        stock.week_52_high = data['52WeekHigh']
        stock.week_52_high_date = data['52WeekHighDate']
        stock.week_52_low = data['52WeekLow']
        stock.week_52_low_date = data['52WeekLowDate']
        stock.dividend_growth_5y = data['dividendGrowthRate5Y']
        stock.eps_growth_3y = data['epsGrowth3Y']
        stock.eps_growth_5y = data['epsGrowth5Y']
        stock.eps_ttm = data['epsInclExtraItemsTTM']
        stock.pe_ratio_ttm = data['peInclExtraTTM']
      end

      def earnings_calendar(json, stock = nil)
        json ||= []
        (json['earningsCalendar'] || []).each do |row|
          next if stock && stock.symbol != row['symbol']

          stock = Stock.find_by(symbol: row['symbol'])
          next unless stock

          date = Date.parse(row['date'])
          if stock.next_earnings_date.nil? ||
              (date.future? && stock.next_earnings_date >= date)
            stock.next_earnings_date = date
            stock.next_earnings_hour = row['hour']
            stock.next_earnings_est_eps = row['epsEstimate']
          end

          details = (stock.next_earnings_details ||= [])
          details.reject! { |d| d['date'] == row['date'] }

          details << {
              date: row['date'],
              hour: row['hour'],
              eps_estimate: row['epsEstimate'],
              eps_actual: row['epsActual'],
              revenue_estimate: row['revenueEstimate'],
              revenue_actual: row['revenueActual'],
              quarter: row['quarter'],
              year: row['year'],
          }

          stock.save!
        end
      end

      private

      def recommendation_mean(rec_details)
        return nil if rec_details.blank?

        value = total = 0
        rec_details.each do |_, data|
          value += 1 * data[0] + 2 * data[1] + 3 * data[2] + 4 * data[3] + 5 * data[4]
          total += data[0] + data[1] + data[2] + data[3] + data[4]
        end

        value.to_f / total
      end

    end
  end
end
