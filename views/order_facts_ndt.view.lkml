view: order_facts_ndt {
    derived_table: {
      explore_source: order_items {
        column: order_id {}
        column: user_id {}
        column: total_sale_price {}
        column: created_time {}
        derived_column: order_rank {
          sql: RANK() OVER (PARTITION BY user_id ORDER BY created_time) ;;
        }
        #bind_all_filters: yes
      }
    }
    dimension: order_id {
      primary_key: yes
      type: number
    }
    dimension: user_id {
      type: number
    }
    dimension: total_sale_price {
      type: number
    }
    dimension_group: created {
      type: time
      timeframes: [
        raw,
        time,
        date,
        week,
        month,
        quarter,
        year
      ]
      sql: ${TABLE}.created_time ;;
    }
    dimension: order_rank {
      type: number
    }
   measure: total_orders_by_user {
      type: max
      sql: ${order_rank} ;;
    }
  }

  explore: order_facts_ndt {}
