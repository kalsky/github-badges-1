require 'sinatra'
require 'haml'
require 'json'
require 'net/http'
require 'cgi'

user = nil
repo = nil

get '/' do
  haml :index
end

get '/list' do
  list = ''
  Dir['cache/*'].each {|file| list += file + '<br />'}

  list
end

[:state, :milestone].each do |type|
  get "/#{type}.svg" do
    if params[:user]
      if params[:repo]
        user     = params[:user]
        repo     = params[:repo]
        style    = params[:style] ? params[:style] : 'default'
        bg_color = params[:background] ? params[:background] : '4c1' # default bg color to green
        color    = params[:color] ? params[:color] : 'fff' # default text color to white
        issue    = params[:issue]
        if params[:auth]
          auth     = params[:auth]
        else
          auth     = ""
        end

        case type
          when :state
            count = fetch("https://api.github.com/repos/#{user}/#{repo}/issues/#{issue}", 'state', {user: user, repo: repo, auth: auth, issue: issue})
            count_url = "https://github.com/repos/#{user}/#{repo}/issues/#{issue}"
            button_url = "https://github.com/repos/#{user}/#{repo}/issues/#{issue}"
          when :milestone
            count = fetch("https://api.github.com/repos/#{user}/#{repo}/issues/#{issue}", 'milestone.title', {user: user, repo: repo, auth: auth, issue: issue})
            count_url = "https://github.com/#{user}/#{repo}/issues/#{issue}"
            button_url = "https://github.com/#{user}/#{repo}/issues/#{issue}"
        end

        # everything is ok.
        content_type 'image/svg+xml'

        # Avoid CDN caching
        now = CGI::rfc1123_date(Time.now)
        response.headers['Cache-Control'] = 'no-cache,no-store,must-revalidate,max-age=0'
        response.headers["Date"] = now
        response.headers["Expires"] = now

        return create_button({
           :button_text => type,
           :count_url   => count_url,
           :count       => count,
           :button_url  => button_url,
           :bg_color    => bg_color,
           :color       => color,
           :style       => style
         }, type)
      else
        content_type 'text/plain'
        return 'missing repo param'
      end
    else
      content_type 'text/plain'
      return 'missing user param'
    end
  end
end

def fetch(api_url, prop, args)
  cached_response = "cache/#{args[:user]}:#{args[:repo]}:#{args[:issue]}"
  uri = URI.parse api_url
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE

  request = Net::HTTP::Get.new(uri.request_uri)
  request.add_field 'If-Modified-Since', File.stat(cached_response).mtime.getgm.strftime('%a, %d %b %Y %H:%M:%S GMT') if File.exist?(cached_response)

  auth = "#{args[:auth]}".split(":")
  if auth.length==2
    request.basic_auth auth[0], auth[1]
  end

  response = http.request(request)

  open cached_response, 'w' do |io|
    io.write response.body
  end if response.is_a? Net::HTTPSuccess

  proplist = prop.split('.')
  if proplist.length==1
    JSON.parse(File.read(cached_response))[prop]
  else 
    if proplist.length==2
      milestone = JSON.parse(File.read(cached_response))[proplist[0]]
      if milestone
        milestone[proplist[1]]
      else
        "No milestone"
      end

    end
  end
end

def create_button(opts, type)
  case type
    when :state
      Haml::Engine.new(File.read("./btn.haml")).render(Object.new, :opts => opts)
    when :milestone
      Haml::Engine.new(File.read("./btn_m.haml")).render(Object.new, :opts => opts)
  end


end
