# Bugsnag requires:
# - connect-src 'https://sessions.bugsnag.com'
#
# AWS assets require:
# - img-src 'https://avfacts.s3.us-west-1.amazonaws.com'
# - media-src <cloudfront url>
#
# Vue.js in development requires:
# - connect-src 'ws://localhost:3035' 'http://localhost:3035'

extra_image_sources = %w[
    https://avfacts.s3.us-west-1.amazonaws.com
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

Rails.application.config.content_security_policy do |policy|
  policy.default_src :self
  policy.font_src    :self, :data
  policy.img_src     :self, :data, *extra_image_sources
  policy.object_src  :none
  policy.script_src  :self, *extra_script_sources
  policy.style_src   :self
  policy.media_src   :self

  policy.child_src :blob
  policy.connect_src :self, *extra_connect_sources
end

Rails.application.config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
