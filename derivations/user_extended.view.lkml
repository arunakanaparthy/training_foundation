include: "/views/users.view"
view: user_extended {
  extends: ["users"]


  ###custom
  dimension: full_name {
    type: string
    sql: ${first_name} ||'  '||${last_name} ;;
  }
 }
