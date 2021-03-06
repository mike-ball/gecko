require 'gecko/record/base'

module Gecko
  module Record
    class Order < Base
      has_many :fulfillments
      has_many :invoices
      has_many :order_line_items

      belongs_to :company
      belongs_to :shipping_address,     class_name: "Address"
      belongs_to :billing_address,      class_name: "Address"
      belongs_to :user
      belongs_to :assignee,             class_name: "User"
      belongs_to :stock_location,       class_name: "Location"
      belongs_to :currency

      attribute :order_number,          String
      attribute :phone_number,          String
      attribute :email,                 String
      attribute :notes,                 String
      attribute :reference_number,      String
      attribute :status,                String
      attribute :packed_status,         String,     readonly: true
      attribute :fulfillment_status,    String,     readonly: true
      attribute :invoice_status,        String,     readonly: true
      attribute :invoice_numbers,       Hash[Integer => String], readonly: true
      attribute :payment_status,        String
      attribute :tax_type,              String
      attribute :issued_at,             Date
      attribute :ship_at,               Date
      attribute :tax_override,          String,     readonly: true
      attribute :tax_label,             String
      attribute :tracking_number,       String
      attribute :source_url,            String
      attribute :total,                 BigDecimal, readonly: true

      attribute :source_id,             String,     readonly: true

      ## DEPRECATED
      attribute :source,                String
    end

    class OrderAdapter < BaseAdapter
    end
  end
end
