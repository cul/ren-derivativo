module Derivativo::ShellCommand
  def self.run_with_timeout(cmd, timeout_in_seconds)
    stdout_str = ''
    stderr_str = ''
    begin
      read_out, write_out = IO.pipe
      read_err, write_err = IO.pipe
      pid = Process.spawn(cmd, pgroup: true, :out => write_out, :err => write_err)
      Timeout.timeout(timeout_in_seconds) do
        Process.waitpid(pid)

        # close write ends so we can read from them
        write_out.close
        write_err.close

        stdout_str = read_out.readlines.join
        stderr_str = read_err.readlines.join
      end
    rescue Timeout::Error => e
      Process.kill('KILL', pid)
      Process.detach(pid)
      # re-raise timeout error
      raise e.class, "Operation timed out because it took longer than allowed timeout duration (#{timeout_in_seconds} seconds)"
    ensure
      write_out.close unless write_out.closed?
      write_err.close unless write_err.closed?
      # dispose the read ends of the pipes
      read_out.close
      read_err.close
    end

    [stdout_str, stderr_str]
  end
end
