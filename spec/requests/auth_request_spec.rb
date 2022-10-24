# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Auth routes" do
  describe "POST /squadrons" do
    it "signs up a new squadron" do
      post "/squadrons.json", params: {squadron: attributes_for(:squadron)}
      expect(response).to have_http_status(:success)
      expect(response.body).to match_json_schema("squadron")
    end

    it "responds with validation errors" do
      post "/squadrons.json", params: {squadron: attributes_for(:squadron).merge(name: " ")}
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to match_json_expression(
                                   errors: {name: ["can’t be blank"]}
                                 )
    end
  end

  describe "PATCH /squadron/password" do
    let(:squadron) { create :squadron }

    before(:each) { login_squadron squadron }

    it "updates a password" do
      api_request :patch, "/squadron/password.json",
                  params: {squadron: {password: "newpassword", password_confirmation: "newpassword", current_password: "password123"}}
      expect(response).to have_http_status(:success)
    end

    it "responds with validation errors" do
      api_request :patch, "/squadron/password.json",
                  params: {squadron: {password: "newpassword", password_confirmation: "newpassword", current_password: "oops"}}
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to match_json_expression(
                                   errors: {
                                       current_password: %w[invalid]
                                   }
                                 )
    end
  end

  describe "PUT /squadron/password" do
    let(:squadron) { create :squadron }

    before(:each) { login_squadron squadron }

    it "updates a password" do
      api_request :put, "/squadron/password.json",
                  params: {squadron: {password: "newpassword", password_confirmation: "newpassword", current_password: "password123"}}
      expect(response).to have_http_status(:success)
    end

    it "responds with validation errors" do
      api_request :put, "/squadron/password.json",
                  params: {squadron: {password: "newpassword", password_confirmation: "newpassword", current_password: "oops"}}
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to match_json_expression(
                                   errors: {
                                       current_password: %w[invalid]
                                   }
                                 )
    end
  end

  describe "DELETE /squadron" do
    let(:squadron) { create :squadron }

    before(:each) { login_squadron squadron }

    it "deletes a squadron" do
      api_request :delete, "/squadron.json"
      expect(response).to have_http_status(:success)
      expect { squadron.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "POST /forgot_password" do
    let(:squadron) { create :squadron }

    before(:each) { login_squadron squadron }

    it "creates and emails a reset token" do
      post "/forgot_password.json", params: {squadron: {email: squadron.email}}
      expect(response).to have_http_status(:success)
      expect(ApplicationMailer.deliveries.size).to be(1)
    end

    it "handles an unknown email" do
      post "/forgot_password.json", params: {squadron: {email: "unknown@email.com"}}
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to match_json_expression(
                                   errors: {email: ["not found"]}
                                 )
    end
  end

  describe "PATCH /forgot_password" do
    let(:squadron) { create :squadron }
    let :token do
      post "/forgot_password.json", params: {squadron: {email: squadron.email}}
      ActionMailer::Base.deliveries.first.body.to_s.
          match(%r{"http://frontend\.example\.com/#/reset_password/(.+?)"})[1]
    end

    it "updates a squadron password from a reset token" do
      patch "/forgot_password.json",
            params: {squadron: {password: "newpassword", password_confirmation: "newpassword", reset_password_token: token}}
      expect(response).to have_http_status(:success)
    end

    it "rejects an incorrect reset token" do
      patch "/forgot_password.json",
            params: {squadron: {password: "newpassword", password_confirmation: "newpassword", reset_password_token: "incorrect-token"}}
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to match_json_expression(
                                   errors: {reset_password_token: %w[invalid]}
                                 )
    end
  end

  describe "POST /login" do
    let(:squadron) { create :squadron }

    it "logs in a squadron by username" do
      post "/login.json", params: {squadron: {username: squadron.username, password: "password123"}}
      expect(response).to have_http_status(:success)
      expect(response.body).to match_json_schema("squadron")
      expect(response.headers["Authorization"]).to be_present
    end

    it "rejects an invalid username" do
      post "/login.json", params: {squadron: {username: squadron.username, password: "oops"}}
      expect(response).to have_http_status(:unauthorized)
      expect(response.body).to match_json_expression(
                                   error: "Invalid Username or password."
                                 )
      expect(response.headers["Authorization"]).not_to be_present
    end
  end

  describe "DELETE /logout" do
    let(:squadron) { create :squadron }

    before(:each) { login_squadron squadron }

    it "logs out a user" do
      api_request :delete, "/logout.json"
      expect(response).to have_http_status(:success)
      expect(response.headers["Authorization"]).not_to be_present
    end
  end
end
