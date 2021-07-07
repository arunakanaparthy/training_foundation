view: dynamic_filters {
  derived_table: {
    sql: SELECT
          order_items."ID"  AS "order_items.id",
          order_items."ORDER_ID"  AS "order_items.order_id",
          order_items."SALE_PRICE"  AS "order_items.sale_price",
          order_items."CREATED_AT"  AS "order_items.created",
          products."BRAND"  AS "products.brand",
          products."CATEGORY"  AS "products.category",
          products."COST"  AS "products.cost"
      FROM "PUBLIC"."ORDER_ITEMS"
           AS order_items
      LEFT JOIN "PUBLIC"."INVENTORY_ITEMS"
           AS inventory_items ON (order_items."INVENTORY_ITEM_ID") = (inventory_items."ID")
      LEFT JOIN "PUBLIC"."PRODUCTS"
           AS products ON (inventory_items."PRODUCT_ID") = (products."ID")
       ;;
  }

  measure: count {
    type: count
    drill_fields: [detail*]
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
      quarter_of_year,
      fiscal_quarter_of_year,
      year
    ]
    sql:CONVERT_TIMEZONE('UTC','@{timezone}',${TABLE}."order_items.created")  ;;
    convert_tz: no
    html: {% if created_month._in_query %}
              {{ created_month._rendered_value | append: "-01" | date: "%b %Y" }}
          {% elsif created_quarter._in_query %}
              F{{ created_fiscal_quarter_of_year._rendered_value }} {{created_year._rendered_value}}
          {% else %} {{value}} {% endif %} ;;

    }

    dimension: order_items_id {
      type: number
      sql: ${TABLE}."order_items.id" ;;
    }

    dimension: order_items_order_id {
      type: number
      sql: ${TABLE}."order_items.order_id" ;;
    }

    dimension: order_items_sale_price {
      type: number
      sql: ${TABLE}."order_items.sale_price" ;;
    }

    dimension: products_brand {
      type: string
      sql: ${TABLE}."products.brand" ;;
      link: {
        label: "Search on Google"
        url: "https://www.google.com/search?q={{value | url_encode}}"
        icon_url : "https://www.google.com/favicon.ico"
      }
      link: {
        label: "Go to Dashboard"
        url: "/dashboards-next/20?Country=UK,USA&Age%20Tier=&Category=&Gender={{_user_attributes['gender']}}&Brand={{value | url_encode}}&State={{_user_attributes['state']}}"
        icon_url : "https://www.looker.com/favicon.ico"
      }
    }

    dimension: products_category {
      type: string
      sql: ${TABLE}."products.category" ;;
      html: <p  style="color: red; font-size: 100%;background-color:#CDCDCD; width:100%;height:200%">{{value}}</p> ;;
    }

    dimension: products_cost {
      type: number
      sql: ${TABLE}."products.cost" ;;
    }

    ### Derived measures and dimensions
    measure: total_sales {
      type: sum
      sql: ${order_items_sale_price} ;;
      value_format_name: usd
      html: {% if value >= 500000 %}
            <p style="color: red; font-size: 150%">{{ rendered_value }}</p>
          {% elsif (value >100000 && value <500000) %}
            <p style="color: black; font-size:125%">{{ linked_value }}</p>
          {% else %}
            <p style="color: blue; font-size:90%">{{ value }}</p>
          {% endif %};;
      drill_fields: [order_items_order_id,products_category,order_items_sale_price]
    }

    ### Brand Ray-Ban Performance
    measure: brand_rayban_sales {
      hidden: yes
      type: sum
      sql: ${order_items_sale_price} ;;
      filters: [
        products_brand: "Ray-Ban"
      ]
    }

    measure: brand_rayban_share {
      type: number
      sql: 1.0*(${brand_rayban_sales}/Nullif(${total_sales},0) );;
      value_format_name: percent_2
    }

############ Parameters with liquid ##############3
## Step 1: User chooses the brand
## Step 2: update dynamic dimension based on the choice
## Step 3: Create measures with filters to dynaamic dimension

    parameter: brand_parameter {
      type: string
      allowed_value: {
        label: "Ray-Ban"
        value: "Ray-Ban"
      }
      allowed_value: {
        label: "Adidas"
        value: "adidas"
      }
      allowed_value: {
        label: "Dockers"
        value: "Dockers"
      }
      allowed_value: {
        label: "Others"
        value: "others"
      }
      default_value: "Ray-Ban"
    }

    ##Dimension to buckets non focus brands to "Others"
    dimension: focus_brands {
      hidden: yes
      case: {
        when: {
          sql: ${products_brand} = 'Ray-Ban' ;;
          label: "Ray-Ban"
        }
        when: {
          sql: ${products_brand} = 'Dockers' ;;
          label: "Dockers"
        }
        when: {
          sql: ${products_brand} = 'adidas' ;;
          label: "adidas"
        }
        else: "others"
      }
    }

    dimension: is_focus_brand_from_param {
      hidden: yes
      type: yesno
      sql: ${focus_brands}={%parameter brand_parameter %} ;;
    }

    measure: brand_y_sales {
      hidden: yes
      type: sum
      sql: ${order_items_sale_price} ;;
      filters: [is_focus_brand_from_param: "Yes"]
    }

    measure: brand_y_share {
      #label_from_parameter: brand_parameter
      # label:
      # "{% if brand_parameter._parameter_value == \"'Ray-Ban'\" %} (Param) Ray-Ban Share
      # {% elsif brand_parameter._parameter_value == \"'Dockers'\" %} (Param) Dockers Share
      # {% elsif brand_parameter._parameter_value == \"'adidas'\" %}(Param) Adidas Share
      # {% else %} (Param) Other's Share {% endif %}"
      type: number
      sql: 1.0*(${brand_y_sales}/Nullif(${total_sales},0) );;
      value_format_name: percent_2
    }

    ############ Templated Filters ##############3
    parameter: brand_filter {
      description: "Dont go beyond 2 years"
      type: string
      suggest_dimension: products_brand
      suggest_explore: dynamic_filters
      default_value: "Ray-Ban"
    }

    dimension: is_selected_brand {
      hidden: yes
      type: yesno
      sql: {% condition brand_filter %}${products_brand}{% endcondition %} ;;
      ##The above sql evaluates to (brand_filter(selected) = products_brand) ?
    }
    measure: brand_x_sales {
      hidden: yes
      type: sum
      sql: ${order_items_sale_price} ;;
      filters: [is_selected_brand: "Yes"]
    }

    measure: brand_x_share {
      type: number
      sql: 1.0*(${brand_x_sales}/Nullif(${total_sales},0) );;
      value_format_name: percent_2
    }

    set: detail {
      fields: [
        order_items_id,
        order_items_order_id,
        order_items_sale_price,
        products_brand,
        products_category,
        products_cost
      ]
    }
  }

##   liquid  variable name
# value
# rendered_value
# link
# linked_value
# filterable_value
#  _user_attributes['<name of the attribute>']
#

  explore: dynamic_filters {}
