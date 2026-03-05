require "openai"

module Agents
  # Creates the article from weighted sources and detected disagreements.
  # Calls the LLM with a strictly constrained prompt and parses the JSON output.
  class SynthesisWriter < BaseAgent
    class SynthesisError < StandardError; end

    def name = "Synthesis Writer"
    def description = "Writes the article from weighted evidence"

    SYSTEM_PROMPT = <<~PROMPT.freeze
      You are Centipedia's Synthesis Writer agent. You compile evidence-weighted knowledge articles.

      STRICT RULES:
      1. You may ONLY use facts found in the provided sources. Do NOT use your training data.
      2. Every sentence you write MUST include a "citation_event_ids" array referencing which source(s) support it.
      3. If disagreements are provided, you MUST acknowledge both sides and cite the respective sources.
      4. Do NOT invent, infer, or hallucinate any knowledge beyond what is explicitly stated in the sources.
      5. Use neutral, encyclopedic tone. Avoid persuasive or normative language.
      6. Structure your output as a JSON array of sections.

      OUTPUT FORMAT (strict JSON, no markdown):
      [
        {
          "section": "Section Title",
          "claims": [
            {
              "text": "A factual claim derived from the sources.",
              "citation_event_ids": [1, 3]
            }
          ]
        }
      ]

      Return ONLY the JSON array. No preamble, no markdown fences, no explanation.
    PROMPT

    def run(context)
      topic = context[:topic]
      citations = context[:citations]
      disagreements = context[:disagreements] || []

      source_context = build_source_context(citations)
      raw_response = call_llm(topic, source_context, disagreements)
      parsed_content = parse_response(raw_response)

      context.merge(article_content: parsed_content)
    end

    private

    def build_source_context(citations)
      citations.map do |ce|
        source = ce.source
        text_content = source.article_content.present? ? source.article_content.truncate(3000) : "(Content not yet extracted)"

        {
          citation_event_id: ce.id,
          url: source.canonical_url,
          domain: source.domain.host,
          title: source.article_title || "(No title)",
          weight: ce.total_weight.to_f,
          text: text_content
        }
      end
    end

    def call_llm(topic, source_context, disagreements)
      client = OpenAI::Client.new(access_token: Rails.application.credentials.dig(:openai, :api_key))

      disagreement_note = if disagreements.any?
        "\n\nDISAGREEMENTS DETECTED (you must acknowledge these):\n" +
        disagreements.map { |d| "- #{d['description']}" }.join("\n")
      else
        ""
      end

      user_message = <<~MSG
        Synthesize a knowledge article for the topic: "#{topic.title}"

        Here are the weighted sources (highest weight = most trusted):

        #{source_context.map { |s|
          "--- SOURCE [citation_event_id: #{s[:citation_event_id]}] (weight: #{s[:weight]}) ---\n" \
          "URL: #{s[:url]}\n" \
          "Domain: #{s[:domain]}\n" \
          "Title: #{s[:title]}\n" \
          "Content:\n#{s[:text]}\n"
        }.join("\n")}
        #{disagreement_note}

        Generate the article now as a JSON array of sections.
      MSG

      response = client.chat(
        parameters: {
          model: "gpt-4o",
          messages: [
            { role: "system", content: SYSTEM_PROMPT },
            { role: "user", content: user_message }
          ],
          temperature: 0.1,
          max_tokens: 4000
        }
      )

      content = response.dig("choices", 0, "message", "content")
      raise SynthesisError, "Empty response from LLM" if content.blank?

      content
    end

    def parse_response(raw)
      cleaned = raw.strip.gsub(/\A```json\n?/, "").gsub(/\n?```\z/, "")

      parsed = JSON.parse(cleaned)

      unless parsed.is_a?(Array)
        raise SynthesisError, "LLM returned non-array JSON: #{parsed.class}"
      end

      parsed.each do |section|
        unless section.is_a?(Hash) && section["section"].present? && section["claims"].is_a?(Array)
          raise SynthesisError, "Invalid section structure: #{section.inspect}"
        end

        section["claims"].each do |claim|
          unless claim.is_a?(Hash) && claim["text"].present? && claim["citation_event_ids"].is_a?(Array)
            raise SynthesisError, "Invalid claim structure: #{claim.inspect}"
          end
        end
      end

      parsed
    rescue JSON::ParserError => e
      raise SynthesisError, "Failed to parse LLM response as JSON: #{e.message}"
    end
  end
end
