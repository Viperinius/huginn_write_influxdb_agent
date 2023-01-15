require 'huginn_agent'

#HuginnAgent.load 'huginn_write_influxdb_agent/concerns/my_agent_concern'
HuginnAgent.register 'huginn_write_influxdb_agent/write_influxdb_agent'
