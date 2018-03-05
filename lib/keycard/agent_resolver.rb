require "ostruct"

module Keycard
  class AgentResolver
    def initialize(agent_factory:)
      @agent_factory = agent_factory
    end

    def resolve(actor, attrs: RequestAttributes.public_method(:new))
      attrs.call(actor.request).all.map { |k,v| agents_for(k,v) }.flatten
    end 

    def agents_for(attribute, values)
      [ values ].flatten.map do |value|
        agent_factory.for(attribute, value)
      end
    end


    private

    attr_reader :agent_factory

  end
end

