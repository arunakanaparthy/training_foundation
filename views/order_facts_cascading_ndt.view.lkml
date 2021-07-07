view: order_facts_cascading_ndt {

   derived_table: {
    explore_source: order_items {
      column: total_orders_by_user { field: order_facts_ndt.total_orders_by_user }
      column: total_cost { field: inventory_items.total_cost }
      column: created_month { field: order_facts_ndt.created_month }
      column: user_id { field: order_facts_ndt.user_id }
    }
  }
  dimension: total_orders_by_user {
    type: number
  }
  dimension: total_cost {
    value_format: "$#,##0.00"
    type: number
  }
  dimension: created_month {
    type: date_month
  }
  dimension: user_id {
    primary_key: yes
    type: number
  }
}
