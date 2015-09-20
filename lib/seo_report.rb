require 'json'
require 'pry'
require 'timeout'
require 'nokogiri'
require 'mechanize'
require 'resolv'

class SeoReport
  REQUIRED_ATTRIBUTES = %i(url)
  TIMEOUT = 30              # 30 seconds

  UNKNOWN_STATUS = :unknown # Status not set
  SUCCESS_STATUS = :success # Succesfully parsed
  ERROR_STATUS   = :error   # Failed to open page

  attr_reader :url, :status, :body, :errors, :created_at

  def initialize(params)
    @url = params[:url]

    @status    = UNKNOWN_STATUS # parsing status, either one of UNKNOWN_STATUS, SUCCESS_STATUS, ERROR_STATUS
    @body      = nil            # actual report body
    @errors    = {}

    @created_at = Time.now

    parse_url!
  end

  def report_filename
    "#{@created_at.strftime('%F_%X')}_#{@uri.hostname}.json"
  end

  def process!
    begin
      Timeout.timeout(TIMEOUT) do
        _agent = Mechanize.new
        _agent.get(@url)

        @body = {
          title: _agent.page.title,
          links: _agent.page.links.map(&:href),
          headers: _agent.page.response
        }

        @body.tap { |_body| _body[:ip_address] = Resolv.getaddress(@uri.hostname) }
        @status = SUCCESS_STATUS
      end
    rescue SocketError
      set_error :socket_error, 'Socket Error. Invalid URL?'
    rescue TimeoutError
      set_error :timeout_error, "Request took longer then #{TIMEOUT} seconds"
    rescue Mechanize::ResponseCodeError => exception
      set_error :response_code_error, "Failed to open URL: #{exception.response_code}"
    rescue Resolv::ResolvError
      set_error :resolv, "No address for #{Resolv.getaddress(@uri.hostname)}"
    end
  end

  def processed?
    valid? and [ SUCCESS_STATUS, ERROR_STATUS ].include?(@status)
  end

  def success?
    @status == SUCCESS_STATUS
  end

  def error?
    @status == ERROR_STATUS
  end

  def valid?
    errors.none?
  end

  private

  def parse_url!
    @uri = URI.parse(@url)

    unless @uri.kind_of?(URI::HTTP) or @uri.kind_of?(URI::HTTPS)
      errors[:url] = "Invalid url"
    end
  rescue URI::InvalidURIError
    errors[:url] = "Invalid url"
  end

  def set_error key, value
    errors[key] = value
    @status = ERROR_STATUS
  end
end
