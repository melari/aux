# frozen_string_literal: true

require "open3"
require "json"
require_relative "../colorize"

module Aux
  module Commands
    class Pr
      class GitError < StandardError; end

      def run
        branch = current_branch
        puts "Branch: #{branch}"

        puts "Fetching origin/#{branch}..."
        fetch(branch)

        local_sha = resolve_sha("HEAD")
        remote_sha = resolve_sha("origin/#{branch}")

        if local_sha == remote_sha
          puts "Branch is in sync with origin/#{branch}.".colorize(:green)
        else
          puts "Warning: local branch is out of sync with origin/#{branch}.".colorize(:yellow)
          puts "  local:  #{local_sha}"
          puts "  remote: #{remote_sha}"
        end

        check_existing_pr(branch)

        puts
        puts "Generating PR title and description...".colorize(:dim)
        title, description = generate_title_and_description(branch)
        puts
        puts "Title: #{title}".colorize(:cyan)
        puts
        puts description

        puts
        puts "Creating draft PR...".colorize(:dim)
        url = create_pr(title, description)
        puts
        puts "PR is ready!".colorize(:green)
        puts "  #{url}"
      end

      private

      def current_branch
        stdout, stderr, status = capture3("git rev-parse --abbrev-ref HEAD")
        raise GitError, "Failed to get current branch: #{stderr.strip}" unless status.success?

        branch = stdout.strip
        raise GitError, "Could not determine current branch." if branch.empty? || branch == "HEAD"

        branch
      end

      def fetch(branch)
        _, stderr, status = capture3("git fetch origin #{branch}")
        raise GitError, "Failed to fetch origin/#{branch}: #{stderr.strip}" unless status.success?
      end

      def check_existing_pr(branch)
        stdout, _, status = capture3("gh pr view #{branch} --json url,title,number,state")

        unless status.success?
          puts "No existing PR found for #{branch}.".colorize(:dim)
          return
        end

        pr = JSON.parse(stdout)
        puts "Existing PR ##{pr["number"]}: #{pr["title"]}".colorize(:cyan)
        puts "  #{pr["url"]}"
      end

      def beta_url
        stdout, stderr, status = capture3("beta ls --json")
        raise GitError, "Failed to list betas: #{stderr.strip}" unless status.success?

        betas = JSON.parse(stdout)

        case betas.length
        when 0
          ""
        when 1
          betas.first["url"]
        else
          betas.map { |b| "- #{b["template"]}: #{b["url"]}" }.join("\n")
        end
      end

      def diff_against_master
        @diff_against_master ||= begin
          stdout, stderr, status = capture3("git diff master")
          raise GitError, "Failed to get diff: #{stderr.strip}" unless status.success?

          stdout
        end
      end

      def commits_against_master
        @commits_against_master ||= begin
          stdout, stderr, status = capture3("git log master..HEAD --oneline")
          raise GitError, "Failed to get commits: #{stderr.strip}" unless status.success?

          stdout
        end
      end

      def generate_title_and_description(branch)
        prompt_path = File.expand_path("../prompts/pr.md", __dir__)
        prompt = File.read(prompt_path)
          .gsub("{{branch}}", branch)
          .gsub("{{diff}}", diff_against_master)
          .gsub("{{commits}}", commits_against_master)
          .gsub("{{beta_url}}", beta_url)

        result = JSON.parse(run_agent(prompt))
        [result.fetch("title"), result.fetch("description")]
      end

      def create_pr(title, description)
        stdout, stderr, status = capture3(
          "gh", "pr", "create",
          "--draft",
          "--title", title,
          "--body", description
        )

        raise GitError, "Failed to create PR: #{stderr.strip}" unless status.success?

        stdout.strip
      end

      def run_agent(prompt)
        stdout, stderr, status = capture3(
          "agent", "--trust", "--output-format", "json", "--print", "prompt", prompt
        )

        raise GitError, "Agent failed: #{stderr.force_encoding("UTF-8").strip}" unless status.success?

        JSON.parse(stdout.force_encoding("UTF-8")).fetch("result")
      end

      def resolve_sha(ref)
        stdout, stderr, status = capture3("git rev-parse #{ref}")
        raise GitError, "Failed to resolve #{ref}: #{stderr.strip}" unless status.success?

        stdout.strip
      end

      def capture3(*cmd)
        Bundler.with_unbundled_env { Open3.capture3(*cmd) }
      end
    end
  end
end
