require 'rails_helper'

RSpec.describe 'Squadron routes', type: :request do
  let(:squadron) { create :squadron }

  before(:each) { login_squadron squadron }

  describe 'GET /squadrons/:id' do
    it "responds with information about the current squadron" do
      api_request :get, "/squadrons/#{squadron.to_param}.json"
      expect(response).to have_http_status(:success)
      expect(response).to match_json_schema('squadron')
    end
  end

  describe 'PATCH /squadron' do
    it "updates the squadron" do
      api_request :patch, '/squadron.json',
                  params: {squadron: attributes_for(:squadron)}
      expect(response).to have_http_status(:success)
      expect(response).to match_json_schema('squadron')
    end

    it "responds with errors" do
      api_request :patch, '/squadron.json',
                  params: {squadron: attributes_for(:squadron).merge(name: ' ')}
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).
          to match_json_expression(errors: {name: ["can’t be blank"]})
    end
  end
end
