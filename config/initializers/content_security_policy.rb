# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy
# For further information see the following documentation
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy

# Bugsnag requires:
# - connect-src 'https://sessions.bugsnag.com'
#
# AWS assets require:
# - img-src 'https://avfacts.s3.us-west-2.amazonaws.com'
# - media-src <cloudfront url>
#
# Vue.js in development requires:
# - connect-src 'ws://localhost:3035' 'http://localhost:3035'

extra_image_sources = %w[
    https://avfacts.s3.us-west-2.amazonaws.com
]
extra_script_sources = [
]
extra_connect_sources = %w[
  https://sessions.bugsnag.com
]

if Rails.env.development? || Rails.env.cypress?
  extra_script_sources << :unsafe_eval << :unsafe_inline
  extra_connect_sources << 'ws://localhost:3035' << 'http://localhost:3035'
end

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self, :data
    policy.img_src     :self, :data, *extra_image_sources
    policy.object_src  :none
    policy.script_src  :self, *extra_script_sources
    policy.style_src   :self
    policy.media_src   :self

    policy.child_src :blob
    policy.connect_src :self, *extra_connect_sources

    # Specify URI for violation reports
    # policy.report_uri "/csp-violation-report-endpoint"
  end

  # Generate session nonces for permitted importmap and inline scripts
  config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  config.content_security_policy_nonce_directives = %w(script-src)

  # Report CSP violations to a specified URI. See:
  # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy-Report-Only
  # config.content_security_policy_report_only = true
end
