require 'rails_helper'

feature 'Account permission' do
  let(:account) { FactoryGirl.create(:account, :with_schema) }
  before do
    set_subdomain(account.subdomain)
  end

  scenario "cannot access the account if not owner or a user" do
    visit root_url
    sign_in_msg = "You need to sign in or sign up before continuing."

    expect(page).to have_content(sign_in_msg)
  end

  context "account's owner" do
    let(:user) { account.owner }

    before do
      login_as user
    end

    it 'can see the account' do
      visit root_url
      expect(page.current_url).to eql(root_url)
    end
  end

  context "an user of that account" do
    let(:user) { FactoryGirl.create(:user) }

    before do
      account.users << user
      login_as user
    end

    it 'can see the account' do
      visit root_url
      expect(page.current_url).to eql(root_url)
    end
  end

  context 'unauthorized permission' do
    let(:user) { FactoryGirl.create(:user) }

    before do
      login_as user
    end

    it 'cannot see the account' do
      visit root_url
      # expect(page).to have_content("You are not permitted to view that account.")
      expect(page.current_url).to eql(root_url(subdomain: nil))
    end
  end
end
