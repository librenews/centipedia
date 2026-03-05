require "test_helper"

class BaseAgentTest < ActiveSupport::TestCase
  class TestAgent < BaseAgent
    def name = "Test Agent"
    def description = "A test agent"
    def run(context)
      context.merge(test_result: "success")
    end
  end

  class FailingAgent < BaseAgent
    def name = "Failing Agent"
    def description = "Always fails"
    def run(context)
      raise "Something went wrong"
    end
  end

  class AbstractAgent < BaseAgent; end

  test "execute returns enriched context with agent log" do
    agent = TestAgent.new
    result = agent.execute({ topic: "test" })

    assert_equal "success", result[:test_result]
    assert_equal 1, result[:agent_log].length

    log_entry = result[:agent_log].first
    assert_equal "Test Agent", log_entry["name"]
    assert_equal "A test agent", log_entry["description"]
    assert log_entry["ran_at"].present?
    assert log_entry["duration_ms"].is_a?(Integer)
  end

  test "execute wraps errors in AgentError" do
    agent = FailingAgent.new

    error = assert_raises(BaseAgent::AgentError) do
      agent.execute({})
    end

    assert_includes error.message, "[Failing Agent]"
    assert_includes error.message, "Something went wrong"
  end

  test "abstract agent raises NotImplementedError" do
    agent = AbstractAgent.new

    assert_raises(NotImplementedError) { agent.name }
    assert_raises(NotImplementedError) { agent.description }
    assert_raises(NotImplementedError) { agent.run({}) }
  end
end
