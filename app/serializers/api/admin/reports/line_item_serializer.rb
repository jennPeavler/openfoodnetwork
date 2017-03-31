class Api::Admin::Reports::LineItemSerializer < ActiveModel::Serializer
  attributes :id, :quantity, :max_quantity, :price, :price_with_fees, :full_name, :cost, :distribution_fee

  has_one :order, serializer: Api::Admin::IdSerializer
  has_one :product, serializer: Api::Admin::IdNameSerializer
  has_one :variant, serializer: Api::Admin::IdSerializer

  def price
    object.amount.to_f
  end

  def price_with_fees
    object.amount_with_adjustments.to_f
  end

  def cost
    object.price * object.quantity
  end
end