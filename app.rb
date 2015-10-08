$LOAD_PATH << File.expand_path('../app', __FILE__)

require 'sinatra'
require 'octokit'
require 'json'

require 'services/creates_commit_status'
require 'services/handles_event/null'
require 'services/handles_event/pull_request'

class App < Sinatra::Base
  post '/webhook' do
    event_type = request.env["HTTP_X_GITHUB_EVENT"]
    event_body = JSON.parse(request.body.read)

    handler = build_event_handler(event_type)
    handler.handle(event_body)

    status 204
  end

  private

  def build_event_handler(event_type)
    # TODO OAuth app flow.
    client = Octokit::Client.new(access_token: ENV["GITHUB_ACCESS_TOKEN"])
    creates_commit_status = CreatesCommitStatus.new(github_client: client)

    case event_type
    when "pull_request"
      HandlesEvent::PullRequest.new(
        creates_commit_status: creates_commit_status
      )
    else
      HandlesEvent::Null.new
    end
  end
end
