require 'capistrano/ext/multistage'

set :stages,          %w(local)
set :default_stage,   "local"

set :application, "cmbase"

# 编译以后的代码所在的路径，就是要 deploy 的版本
set :repository,  "./build"

# 因为是直接编译的JS，所以没有用到 SCM
set :scm, :none

# deploy 复制文件的方式
set :deploy_via, :copy

# 压缩的方式
set :copy_compression,  :bz2

set :linked_dirs, %w{bin log assets tmp node_modules}

# 本地生成的压缩文件的路径
set :copy_dir, "/var/tmp"

set :default_environment, {
  'PATH' => "/usr/local/bin:$PATH",
}

# 部署时候不需要sudo
set :use_sudo, false

# 终端的类型
set :default_run_options, :pty => true

set :normalize_asset_timestamps, false

set :deploy_to, '/var/www/apps/cmbase/'

set :path_to_log, "#{current_path}/log/#{application}.log"
set :path_to_pid, "#{current_path}/#{application}.pid"
set :path_to_main_script, "#{current_path}/lib/server.min.js"

namespace :build do
  desc "build production release"
  task :release do
    run_locally "rm -rf ./build && mkdir -pv ./build && distill -i src/server.coffee -o build/lib/server.js -n && cp -Rv package.json public views build/ "
    raise "build failed. Exit code: #{$?.exitstatus}" unless $?.exitstatus.zero?
  end
end

namespace :deploy do

  desc "start cmbase"
  task :start, :roles => :app, :except => { :no_release => true } do
    run "touch #{path_to_log} && DEBUG=* forever start -a -l #{path_to_log} --pidFile #{path_to_pid} #{path_to_main_script} -e #{mode}"
  end

  desc "stop cmbase"
  task :stop, :roles => :app, :except => { :no_release => true } do
    run "forever_status=$(forever list); grep -q #{path_to_main_script} <<< $forever_status && forever stop  #{path_to_main_script} ; echo service stopped"
  end

  desc "restart cmbase"
  task :restart, :roles => :app, :except => { :no_release => true } do
    stop
    sleep 1
    start
  end

  desc "install nodejs dependency"
  task :npm_install do
    run "mkdir -p #{shared_path}/node_modules && ln -s #{shared_path}/node_modules #{release_path}/node_modules"
    run "cd #{release_path} && npm config set registry http://registry.cnpmjs.org && npm install --production && npm config set registry http://registry.npmjs.org"

  end

end

after "deploy:update_code", "deploy:npm_install"


