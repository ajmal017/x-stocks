class ServiceRunner

  attr_reader :name
  attr_reader :lookup_code
  attr_reader :service_code
  attr_reader :schedule_code
  attr_reader :arguments
  attr_reader :proc

  def initialize(name, lookup_code, options, proc)
    @name = name
    @lookup_code = lookup_code
    @service_code = options[:service_code]
    @schedule_code = options[:schedule_code]
    @arguments = options[:arguments]
    @proc = proc
  end

  def self.all
    ALL
  end

  def self.find(lookup_code)
    all.detect {|tag| tag.lookup_code == lookup_code }
  end

  def service
    Service.find_by(key: service_code) if service_code.present?
  end

  def run(args, &block)
    proc.call(args, &block)
  end

  private

  def self.stock_message(stock)
    Etl::Refresh::Base.new.stock_message(stock)
  end

  def self.completed_message
    Etl::Refresh::Base.new.completed_message
  end

  ALL = [
      ServiceRunner.new('Update stock prices [Finnhub]', 'hourly_all_finnhub', {service_code: 'stock_prices', schedule_code: 'Hourly'},
                        ->(args, &block) do
                          Etl::Refresh::Finnhub.new.hourly_all_stocks!(force: true, &block)
                        end),

      ServiceRunner.new('Update stock prices [Finnhub]', 'hourly_one_finnhub', {service_code: 'hourly_one_finnhub', arguments: [:stock_id]},
                        ->(args, &block) do
                          stock = Stock.find_by!(id: args[:stock_id])
                          block.call stock_message(stock)
                          Service.lock(:hourly_one_finnhub, force: true) do |logger|
                            logger.text_size_limit = nil
                            Etl::Refresh::Finnhub.new.hourly_one_stock!(stock, logger: logger, &block)
                          end
                          block.call completed_message
                        end),

      ServiceRunner.new('Update stock information [Yahoo]', 'daily_all_yahoo', {service_code: 'daily_yahoo', schedule_code: 'Daily'},
                        ->(args, &block) do
                          Etl::Refresh::Yahoo.new.daily_all_stocks!(force: true, &block)
                        end),

      ServiceRunner.new('Update stock information [Yahoo]', 'daily_one_yahoo', {service_code: 'daily_one_yahoo', arguments: [:stock_id]},
                        ->(args, &block) do
                          stock = Stock.find_by!(id: args[:stock_id])
                          block.call stock_message(stock)
                          Service.lock(:daily_one_yahoo, force: true) do |logger|
                            logger.text_size_limit = nil
                            Etl::Refresh::Yahoo.new.daily_one_stock!(stock, logger: logger)
                          end
                          block.call completed_message
                        end),

      ServiceRunner.new('Update stock information [Finnhub]', 'daily_all_finnhub', {service_code: 'daily_finnhub', schedule_code: 'Daily'},
                        ->(args, &block) do
                          Etl::Refresh::Finnhub.new.daily_all_stocks!(force: true, &block)
                        end),

      ServiceRunner.new('Update stock information [Finnhub]', 'daily_one_finnhub', {service_code: 'daily_one_finnhub', arguments: [:stock_id]},
                        ->(args, &block) do
                          stock = Stock.find_by!(id: args[:stock_id])
                          block.call stock_message(stock)
                          Service.lock(:daily_one_finnhub, force: true) do |logger|
                            logger.text_size_limit = nil
                            Etl::Refresh::Finnhub.new.daily_one_stock!(stock, logger: logger)
                          end
                          block.call completed_message
                        end),

      ServiceRunner.new('Update stock dividends [IEX Cloud]', 'weekly_all_iexapis', {service_code: 'weekly_iexapis', schedule_code: 'Weekly'},
                        ->(args, &block) do
                          Etl::Refresh::Iexapis.new.weekly_all_stocks!(force: true, &block)
                        end),

      ServiceRunner.new('Update stock dividends [IEX Cloud]', 'weekly_one_iexapis', {service_code: 'weekly_one_iexapis', arguments: [:stock_id]},
                        ->(args, &block) do
                          stock = Stock.find_by!(id: args[:stock_id])
                          block.call stock_message(stock)
                          Service.lock(:weekly_one_iexapis, force: true) do |logger|
                            logger.text_size_limit = nil
                            Etl::Refresh::Iexapis.new.weekly_one_stock!(stock, logger: logger, immediate: true, &block)
                          end
                          block.call completed_message
                        end),

      ServiceRunner.new('Update stock dividends [Dividend.com]', 'weekly_all_dividend', {service_code: 'weekly_dividend', schedule_code: 'Weekly'},
                        ->(args, &block) do
                          Etl::Refresh::Dividend.new.weekly_all_stocks!(force: true, &block)
                        end),

      ServiceRunner.new('Update stock dividends [Dividend.com]', 'weekly_one_dividend', {service_code: 'weekly_one_dividend', arguments: [:stock_id]},
                        ->(args, &block) do
                          stock = Stock.find_by!(id: args[:stock_id])
                          block.call stock_message(stock)
                          Service.lock(:weekly_one_dividend, force: true) do |logger|
                            logger.text_size_limit = nil
                            Etl::Refresh::Dividend.new.weekly_one_stock!(stock, logger: logger)
                          end
                          block.call completed_message
                        end),

      ServiceRunner.new('Load company information [Finnhub] [IEX Cloud] [Yahoo]', 'company_information', {service_code: 'company_information', arguments: [:stock_id]},
                        ->(args, &block) do
                          stock = Stock.find_by!(id: args[:stock_id])
                          block.call stock_message(stock)
                          Service.lock(:company_information, force: true) do |logger|
                            logger.text_size_limit = nil
                            Etl::Refresh::Company.new.one_stock!(stock, logger: logger)
                          end
                          block.call completed_message
                        end),

      ServiceRunner.new('S&P 500, Nasdaq 100 and Dow Jones [SlickCharts]', 'slickcharts', {service_code: 'slickcharts'},
                        ->(args, &block) do
                          Etl::Refresh::Slickcharts.new.all_stocks!(&block)
                        end),

      ServiceRunner.new('Update upcoming earnings [Finnhub]', 'upcoming_earnings', {service_code: 'weekly_finnhub', schedule_code: 'Weekly'},
                        ->(args, &block) do
                          Etl::Refresh::Finnhub.new.weekly_all_stocks!(force: true, &block)
                        end),
  ].freeze

end
