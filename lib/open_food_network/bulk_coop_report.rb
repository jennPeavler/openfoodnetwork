require 'open_food_network/reports/report'
require 'open_food_network/reports/bulk_coop_supplier_report'
require 'open_food_network/reports/bulk_coop_allocation_report'

module OpenFoodNetwork
  class BulkCoopReport < Reports::Report

    def initialize(user, params = {})
      @params = params
      @user = user

      @supplier_report = OpenFoodNetwork::Reports::BulkCoopSupplierReport.new
      @allocation_report = OpenFoodNetwork::Reports::BulkCoopAllocationReport.new
    end

    def header
      case params[:report_type]
      when "bulk_coop_supplier_report"
        @supplier_report.header
      when "bulk_coop_allocation"
        @allocation_report.header
      when "bulk_coop_packing_sheets"
        ["Customer", "Product", "Variant", "Sum Total"]
      when "bulk_coop_customer_payments"
        ["Customer", "Date of Order", "Total Cost", "Amount Owing", "Amount Paid"]
      else
        ["Supplier", "Product", "Bulk Unit Size", "Variant", "Weight", "Sum Total", "Sum Max Total", "Units Required", "Remainder"]
      end
    end

    def rules
      case params[:report_type]
      when "bulk_coop_supplier_report"
        @supplier_report.rules
      when "bulk_coop_allocation"
        @allocation_report.rules
      when "bulk_coop_packing_sheets"
        [ { group_by: proc { |li| li.product },
          sort_by: proc { |product| product.name } },
          { group_by: proc { |li| li.full_name },
          sort_by: proc { |full_name| full_name } },
          { group_by: proc { |li| li.order },
          sort_by: proc { |order| order.to_s } } ]
      when "bulk_coop_customer_payments"
        [ { group_by: proc { |li| li.order },
          sort_by: proc { |order|  order.completed_at } } ]
      else
        [ { group_by: proc { |li| li.product.supplier },
        sort_by: proc { |supplier| supplier.name } },
        { group_by: proc { |li| li.product },
        sort_by: proc { |product| product.name },
        summary_columns: [ proc { |lis| lis.first.product.supplier.name },
          proc { |lis| lis.first.product.name },
          proc { |lis| lis.first.product.group_buy_unit_size || 0.0 },
          proc { |lis| "" },
          proc { |lis| "" },
          proc { |lis| lis.sum { |li| li.quantity * (li.weight_from_unit_value || 0) } },
          proc { |lis| lis.sum { |li| (li.max_quantity || 0) * (li.weight_from_unit_value || 0) } },
          proc { |lis| ( (lis.first.product.group_buy_unit_size || 0).zero? ? 0 : ( lis.sum { |li| ( [li.max_quantity || 0, li.quantity || 0].max ) * (li.weight_from_unit_value || 0) } / lis.first.product.group_buy_unit_size ) ).floor },
          proc { |lis| lis.sum { |li| ( [li.max_quantity || 0, li.quantity || 0].max ) * (li.weight_from_unit_value || 0) } - ( ( (lis.first.product.group_buy_unit_size || 0).zero? ? 0 : ( lis.sum { |li| ( [li.max_quantity || 0, li.quantity || 0].max ) * (li.weight_from_unit_value || 0) } / lis.first.product.group_buy_unit_size ) ).floor * (lis.first.product.group_buy_unit_size || 0) ) } ] },
        { group_by: proc { |li| li.full_name },
        sort_by: proc { |full_name| full_name } } ]
      end
    end

    def columns
      case params[:report_type]
      when "bulk_coop_supplier_report"
        @supplier_report.columns
      when "bulk_coop_allocation"
        @allocation_report.columns
      when "bulk_coop_packing_sheets"
        [ proc { |lis| lis.first.order.bill_address.firstname + " " + lis.first.order.bill_address.lastname },
          proc { |lis| lis.first.product.name },
          proc { |lis| lis.first.full_name },
          proc { |lis|  lis.sum { |li| li.quantity } } ]
      when "bulk_coop_customer_payments"
        [ proc { |lis| lis.first.order.bill_address.firstname + " " + lis.first.order.bill_address.lastname },
          proc { |lis| lis.first.order.completed_at.to_s },
          proc { |lis| lis.map { |li| li.order }.uniq.sum { |o| o.total } },
          proc { |lis| lis.map { |li| li.order }.uniq.sum { |o| o.outstanding_balance } },
          proc { |lis| lis.map { |li| li.order }.uniq.sum { |o| o.payment_total } } ]
      else
        [ proc { |lis| lis.first.product.supplier.name },
          proc { |lis| lis.first.product.name },
          proc { |lis| lis.first.product.group_buy_unit_size || 0.0 },
          proc { |lis| lis.first.full_name },
          proc { |lis| lis.first.weight_from_unit_value || 0 },
          proc { |lis| lis.sum { |li| li.quantity } },
          proc { |lis| lis.sum { |li| li.max_quantity || 0 } },
          proc { |lis| "" },
          proc { |lis| "" } ]
      end
    end

    private

    def permissions
      return @permissions unless @permissions.nil?
      @permissions = OpenFoodNetwork::Permissions.new(@user)
    end
  end
end
