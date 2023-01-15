module Agents
  class WriteInfluxdbAgent < Agent
    no_bulk_receive!
    cannot_create_events!
    default_schedule 'never'

    description <<-MD
      The Write InfluxDB Agent writes data from an event to an InfluxDB database.

      Options:

      * `url` - Connection URL to the DB (e.g. http://influx:8086)
      * `db` - Database name
      * `payload` - Array of write commands in line protocol format (see [the InfluxDB docs](https://docs.influxdata.com/influxdb/v1.8/write_protocols/line_protocol_reference/))
    MD

    def default_options
      {
        'url' => '',
        'db' => '',
        'payload' => [],

        'expected_receive_period_in_days' => '1',
        'debug' => 'false'
      }
    end

    def validate_options
      errors.add(:base, "url is required") unless options['url'].present?
      errors.add(:base, "url must be http(s)") unless /^https?:\/\/.+/.match?(interpolated['url'])

      errors.add(:base, "db is required") unless options['db'].present?

      errors.add(:base, "payload is required") unless options['payload'].present?
      case payload = options['payload']
      when nil
      when Array
        payload.all? { |item|
          String === item
        } or errors.add(:base, 'payload may only contain strings')
        if payload.empty?
          errors.add(:base, 'payload must not be empty')
        end
      else
        errors.add(:base, 'payload must be an array')
      end

      unless options['expected_receive_period_in_days'].present? && options['expected_receive_period_in_days'].to_i > 0
        errors.add(:base, "Please provide 'expected_receive_period_in_days' to indicate how many days can pass without an update before this Agent is considered to not be working")
      end
      
      if options['debug'].present?
        errors.add(:base, "debug contains invalid value") unless !boolify(options['debug']).nil?
      end
    end

    def working?
      received_event_without_error?
    end

    def receive(incoming_events)
      incoming_events.each do |event|
        interpolate_with(event) do
          log event if interpolated['debug'] == 'true'
          write_to_db
        end
      end
    end
    
    def write_to_db
      url = URI.parse("#{interpolated['url']}/write?db=#{interpolated['db']}")
      log url
    end
  end
end
