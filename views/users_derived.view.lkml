include: "/views/users.view"
include: "/views/order_items.view"
view: users_extended {
  extends: [users]

 #String, Number, YesNo, tier, case, time, duration,
  dimension: full_name {
    type: string
    sql: ${first_name}||' '||${last_name} ;;
  }

  ##Number Dimension
  dimension:days_since_signup {
    type: number
    sql: datediff(day, ${created_date},current_date) ;;
  }

  ##duration
  dimension_group: since_signup {
    type: duration
    intervals: [
      ,week
      ,month
      ,year
    ]
    sql_start: ${created_time};;
    sql_end: current_date ;;
  }

  ##Boolean
  dimension: is_new_customer {
    type: yesno
    sql: ${days_since_signup}<=90 ;;
  }

  ###case
  dimension: customer_type {
    case: {
      when: {
        sql: ${days_since_signup}<=90 ;;
        label: "New Customer"
      }
      else: "Old Customer"
    }
  }

  dimension: customer_type_2 {
    type: string
    sql: case when ${days_since_signup}<=90 then "New Customer"  else "Old Customer";;
  }

  dimension: region {
    case: {
      when: {
        sql: ${state} in('xyz');;
        label:"xyz"
      }
      when: {
        sql: ${state} in('New Jersey','New York');;
        label:"Mid-Atlantic"
      }
      when: {
        sql: ${state} in('Ohio','Kansas','Indiana');;
        label:"Midwest"
      }
      when: {
        sql: ${state} in('Florida','Georgia');;
        label:"Southeast"
      }
      when: {
        sql: ${state} in('California','Washington');;
        label:"Pacific"
      }
    }
  }

  dimension: region2 {
    type: string
    sql: CASE
        WHEN (users."STATE") in('XYZ') THEN 'XYZ'
        WHEN (users."STATE") in('New Jersey','New York') THEN 'Mid-Atlantic'
        WHEN (users."STATE") in('Ohio','Kansas','Indiana') THEN 'Midwest'
        WHEN (users."STATE") in('Florida','Georgia') THEN 'Southeast'
        WHEN (users."STATE") in('California','Washington') THEN 'Pacific'
        END;;
  }

  ##Tiers
  dimension: days_since_signup_tier {
    type: tier
    sql:  ${days_since_signup} ;;
    tiers: [0,30,60,90,120,150]
    style: integer
  }


  ####Measures########
  measure:count_female_users{
    type: count
    filters:[gender: "Female"]
  }

  measure: count_female_rollup {
    type: running_total
    sql:  ${count_female_users};;
  }

  measure: percent_female_users {
    type: number
    sql: ${count_female_users}/NULLIF(${users_extended.count},0) ;;
    value_format_name: percent_2
  }

##Cross Reference
  measure: days_since_last_order {
    type: number
    sql: datediff(day,${order_items.max_order_date},current_date) ;;
  }

  measure: user_activity {
    case: {
      when: {
        sql: ${days_since_last_order}<=30 ;;
        label: "Active"
      }
      else: "Inactive"
    }
  }

  # measure: active_customer_count {
  #   type: count_distinct
  #   sql: case when ${user_activity}="Active" then 1 else 0 ;;
  # }
}


explore: users_extended {
  #group_label: "Group Label Training"
  #sql_always_where: ${order_items.created_date}>='2020-01-01' ;;
  #sql_always_having: ${order_items.count}>10 ;;
  always_filter: {
    filters: [country:"USA"]
  }
  access_filter: {
    field: state
    user_attribute: state
  }
  conditionally_filter: {
    filters: [order_items.created_year:"2 years"]
    unless: [users_extended.id, users_extended.full_name]
  }
  join: order_items {
   # fields: [detail*]
    type: left_outer
    sql_on: ${users_extended.id}=${order_items.user_id} ;;
    relationship: one_to_many
  }
}
