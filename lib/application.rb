require 'sinatra'
require 'pry'
require 'json'

require_relative 'seo_report'

REPORT_STORAGE_DIRECTORY = File.join(File.dirname(__FILE__), "public/reports")

class Application < Sinatra::Base
  set :app_file, __FILE__
  configure { set :server, :puma }


  # Root path
  get '/' do
    erb :index
  end

  post '/seo-report' do
    content_type :json

    @report = SeoReport.new(report_params)
    @report.process! if @report.valid?

    if @report.processed?
      status 200

      File.open(File.join(REPORT_STORAGE_DIRECTORY, @report.report_filename), 'w') { |file| file.puts @report.body }

      { report: erb(:report, locals: { report: @report }, layout: false) }.to_json
    else
      status 422

      { errors: @report.errors }.to_json
    end
  end

  private

  def report_params
    params.select { |attribute, _| SeoReport::REQUIRED_ATTRIBUTES.include?(attribute.to_sym) }.
      inject(Hash.new) { |memo, (key, value)| memo[key.to_sym] = value; memo } # turn string keys to sym keys
  end
end
