

set :user, "user"
set :host, "localhost"
#set :host, "gamagama.cn"

set :mode, "development"

role :web, host
role :app, host

# refresh build every deployment
before "deploy", "build:release"

