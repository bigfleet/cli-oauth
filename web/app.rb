# frozen_string_literal: true
# copied straight up from  MikeMcQuaid/strap
 
require "sinatra"
require "omniauth-github"
require "octokit"
require "securerandom"
require "rack/protection"
require "awesome_print" if ENV["RACK_ENV"] == "development"

GITHUB_KEY = ENV["GITHUB_KEY"]
GITHUB_SECRET = ENV["GITHUB_SECRET"]
SESSION_SECRET = ENV["SESSION_SECRET"] || SecureRandom.hex
CLI_ISSUES_URL = ENV["CLI_ISSUES_URL"]
CUSTOM_HOMEBREW_TAP = ENV["CUSTOM_HOMEBREW_TAP"]
CUSTOM_BREW_COMMAND = ENV["CUSTOM_BREW_COMMAND"]

set :sessions, secret: SESSION_SECRET

use OmniAuth::Builder do
  options = { scope: "user:email,repo,workflow" }
  options[:provider_ignores_state] = true if ENV["RACK_ENV"] == "development"
  provider :github, GITHUB_KEY, GITHUB_SECRET, options
end

use Rack::Protection, use: %i[authenticity_token cookie_tossing form_token
                              remote_referrer strict_transport]

get "/auth/github/callback" do
  auth = request.env["omniauth.auth"]
  session[:auth] = {
    "info"        => auth["info"],
    "credentials" => auth["credentials"],
  }

  return_to = session.delete :return_to
  return_to = "/" if !return_to || return_to.empty?
  redirect to return_to
end

get "/" do
  if request.scheme == "http" && ENV["RACK_ENV"] != "development"
    redirect to "https://#{request.host}#{request.fullpath}"
  end

  debugging_text = if CLI_ISSUES_URL.to_s.empty?
    "try to debug it yourself"
  else
    %Q{file an issue at <a href="#{CLI_ISSUES_URL}">#{CLI_ISSUES_URL}</a>}
  end

  @title = "Levvel CLI"
  @text = <<~HTML
    <h4 class="pb-3">To install the CLI:<h4>
    <p>It's assumed that you have atleast Node.js >=10.5, Yarn, and GIT installed
    <h5 class="pb-2">On Mac.</h5>
    <ol>
      <li>
        <a class="no-underline" href="/install-cli.sh">
          <button type="button" class="btn btn-sm">
            Download the <code>install-cli.sh</code>
          </button>
        </a>
        that's been customised for your GitHub user (or
        <a href="/install-cli.sh?text=1">view it</a>
        first). This will prompt for access to your email, public and private
        repositories; you'll need to provide access to any organizations whose
        repositories you need to be able to <code>git clone</code>. This is
        used to add a GitHub access token to the <code>install-cli.sh</code> script
        and is not otherwise used by this web application or stored
        anywhere.
      </li>
      <li>
        Run CLI installation in Terminal.app with <code>bash ~/Downloads/install-cli.sh</code>.
      </li>
      <li>
        If something failed, run CLI installation with more debugging output in
        Terminal.app with <code>bash ~/Downloads/install-cli.sh --debug</code> and
        #{debugging_text}.
      </li>
      <li>
        Delete the customised <code>install-cli.sh</code> (it has a GitHub token
        in it) in Terminal.app with
        <code>rm -f ~/Downloads/install-cli.sh</code>
      </li>
      <li>
        Install additional software with
        <code>brew install</code> and
        <code>brew cask install</code>.
      </li>
    </ol>
    <h5 class="pb-2">On PC.</h5>
    <ol>
    <li>
      <a class="no-underline" href="/install-cli-win.sh">
        <button type="button" class="btn btn-sm">
          Download the <code>install-cli-win.sh</code> (Recommended)
        </button>
      </a>
      <a class="no-underline" href="/install-cli-win.cmd">
        <button type="button" class="btn btn-sm">
          Download the <code>install-cli-win.cmd</code>
        </button>
      </a>
      that's been customised for your GitHub user (or
      <a href="/install-cli-win.sh?text=1">view it</a>
      first). This will prompt for access to your email, public and private
      repositories; you'll need to provide access to any organizations whose
      repositories you need to be able to <code>git clone</code>. This is
      used to add a GitHub access token to the <code>install-cli-win.sh</code> script
      and is not otherwise used by this web application or stored
      anywhere.
    </li>
    <li>
      Run CLI installation in Terminal.app with <code>bash ~/Downloads/install-cli-win.sh</code>.
    </li>
    <li>
      Delete the customised <code>install-cli-win.sh</code> (it has a GitHub token
      in it) in Terminal.app with
      <code>rm -f ~/Downloads/install-cli-win.sh</code>
    </li>
    <li>That's pretty much as far as we've got so far.</li>
    </ol>
  HTML
  erb :root
end

