class CardsController < ApplicationController
  before_action :set_card, only: [:new, :index, :destroy]
  
  require "payjp"

  def new
    if @card.present?
      redirect_to cards_path
    else
      @card = Card.new
    end
  end

  def index
    if @card.present?
      Payjp.api_key = Rails.application.credentials[:payjp][:secret_key]
      customer = Payjp::Customer.retrieve(@card.customer_id)
      @default_card_information = customer.cards.retrieve(@card.card_id)
      @card_brand = @default_card_information.brand
      case @card_brand
      when "Visa"
        @card_src = "cards/visa.svg"
      when "JCB"
        @card_src = "cards/jcb.svg"
      when "MasterCard"
        @card_src = "cards/master-card.svg"
      when "American Express"
        @card_src = "cards/american_express.svg"
      when "Diners Club"
        @card_src = "cards/dinersclub.svg"
      when "Discover"
        @card_src = "cards/discover.svg"
      end
    end
  end

  def create #PayjpとCardのデータベースを作成
    Payjp.api_key = Rails.application.credentials[:payjp][:secret_key]

    if params['payjp-token'].blank?
      redirect_to new_card_path
    else
      customer = Payjp::Customer.create(
        card: params['payjp-token'],
        metadata: {user_id: current_user.id}
      )
      @card = Card.new(
        user_id: current_user.id,
        customer_id: customer.id,
        card_id: customer.default_card
      )
      if @card.save
        redirect_to cards_path
      else
        redirect_to action: "create"
      end
    end
  end

  def destroy #PayjpとCardデータベースを削除
    Payjp.api_key = Rails.application.credentials[:payjp][:secret_key]
    customer = Payjp::Customer.retrieve(@card.customer_id)
    customer.delete
    @card.delete
    redirect_to new_card_path
  end

  private
    def set_card
      @card = Card.find_by(user_id: current_user.id)
    end

end
