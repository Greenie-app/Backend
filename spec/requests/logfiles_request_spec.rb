require 'rails_helper'

RSpec.describe 'Logfiles routes', type: :request do
  let(:squadron) { FactoryBot.create :squadron }

  before(:each) { login_as squadron }

  describe 'GET /squadron/logfiles' do
    before :each do
      FactoryBot.create_list :logfile, 10, squadron: squadron
    end

    it "lists logfiles" do
      api_request :get, '/squadron/logfiles.json'
      expect(response).to have_http_status(:success)
      expect(response).to match_json_schema('logfiles')
    end

    it "paginates" do
      api_request :get, '/squadron/logfiles.json?page=1&per_page=5'
      expect(response).to have_http_status(:success)
      expect(response.headers['X-Page']).to eq('1')
      expect(response.headers['X-Per-Page']).to eq('5')
      expect(response.headers['X-Count']).to eq('10')
      expect(response).to match_json_schema('logfiles')

      api_request :get, '/squadron/logfiles.json?page=2&per_page=5'
      expect(response).to have_http_status(:success)
      expect(response.headers['X-Page']).to eq('2')
      expect(response.headers['X-Per-Page']).to eq('5')
      expect(response.headers['X-Count']).to eq('10')
      expect(response).to match_json_schema('logfiles')
    end
  end

  describe 'POST /squadron/logfiles' do
    it "uploads a logfile" do
      api_request :post, '/squadron/logfiles.json', params: {logfile: {files: [fixture_file_upload('dcs.log', 'text/plain')]}}
      expect(response).to have_http_status(:success)
      expect(squadron.logfiles.count).to eq(1)
      expect(response).to match_json_schema('logfile')
    end
  end
end