get "/install-cli.sh" do
  auth = session[:auth]

  if !auth && GITHUB_KEY && GITHUB_SECRET
    query = request.query_string
    query = "?#{query}" if query && !query.empty?
    session[:return_to] = "#{request.path}#{query}"
    redirect to "/auth/github"
  end

  script = File.expand_path("#{File.dirname(__FILE__)}/../bin/install-cli.sh")
  content = IO.read(script)

  set_variables = { CLI_ISSUES_URL: CLI_ISSUES_URL }
  unset_variables = {}

  if CUSTOM_HOMEBREW_TAP
    unset_variables[:CUSTOM_HOMEBREW_TAP] = CUSTOM_HOMEBREW_TAP
  end

  if CUSTOM_BREW_COMMAND
    unset_variables[:CUSTOM_BREW_COMMAND] = CUSTOM_BREW_COMMAND
  end

  if auth
    unset_variables.merge! CLI_GIT_NAME:     auth["info"]["name"],
                           CLI_GIT_EMAIL:    auth["info"]["email"],
                           CLI_GITHUB_USER:  auth["info"]["nickname"],
                           CLI_GITHUB_TOKEN: auth["credentials"]["token"],
                           CLI_LOG_TOKEN:    ENV["LVL_CLI_LOG_TOKEN"]
  end

  env_sub(content, set_variables, set: true)
  env_sub(content, unset_variables, set: false)

  # Manually set X-Frame-Options because Rack::Protection won't set it on
  # non-HTML files:
  # https://github.com/sinatra/sinatra/blob/v2.0.7/rack-protection/lib/rack/protection/frame_options.rb#L32
  headers["X-Frame-Options"] = "DENY"
  content_type = if params["text"]
    "text/plain"
  else
    "application/octet-stream"
  end
  erb content, content_type: content_type
end

get "/install-cli-win.sh" do
  auth = session[:auth]

  if !auth && GITHUB_KEY && GITHUB_SECRET
    query = request.query_string
    query = "?#{query}" if query && !query.empty?
    session[:return_to] = "#{request.path}#{query}"
    redirect to "/auth/github"
  end

  script = File.expand_path("#{File.dirname(__FILE__)}/../bin/install-cli-win.sh")
  content = IO.read(script)

  unset_variables = {}

  if auth
    unset_variables.merge! CLI_GIT_NAME:     auth["info"]["name"],
                           CLI_GIT_EMAIL:    auth["info"]["email"],
                           CLI_GITHUB_USER:  auth["info"]["nickname"],
                           CLI_GITHUB_TOKEN: auth["credentials"]["token"],
                           CLI_LOG_TOKEN:    ENV["LVL_CLI_LOG_TOKEN"]
  end

  env_sub(content, unset_variables, set: false)

  # Manually set X-Frame-Options because Rack::Protection won't set it on
  # non-HTML files:
  # https://github.com/sinatra/sinatra/blob/v2.0.7/rack-protection/lib/rack/protection/frame_options.rb#L32
  headers["X-Frame-Options"] = "DENY"
  content_type = if params["text"]
    "text/plain"
  else
    "application/octet-stream"
  end
  erb content, content_type: content_type
end

get "/install-cli-win.cmd" do
  auth = session[:auth]

  if !auth && GITHUB_KEY && GITHUB_SECRET
    query = request.query_string
    query = "?#{query}" if query && !query.empty?
    session[:return_to] = "#{request.path}#{query}"
    redirect to "/auth/github"
  end

  script = File.expand_path("#{File.dirname(__FILE__)}/../bin/install-cli-win.cmd")
  content = IO.read(script)

  unset_variables = {}

  if auth
    unset_variables.merge! CLI_GIT_NAME:     auth["info"]["name"],
                           CLI_GIT_EMAIL:    auth["info"]["email"],
                           CLI_GITHUB_USER:  auth["info"]["nickname"],
                           CLI_GITHUB_TOKEN: auth["credentials"]["token"],
                           CLI_LOG_TOKEN:    ENV["LVL_CLI_LOG_TOKEN"]
  end

  env_sub(content, unset_variables, set: false)

  # Manually set X-Frame-Options because Rack::Protection won't set it on
  # non-HTML files:
  # https://github.com/sinatra/sinatra/blob/v2.0.7/rack-protection/lib/rack/protection/frame_options.rb#L32
  headers["X-Frame-Options"] = "DENY"
  content_type = if params["text"]
    "text/plain"
  else
    "application/octet-stream"
  end
  erb content, content_type: content_type
end

private

def env_sub(content, variables, set:)
  variables.each do |key, value|
    next if value.to_s.empty?
    regex = if set
      /^#{key}='.*'$/
    else
      /# #{key}=$/
    end
    escaped_value = value.gsub(/'/, "\\\\\\\\'")
    content.gsub!(regex, "#{key}='#{escaped_value}'")
  end
end
