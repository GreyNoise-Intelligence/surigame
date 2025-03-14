require 'base64'
require 'json'
require 'pathname'
require 'sinatra'
require 'singlogger'
require 'socket'
require 'timeout'

# Markdown
require 'redcarpet'

# Safe YAML parsing
require 'safe_yaml'
SafeYAML::OPTIONS[:default_mode] = :safe

GAME_NAME = 'SuriGame'
GAME_LOGO = '/greynoise.jpg'

# These are what get returned to the user by default
PUBLIC_FIELDS = %w[
  id
  name
  type
  divider_before
  text
  hints
  base_request
  previous
]

::SingLogger.set_level_from_string(level: ENV['log_level'] || 'debug')
LOGGER = ::SingLogger.instance()

# Ideally, we set all these in the Dockerfile
set :bind, ENV['HOST'] || '0.0.0.0'
set :port, ENV['PORT'] || '1234'

PROFILE = 'dev' # prod?

SCRIPT = File.expand_path(__FILE__)

# Load the levels from the levels/ directory
LEVELS = ::Dir.glob(::File.join(__dir__, 'levels', '**', 'config.yaml')).sort.map do |config|
  {
    # Add the id (based on the filename) to each config file
    'id' => ::Pathname.new(config).parent.basename.to_s,
  }.merge(::YAML.load_file(config))
end

# Add the next/previous levels
1.upto(LEVELS.length - 1) do |i|
  LEVELS[i]['previous'] = LEVELS[i - 1]['id']
  LEVELS[i - 1]['next'] = LEVELS[i]['id']
end

LEVELS_BY_ID = LEVELS.map { |l| [l['id'], l] }.to_h

def unlocked_levels
  return LEVELS.map { |l| l.slice(*PUBLIC_FIELDS) }
end

def get_level(id)
  return LEVELS_BY_ID[id]&.slice(*PUBLIC_FIELDS)
end

MARKDOWN = Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true, tables: true, prettify: true)
def md(text)
  return MARKDOWN.render(text)
end

def format_http(http)
  http = http.gsub(/\r?\n/, "\r\n")
  until http.include?("\r\n\r\n")
    http.concat("\r\n")
  end

  return http
end

get '/' do
  erb(
    :index,
    locals: {
      levels: unlocked_levels
    }
  )
end

get '/level/:id' do
  puts @params[:id]
  level = get_level(@params[:id])

  if level
    erb(
      :"levels/#{ level['type'] }",
      locals: {
        levels: unlocked_levels,
        level: level,
      }
    )
  else
    erb(
      :error,
      locals: {
        levels: unlocked_levels,
        error: 'No such level!',
      }
    )
  end
end

# Define routes starting with /api
before do
  if request.nil? || request.content_type.nil?
    next
  end

  unless request.content_type.start_with?('application/json')
    next
  end

  begin
    request.body.rewind
    @body = ::JSON.parse(request.body.read)
  rescue ::JSON::ParserError => e
    # Handle JSON parsing errors
    LOGGER.error("JSON parsing error: #{ e.message }")

    halt(400, { error: 'JSON parsing error!' }.to_json)
  rescue StandardError => e
    # Handle any other unexpected errors
    LOGGER.error("Unexpected error: #{ e.message }")

    halt(500, { error: "Unexpected error: #{ e.message }" }.to_json)
  end
end

get '/api/levels/:id' do
  level = get_level(@params[:id])

  unless level
    return 400, { 'error' => 'No such level!' }.to_json
  end

  return 200, level.to_json
end

post '/api/exploit/:id' do
  if @body['request'].nil?
    return 400, { 'error' => 'Missing request!' }.to_json
  end

  level = LEVELS_BY_ID[@params[:id]]
  if level.nil?
    return 400, { 'error' => 'Invalid level!' }.to_json
  end

  request = format_http(@body['request'])

  begin
    ::Timeout.timeout(10) do
      s = TCPSocket.new(level['target'][PROFILE]['host'], level['target'][PROFILE]['port'])
      s.write(request)
      response = s.read()

      pp level

      return 200, {
        'response' => ::Base64.strict_encode64(response),
        'completed' => !(response =~ ::Regexp.new(level['expected_output'])).nil?,
      }.to_json
    end
  rescue ::Timeout::Error
    LOGGER.warn('Timeout!')
    return 500, { 'error' => 'Request to target server timed out! This is probably an infrastructure problem...' }.to_json
  rescue ::Errno::ECONNREFUSED => e
    LOGGER.error("Connection refused: #{ e }")
    return 500, { 'error' => 'Connection refused to target server! This is probably an infrastructure problem...' }.to_json
  rescue ::StandardError => e
    LOGGER.error("Error running exploit (#{ e.class }): #{ e }")
    return 500, { 'error' => "Error running exploit: #{ e }" }.to_json
  end
end
