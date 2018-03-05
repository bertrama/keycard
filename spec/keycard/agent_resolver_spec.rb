require "keycard/agent_resolver"

module Keycard
  RSpec.describe AgentResolver do
    let(:fake_agent_factory) { double(:agent_factory) }

    subject(:agent_resolver) do
      described_class.new(agent_factory: fake_agent_factory)
    end

    def fake_attrs(attrs) 
      ->(_) { double(:attrs, all: attrs) }
    end

    describe "#resolve" do
      let(:actor) { double(:user, request: double(:request) ) }

      context "foo" do
        context "with some attributes" do
          subject(:agent_resolver) do
            described_class.new(agent_factory: fake_agent_factory)
          end

          before(:each) do 
            allow(fake_agent_factory).to receive(:for).with(:foo,'bar').and_return(agent)
          end

          let(:attrs) { fake_attrs(foo: 'bar') }
          let(:agent) { double(:agent, type: 'foo', id: 'bar') }
          it "turns the attributes into agents" do
            resolved_agents = agent_resolver.resolve(actor, attrs: attrs)
            expect(resolved_agents).to contain_exactly(agent)
          end
        end
      end

      context "with some different attributes" do
        let(:attrs) { fake_attrs(baz: 'quux') }
        let(:agent) { double(:agent, type: 'baz', id: 'quux') }

        before(:each) do
          allow(fake_agent_factory).to receive(:for).with(:baz,'quux').and_return(agent)
        end

        it "turns the attributes into agents" do
          resolved_agents = agent_resolver.resolve(actor, attrs: attrs)
          expect(resolved_agents).to contain_exactly(agent)
        end
      end

      context "with a multi-value attribute" do
        let(:attrs) { fake_attrs(foo: ['bar', 'baz']) }
        let(:agents) do
          [ double(:agent, type: 'foo', id: 'bar'),
            double(:agent, type: 'foo', id: 'baz') ] 
        end

        before(:each) do
          allow(fake_agent_factory).to receive(:for).with(:foo,'bar').and_return(agents[0])
          allow(fake_agent_factory).to receive(:for).with(:foo,'baz').and_return(agents[1])
        end

        it "returns two agents" do
          resolved_agents = agent_resolver.resolve(actor, attrs: attrs)
          expect(resolved_agents.length).to eq(2)
          expect(resolved_agents).to contain_exactly(*agents)
        end

      end

    end
  end
end
