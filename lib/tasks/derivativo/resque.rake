MAX_WAIT_TIME_TO_KILL_WORKERS = 120
PIDFILE_PATH = 'tmp/pids/resque.pid'

namespace :resque do

  desc "Stop current workers and start new workers"
  task :restart_workers => :environment do
    Rake::Task['resque:stop_workers'].invoke
    Rake::Task['resque:start_workers'].invoke
  end

  desc "Stop running workers"
  task :stop_workers => :environment do
    stop_workers
  end

  desc "Start workers"
  task :start_workers => :environment do
    start_workers(Rails.application.config_for(:resque))
  end

  def store_pids(pids, mode)
    pids_to_store = pids
    pids_to_store += read_pids if mode == :append

    File.write(File.expand_path(PIDFILE_PATH, Rails.root), pids_to_store.join(','))
  end

  def read_pids
    pid_file_path = File.expand_path(PIDFILE_PATH, Rails.root)
    return [] if ! File.exists?(pid_file_path)

    File.read(pid_file_path).split(',').collect {|p| p.to_i }
  end

  def stop_workers
    pids = read_pids

    if pids.empty?
      puts "No workers to kill"
    else
      # First tell workers to stop accepting new work by sending USR2 signal
      puts "\nTelling workers to finish current jobs, but not process any new jobs..."
      syscmd = "kill -s USR2 #{pids.join(' ')}"
      puts "$ #{syscmd}"
      `#{syscmd}`
      puts "\n"
      puts "Waiting for workers to finish current jobs..."
      start_time = Time.now
      while (Time.now - start_time) < MAX_WAIT_TIME_TO_KILL_WORKERS do
        sleep 1
        num_workers_working = Resque.workers.select { |w| w.working? }.length
        puts "#{num_workers_working} workers still working..."
        break if num_workers_working.zero?
      end
      puts "\n"
      if Resque.workers.select(&:working?).length > 0
        puts "Workers are still running, but wait time of #{MAX_WAIT_TIME_TO_KILL_WORKERS} has been exceeded. Sending QUIT signal anyway."
      else
        puts 'Workers are no longer processing any jobs. Sending QUIT signal.'
      end
      syscmd = "kill -s QUIT #{pids.join(' ')}"
      puts "$ #{syscmd}"
      `#{syscmd}`
      store_pids([], :write)
      puts "\n"
    end

    # Unregister old workers
    Resque.workers.each {|w| w.unregister_worker}
  end

  # Start a worker with proper env vars and output redirection
  def start_workers(resque_config)
    polling_interval = resque_config[:polling_interval]
    worker_config = resque_config.fetch(:workers, {})

    total_workers = 0
    worker_info_string = worker_config.map { |queues, count|
      total_workers += count

      "  [ #{queues} ] => #{count} #{count == 1 ? 'worker' : 'workers'}"
    }.join("\n")
    puts "Starting #{total_workers} #{total_workers == 1 ? 'worker' : 'workers'} with a polling interval of #{polling_interval} seconds:\n" + worker_info_string

    ##  make sure log/resque_err, log/resque_stdout are writable.
    ops = {:pgroup => true, :err => [(Rails.root + "log/resque_err").to_s, "a"],
                            :out => [(Rails.root + "log/resque_stdout").to_s, "a"]}

    pids = []
    worker_config.each do |queues, count|
      env_vars = {"QUEUES" => queues.to_s, 'RAILS_ENV' => Rails.env.to_s, 'TERM_CHILD' => '1'}
      env_vars = {
        'QUEUES' => queues.to_s,
        'RAILS_ENV' => Rails.env.to_s,
        'TERM_CHILD' => '1',
        'INTERVAL' => polling_interval # jobs tend to run for a while, so a 5-second checking interval is fine
      }
      count.times {
        # Using Kernel.spawn and Process.detach because regular system() call would
        # cause the processes to quit when capistrano finishes
        pid = spawn(env_vars, "rake resque:work", ops)
        Process.detach(pid)
        pids << pid
      }
    end

    store_pids(pids, :append)
  end
end
