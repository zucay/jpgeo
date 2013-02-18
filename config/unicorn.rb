# -*- coding: utf-8 -*-
worker_processes 2
rails_env = 'production'

port = 4000
listen port, :tcp_nopush => true
# unix socket for nginx
#listen File.expand_path('tmp/unicorn.sock', ENV['RAILS_ROOT'])

# log
stderr_path File.expand_path('log/unicorn.log', ENV['RAILS_ROOT'])
stdout_path File.expand_path('log/unicorn.log', ENV['RAILS_ROOT'])

# pid
pid 'tmp/pids/unicorn.pid'

# no downtime
preload_app true

before_fork do |server, worker|
  # for preload_app true
  defined?(ActiveRecord::Base) and ActiveRecord::Base.connection.disconnect!

  old_pid = "#{  server.config[:pid] }.oldbin"
  unless old_pid == server.pid
    begin
      Process.kill :QUIT, File.read(old_pid).to_i
    rescue Errno::ENOENT, Errno::ESRCH
    end
  end
end

after_fork do |server, worker|
  # for preload_app true
  defined?(ActiveRecord::Base) and ActiveRecord::Base.establish_connection
end

