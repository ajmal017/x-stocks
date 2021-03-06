class ServicesController < ApplicationController
  include ActionController::Live

  def index
    @service_runners = ServiceRunner.all
    @stocks = Stock.all

    @page_title = 'Services'
    @page_menu_item = :services
  end

  def run_one
    find_service_runner do |service_runner|
      EventStream.run(response) do |stream|
        service_runner.run(params) do |status|
          stream.write(status)
        end
      end
    end
  end

  def log
    find_service_runner do |service_runner|
      send_data(service_runner.service&.log, filename: 'service-log.txt', type: 'text/plain')
    end
  end

  def error
    find_service_runner do |service_runner|
      send_data(service_runner.service&.error, filename: 'service-error.txt', type: 'text/plain')
    end
  end

  def run_all
    EventStream.run(response) do |stream|

      if Service.locked?
        # Just wait

      elsif Etl::Refresh::Finnhub.new.hourly_all_stocks?
        Etl::Refresh::Finnhub.new.hourly_all_stocks { |status| stream.write(status) }

      else
        Etl::Refresh::Yahoo.new.daily_all_stocks { |status| stream.write(status) }
        Etl::Refresh::Finnhub.new.daily_all_stocks { |status| stream.write(status) }
        Etl::Refresh::Iexapis.new.weekly_all_stocks { |status| stream.write(status) }
        Etl::Refresh::Dividend.new.weekly_all_stocks { |status| stream.write(status) }
        Etl::Refresh::Finnhub.new.weekly_all_stocks { |status| stream.write(status) }

      end
    end
  end

  private

  def find_service_runner
    service = ServiceRunner.find(params[:id])
    if service
      yield service
    else
      flash[:notice] = "Invalid service"
      redirect_to action: 'index'
    end
  end
end
