require 'spec_helper'

include Warden::Test::Helpers

describe 'Auction management' do
  include CategorySeedData

  describe "for signed-in users" do
    before :each do
      @user = FactoryGirl.create(:user)
      login_as @user, scope: :user
    end

    describe "auction creation" do
      before do
        FactoryGirl.create(:category, :parent => nil)
        visit new_auction_path
      end

      it "should have the correct title" do
        page.should have_content(I18n.t("auction.titles.new"))
      end

      it 'creates an auction' do
        lambda do
          fill_in I18n.t('formtastic.labels.auction.title'), with: 'Auction title'
          check Category.root.name
          within("#auction_condition_input") do
            choose "auction_condition_new"
          end

          if @user.is_a? LegalEntity
            fill_in I18n.t('formtastic.labels.auction.basic_price'), with: '99,99'
            select I18n.t("enumerize.auction.basic_price_amount.kilogram"), from: I18n.t('formtastic.labels.auction.basic_price_amount')
          end
          fill_in I18n.t('formtastic.labels.auction.content'), with: 'Auction content'
          check "auction_transport_pickup"
          select I18n.t("enumerize.auction.default_transport.pickup") , from: I18n.t('formtastic.labels.auction.default_transport')
          fill_in 'auction_transport_details', with: 'transport_details'
          check "auction_payment_cash"
          select I18n.t("enumerize.auction.default_payment.cash") , from: I18n.t('formtastic.labels.auction.default_payment')
          fill_in 'auction_payment_details', with: 'payment_details'

          find(".double_check-step-inputs").find(".action").find("input").click
        end.should change(Auction.unscoped, :count).by 1
      end

      it 'shows sub-categories' do
        setup_categories

        visit new_auction_path
        hardware_id = Category.find_by_name!('Hardware').id

        page.should have_selector("label[for$='auction_categories_and_ancestors_#{hardware_id}']", visible: false)
        check "auction_categories_and_ancestors_#{Category.find_by_name!('Elektronik').id}"
        check "auction_categories_and_ancestors_#{Category.find_by_name!('Computer').id}"
        page.should have_selector("label[for$='auction_categories_and_ancestors_#{hardware_id}']", visible: true)
      end
    end

    describe "auction search", search: true do
      before do
        auction = FactoryGirl.create :auction, title: 'chunky bacon'
        Sunspot.commit
        visit root_path
      end

      context "when submitting" do
        before { fill_in 'search_input', with: 'chunky bacon' }

        it "should show the page with search results" do
          click_button 'Suche'
          page.should have_link 'chunky bacon'
        end

        it "should rescue an Errno::ECONNREFUSED" do
          Sunspot.stub(:search).and_raise(Errno::ECONNREFUSED)
          click_button 'Suche'
          page.should have_content I18n.t 'auction.titles.sunspot_failure'
        end
      end
    end
  end
end