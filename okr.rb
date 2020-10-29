require 'net/https'
require 'uri'
require 'json'

uri = URI('https://my.15five.com/account/login')
resp = Net::HTTP.post_form(
  uri,
  {
    username: ENV['OKR_USERNAME'],
    password: ENV['OKR_PASSWORD'],
  },
)
raise resp if resp.code != '302'
@cookies = resp.get_fields('Set-Cookie').map do |cookie|
  cookie.split('; ').first
end

def get_user_id
  uri = URI('https://my.15five.com/profile/api/user-profile/')
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  req = Net::HTTP::Get.new(uri)
  req[:Accept] = 'application/json'
  req[:Cookie] = @cookies.join('; ')
  resp = http.request(req)
  JSON.parse(resp.body)['id']
end

def get_objectives(**params)
  uri = URI('https://my.15five.com/objectives/api/objectives/')
  uri.query = URI.encode_www_form(params)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  req = Net::HTTP::Get.new(uri)
  req[:Accept] = 'application/json'
  req[:Cookie] = @cookies.join('; ')
  resp = http.request(req)
  result = JSON.parse(resp.body)['results']
  result.select { |o| o['marked_completed_ts'].nil? }.map do |o|
    key_results = o['key_results'].map do |kr|
      {
        description: kr['description'],
      }
    end
    children = get_objectives(parent_id: o['id']) if o['children_count'] > 0
    {
      id: o['id'],
      description: o['description'],
      children: [*key_results, *children],
    }
  end
end

def format_objectives(objectives, indent = 0)
  spaces = '  ' * indent
  objectives.map do |o|
    row = o[:description]
    row = "[#{row}](https://my.15five.com/objectives/details/#{o[:id]})" if o[:id]
    [
      "#{spaces}- #{row}",
      *format_objectives(o[:children], indent + 1),
    ]
  end.join("\n") if objectives
end
