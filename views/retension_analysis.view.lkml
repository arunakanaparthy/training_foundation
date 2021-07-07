view: retension_analysis {
  derived_table: {
    sql: SELECT
        order_items.order_id
        , order_items.user_id
        ,  order_items.created_at as  current_order_date
        , COUNT(DISTINCT repeat_order_items.id) AS number_subsequent_orders
        , MIN(repeat_order_items.created_at) AS next_order_date
        , MIN(repeat_order_items.order_id) AS next_order_id
      FROM order_items
      LEFT JOIN order_items repeat_order_items
        ON order_items.user_id = repeat_order_items.user_id
        AND order_items.created_at < repeat_order_items.created_at
        AND date_trunc('MONTH', order_items.created_at) != date_trunc('MONTH',  repeat_order_items.created_at)
      GROUP BY 1,2,3
       ;;
    persist_for: "24 hours"  ## Best practice would be to use `datagroup_trigger: ecommerce_etl` but we don't here for snowflake costs
  }

  dimension: order_id {
    type: number
    primary_key: yes
    sql: ${TABLE}.order_id ;;
  }

  dimension: user_id {
    type: number
    sql: ${TABLE}.order_id ;;
  }

  # dimension: next_order_id {
  #   type: number
  #   hidden: yes
  #   sql: ${TABLE}.next_order_id ;;
  # }

  dimension_group: next_transaction {
    type: duration
    sql_start: ${current_order_raw} ;;
    sql_end: ${next_order_raw} ;;
    intervals: [day,month]
    convert_tz: no
  }

  dimension: is_customer_retained {
    type: yesno
    sql: ${months_next_transaction}>=1 AND ${months_next_transaction} <  4 ;;
  }

  dimension_group:retention_period{
    type: time
    sql:  dateadd(month, 3,${current_order_raw});;
    timeframes: [month]
    convert_tz: no
  }

  # dimension: has_subsequent_order {
  #   type: yesno
  #   sql: ${next_order_id} > 0 ;;
  # }

  # dimension: number_subsequent_orders {
  #   type: number
  #   sql: ${TABLE}.number_subsequent_orders ;;
  # }

  dimension_group: next_order {
    type: time
    timeframes: [raw, date, month, time]
    sql: ${TABLE}.next_order_date ;;
    convert_tz: no
  }

  dimension_group: current_order {
    type: time
    timeframes: [raw, date, month, time]
    sql: ${TABLE}.current_order_date ;;
    convert_tz: no
  }

  measure: current_month_count {
    type: count_distinct
    sql: ${user_id} ;;
  }

  measure: retention_period_count {
    type: count_distinct
    sql: ${user_id} ;;
    filters: [is_customer_retained: "Yes"]
  }

  measure: retention_rate {
    type: number
    sql: ${retention_period_count}/nullif(${current_month_count},0) ;;
    value_format_name: percent_2
  }
}
explore: retension_analysis {}
