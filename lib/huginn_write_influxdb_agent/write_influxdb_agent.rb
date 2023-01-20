module Agents
  class WriteInfluxdbAgent < Agent
    include WebRequestConcern
    
    no_bulk_receive!
    cannot_create_events!
    default_schedule 'never'

    description <<-MD
      The Write InfluxDB Agent writes data from an event to an InfluxDB database.

      Options:

      * `url` - Connection URL to the DB (e.g. http://influx:8086)
      * `db` - Database name
      * `influx_payload` - Array of write commands in line protocol format (see [the InfluxDB docs](https://docs.influxdata.com/influxdb/v1.8/write_protocols/line_protocol_reference/)).
                           Alternatively to adding values here, you can pass them by having an `influx_payload` array in the incoming event.
    MD

    def default_options
      {
        'url' => '',
        'db' => '',
        'influx_payload' => [],

        'expected_receive_period_in_days' => '1',
        'debug' => 'false'
      }
    end

    def validate_options
      errors.add(:base, "url is required") unless options['url'].present?
      errors.add(:base, "url must be http(s)") unless /^https?:\/\/.+/.match?(interpolated['url'])

      errors.add(:base, "db is required") unless options['db'].present?

      if options['influx_payload'].present?
        case payload = options['influx_payload']
        when Array
          payload.all? { |item|
            String === item
          } or errors.add(:base, 'influx_payload may only contain strings')
        else
          errors.add(:base, 'influx_payload must be an array')
        end
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
          write_to_db(event)
        end
      end
    end
    
    def write_to_db(event)
      url = URI.parse("#{interpolated['url']}/write?db=#{interpolated['db']}")
      log url if interpolated['debug'] == 'true'
      
      if interpolated['influx_payload'].present?
        msgs = interpolated['influx_payload']
      elsif event.payload['influx_payload'].present?
        msgs = event.payload['influx_payload']
      end
      
      if msgs
        msgs.each do |msg|
          log msg if interpolated['debug'] == 'true'
    
          response = faraday.run_request(:post, url, msg)

          log "response status code: #{response.status}" if interpolated['debug'] == 'true'
        end
      end
    end

  end
end
