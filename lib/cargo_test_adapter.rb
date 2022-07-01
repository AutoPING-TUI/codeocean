# frozen_string_literal: true

require 'json'

class CargoTestAdapter < TestingFrameworkAdapter
    def self.framework_name
        'CargoTest'
    end

    def parse_output(output)
        extract_test_result_parameters(parse_json_objects_per_line(output[:stdout]))
    end

    def pretty_format(test_result_obj)
        test_result_obj["stdout"]
    end

    # Assumption: One JSON object per row. If a row is not a JSON object, it will not be included in parsed_json_objects.
    def parse_json_objects_per_line(string)
        parsed_json_objects = []
        string.each_line(chomp: true) { |line|
            begin
                obj = JSON.parse(line)
                parsed_json_objects.push(obj)
            rescue JSON::ParserError
            end
        }
        parsed_json_objects
    end

    def extract_test_result_parameters(parsed_json_objects)
        count = 0
        failed = 0
        error_messages = []

        parsed_json_objects.each { |obj|
            if obj["type"] == "suite"
                if obj.has_key?("test_count")
                    count += obj["test_count"]
                elsif obj.has_key?("failed")
                    failed += obj["failed"]
                end
            end
            if obj["type"] == "test" && obj["event"] == "failed"
                error_messages.push(pretty_format(obj))
            end
        }

        {count: count, failed: failed, error_messages: error_messages}
    end
end

