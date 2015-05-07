require 'sinatra'

class Logger
  def initialize(logfile_name="simpleportal.log")
    if File.exist? logfile_name
      @logfile = File.open(logfile_name, "w+")
    else
      @logfile = File.open(logfile_name, "w")
    end
  end
  def log(msg)
    @logfile.puts(msg)
    puts(msg)
  end
end

logger = Logger.new
host = "10.0.0.1"
port = "4567"
if !File.exist? "/tmp/captive_auth"
  abort("/tmp/captive_auth not exists.. aborting")
end

if !File.exist? "/tmp/captive_res"
  abort("/tmp/captive_res not exists.. aborting")
end
logger.log("start simple captive portal at #{Time.now}")
set :bind, '0.0.0.0' #allow outboud connection
get '/' do 
  if request.host != host
    redirect "http://#{host}:#{port}/"
  end
  erb :index
end
post '/auth' do
  logger.log("#{Time.now} : #{request.ip}")
  authpipe = File.open("/tmp/captive_auth", "w+")
  authpipe.puts("#{params['username']};#{params['password']};#{request.ip};#{Time.now}")
  authpipe.close
  respipe = File.open("/tmp/captive_res", "r+")
  res = respipe.gets
  respipe.close
  if res.chomp == "passed"
    redirect to("/passed")
  else
    redirect to("/failed")
  end
end

get '/passed' do
  erb :passed
end

get '/failed' do  
  erb :failed
end
