require 'rails_helper'
require 'huginn_agent/spec_helper'

describe Agents::WriteInfluxdbAgent do
  before(:each) do
    @valid_options = Agents::WriteInfluxdbAgent.new.default_options
    @checker = Agents::WriteInfluxdbAgent.new(:name => "WriteInfluxdbAgent", :options => @valid_options)
    @checker.user = users(:bob)
    @checker.save!
  end

  pending "add specs here"
end
