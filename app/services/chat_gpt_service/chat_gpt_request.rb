
module ChatGptService
  class ChatGptRequest
    MODEL_NAME = 'gpt-4o'.freeze

    def initialize
      raise Gpt::Error::InvalidApiKey if fetch_api_key.blank?
      @client = OpenAI::Client.new(access_token: fetch_api_key)
    end

    def execute(prompt, response_format_needed = false)
      wrap_api_error! do
        data = {
          model: MODEL_NAME,
          messages: [{ role: 'user', content: prompt }],
          temperature: 0.7 # Lower values insure reproducibility
        }

        if response_format_needed
          response_format = JSON.parse(File.read(Rails.root.join('app', 'services/chat_gpt_service/chat_gpt_prompts', 'response_format.json')))
          data[:response_format] = response_format
        end

        begin
          response = @client.chat(parameters: data)
          json_response = response.dig('choices', 0, 'message', 'content')

          if json_response
            json_response
          else
            error_message = response.dig('error', 'message') || 'Unknown error'
            Rails.logger.error "ChatGPT API Error: #{error_message}"
            raise "ChatGPT API Error: #{error_message}"
          end
        rescue JSON::ParserError => e
          Rails.logger.error "Failed to parse ChatGPT response: #{e.message}"
          raise "Failed to parse ChatGPT response: #{e.message}"
        rescue StandardError => e
          Rails.logger.error "Error while making request to ChatGPT: #{e.message}"
          raise e
        end
      end
    end

    private

    def fetch_api_key
      api_key = Rails.application.credentials.openai[:api_key]
      raise "OpenAI API key is missing. Please set it in environment variables or Rails credentials." unless api_key
      api_key
    end

    def wrap_api_error!
      yield
    rescue Faraday::UnauthorizedError, OpenAI::Error => e
      raise Gpt::Error::InvalidApiKey.new("Could not authenticate with OpenAI: #{e.message}")
    rescue Faraday::Error => e
      raise Gpt::Error::InternalServerError.new("Could not communicate with OpenAI: #{e.inspect}")
    rescue Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNRESET, SocketError, EOFError => e
      raise Gpt::Error.new(e)
    end

  end
end
