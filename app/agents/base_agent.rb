# Abstract base class for all Centipedia agents.
# Each agent has a single responsibility, a typed input/output contract,
# and its contribution is automatically logged for transparency.
#
# Usage:
#   class MyAgent < BaseAgent
#     def name = "My Agent"
#     def description = "Does something specific"
#     def run(context)
#       # Do work, return enriched context
#       context.merge(my_result: "value")
#     end
#   end
#
class BaseAgent
  class AgentError < StandardError; end

  # Human-readable name shown in the UI (e.g., "Evidence Judge")
  def name
    raise NotImplementedError, "#{self.class} must implement #name"
  end

  # What this agent does, shown in the UI transparency panel
  def description
    raise NotImplementedError, "#{self.class} must implement #description"
  end

  # Execute the agent's task.
  # Receives a context hash, returns an enriched version of it.
  # Subclasses MUST override this method.
  def run(context)
    raise NotImplementedError, "#{self.class} must implement #run(context)"
  end

  # Execute with automatic timing and logging.
  # Called by AgentPipeline — agents should NOT override this.
  def execute(context)
    started_at = Time.current

    result = run(context)

    finished_at = Time.current

    # Append this agent's metadata to the log
    log_entry = {
      "name" => name,
      "description" => description,
      "ran_at" => started_at.iso8601,
      "duration_ms" => ((finished_at - started_at) * 1000).round
    }

    result[:agent_log] ||= []
    result[:agent_log] << log_entry

    result
  rescue StandardError => e
    raise AgentError, "[#{name}] #{e.message}"
  end
end
