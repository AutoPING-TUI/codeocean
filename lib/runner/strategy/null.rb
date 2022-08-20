# frozen_string_literal: true

# This strategy allows normal operation of CodeOcean even when the runner management is disabled.
# However, as no command can be executed, all execution requests will fail.
class Runner::Strategy::Null < Runner::Strategy
  def self.initialize_environment; end

  def self.environments
    raise Runner::Error.new
  end

  def self.sync_environment(_environment)
    raise Runner::Error.new
  end

  def self.remove_environment(_environment)
    raise Runner::Error.new
  end

  def self.request_from_management(_environment)
    SecureRandom.uuid
  end

  def destroy_at_management; end

  def copy_files(_files); end

  def attach_to_execution(command, event_loop, starting_time)
    socket = Connection.new(nil, self, event_loop)
    # We don't want to return an error if the execution environment is changed
    socket.status = :terminated_by_codeocean if command == ExecutionEnvironment::VALIDATION_COMMAND
    yield(socket, starting_time)
    socket
  end

  def self.available_images
    []
  end

  def self.config; end

  def self.release
    'N/A'
  end

  def self.pool_size
    {}
  end

  def self.websocket_header
    {}
  end

  class Connection < Runner::Connection
    def decode(event_data)
      event_data
    end

    def encode(data)
      data
    end

    def active?
      false
    end
  end
end
