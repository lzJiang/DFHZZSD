CLASS zcl_sdi002_util DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    METHODS check_0001
      IMPORTING ls_req TYPE zzs_sdi002_0001_in
      EXPORTING flag   TYPE bapi_mtype
                msg    TYPE bapi_msg.
    METHODS deal_0001
      IMPORTING VALUE(fsysid) TYPE zzefsysid OPTIONAL
      EXPORTING flag   TYPE bapi_mtype
                msg    TYPE bapi_msg
      CHANGING  ls_req TYPE zzs_sdi002_0001_in.
    METHODS deal_0001_fp
      EXPORTING flag   TYPE bapi_mtype
                msg    TYPE bapi_msg
      CHANGING  lv_sales_order TYPE vbeln.
    METHODS check_0002
      IMPORTING lt_req TYPE zzt_sdi002_0002_in
      EXPORTING flag   TYPE bapi_mtype
                msg    TYPE bapi_msg.
    METHODS deal_0002
      EXPORTING flag   TYPE bapi_mtype
                msg    TYPE bapi_msg
      CHANGING  lt_req TYPE zzt_sdi002_0002_in.
    METHODS deal_0002_act01
      EXPORTING flag   TYPE bapi_mtype
                msg    TYPE bapi_msg
      CHANGING  ls_req TYPE zzs_sdi002_0002_in.
    METHODS deal_0002_act02
      EXPORTING flag   TYPE bapi_mtype
                msg    TYPE bapi_msg
      CHANGING  ls_req TYPE zzs_sdi002_0002_in.
    METHODS deal_0002_act03
      EXPORTING flag   TYPE bapi_mtype
                msg    TYPE bapi_msg
      CHANGING  ls_req TYPE zzs_sdi002_0002_in.
    METHODS deal_0002_act04
      EXPORTING flag   TYPE bapi_mtype
                msg    TYPE bapi_msg
      CHANGING  ls_req TYPE zzs_sdi002_0002_in.
    METHODS deal_0002_act05
      EXPORTING flag   TYPE bapi_mtype
                msg    TYPE bapi_msg
      CHANGING  ls_req TYPE zzs_sdi002_0002_in.
    METHODS deal_0002_act01_return
      EXPORTING flag   TYPE bapi_mtype
                msg    TYPE bapi_msg
      CHANGING  ls_req TYPE zzs_sdi002_0002_in.
    METHODS deal_0002_act02_return
      EXPORTING flag   TYPE bapi_mtype
                msg    TYPE bapi_msg
      CHANGING  ls_req TYPE zzs_sdi002_0002_in.
    METHODS deal_0002_act03_return
      EXPORTING flag   TYPE bapi_mtype
                msg    TYPE bapi_msg
      CHANGING  ls_req TYPE zzs_sdi002_0002_in.
    METHODS deal_0002_act04_return
      EXPORTING flag   TYPE bapi_mtype
                msg    TYPE bapi_msg
      CHANGING  ls_req TYPE zzs_sdi002_0002_in.
    METHODS deal_0002_get_msg
      IMPORTING ls_failed    TYPE any
                ls_reported  TYPE any
                lv_component TYPE string
      EXPORTING msg          TYPE bapi_msg.
    METHODS save_zztsd_0001
      IMPORTING lv_sales_order     TYPE vbeln
      CHANGING  lt_zzt_sdi002_0001_out TYPE zzt_sdi002_0001_out_tab.
PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_SDI002_UTIL IMPLEMENTATION.


  METHOD check_0001.
    IF ls_req IS INITIAL.
      flag = 'E'.
      msg = |'传入项目为空'| .
      RETURN.
    ENDIF.

    "1.检查抬头
    IF ls_req-sales_order_type NE 'OR'
     AND ls_req-sales_order_type NE 'CBAR'
     AND ls_req-sales_order_type NE 'DR'.
      flag = 'E'.
      msg = '【销售凭证类型】传入值不支持，请检查'.
      RETURN.
    ENDIF.
    IF ls_req-sales_organization IS INITIAL.
      flag = 'E'.
      msg = '【销售组织】不能为空'.
      RETURN.
    ENDIF.
    IF ls_req-sold_to_party IS INITIAL.
      flag = 'E'.
      msg = '【售达方】不能为空'.
      RETURN.
    ENDIF.
    IF ls_req-purchase_order_by_customer IS INITIAL.
      flag = 'E'.
      msg = '【外围系统单号】不能为空'.
      RETURN.
    ELSE.
      SELECT SINGLE *
               FROM i_salesdocument WITH PRIVILEGED ACCESS
              WHERE purchaseorderbycustomer = @ls_req-purchase_order_by_customer
                AND salesdocumenttype NE 'L2'
              INTO @DATA(ls_salesorder).
      IF sy-subrc = 0 AND ls_req-sales_order_type = 'OR' .
        flag = 'E'.
        msg = |'外围系统单号'{ ls_req-purchase_order_by_customer }'已存在对应SAP销售订单'{ ls_salesorder-salesdocument }',请勿重复创建' |.
        RETURN.
      ENDIF.

    ENDIF.
    "2.检查行项目
    IF ls_req-to_item IS INITIAL OR ls_req-to_item-results[] IS INITIAL.
      flag = 'E'.
      msg = '行项目不能为空'.
      RETURN.
    ENDIF.
    LOOP AT ls_req-to_item-results[] INTO DATA(ls_item).
      IF ls_item-underlying_purchase_order_item IS INITIAL.
        flag = 'E'.
        msg = '【进销存订单行】不能为空'.
        RETURN.
      ENDIF.
      IF ls_item-material IS INITIAL.
        flag = 'E'.
        msg =  |'行'{ ls_item-underlying_purchase_order_item }'【物料编码】不能为空'| .
        RETURN.
      ENDIF.
      IF ls_item-requested_quantity IS INITIAL AND ls_req-sales_order_type NE 'DR'.
        flag = 'E'.
        msg = |'行'{ ls_item-underlying_purchase_order_item }'【订单数量】不能为空'| .
        RETURN.
      ENDIF.
      IF ls_item-requested_quantity_unit IS INITIAL.
        flag = 'E'.
        msg = |'行'{ ls_item-underlying_purchase_order_item }'【订单单位】不能为空'| .
        RETURN.
      ENDIF.
      IF ls_item-production_plant IS INITIAL AND ls_req-sales_order_type NE 'DR'.
        flag = 'E'.
        msg = |'行'{ ls_item-underlying_purchase_order_item }'【工厂】不能为空'| .
        RETURN.
      ENDIF.
*      IF ls_item-material_by_customer IS INITIAL.
*        flag = 'E'.
*        msg = |'行' { ls_item-underlying_purchase_order_item } '【客户物料】不能为空'|.
*        RETURN.
*      ENDIF.
      IF ls_item-to_pricing_element IS INITIAL OR ls_item-to_pricing_element-results[] IS INITIAL.
        flag = 'E'.
        msg = |'行'{ ls_item-underlying_purchase_order_item }'【价格】不能为空'| .
        RETURN.
      ELSE.
        LOOP AT ls_item-to_pricing_element-results[] TRANSPORTING NO FIELDS WHERE condition_rate_value IS NOT INITIAL.
          EXIT.
        ENDLOOP.
        IF sy-subrc NE 0.
          flag = 'E'.
          msg = |'行'{ ls_item-underlying_purchase_order_item }'【价格】不能为空'| .
          RETURN.
        ENDIF.
      ENDIF.
      IF ls_req-sales_order_type = 'CBAR'.
        IF ls_item-returnsrefundprocgmode NE 'N' AND ls_item-returnsrefundprocgmode  NE 'R'.
          flag = 'E'.
          msg = |退货订单行{ ls_item-underlying_purchase_order_item }【退货控制】传入值{ ls_item-returnsrefundprocgmode }不支持，请检查| .
          RETURN.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD check_0002.

    IF lt_req[] IS INITIAL.
      flag = 'E'.
      msg = |'传入项目为空'| .
      RETURN.
    ENDIF.

    DATA(lt_sale_sorder) = lt_req[].
    SORT lt_sale_sorder BY sales_order.
    DELETE ADJACENT DUPLICATES FROM lt_sale_sorder COMPARING sales_order.
    DATA(lv_lines) = lines( lt_sale_sorder ).
    IF lv_lines > 1.
      flag = 'E'.
      msg = |'单次只能传入单条销售订单号'| .
      RETURN.
    ENDIF.

    LOOP AT lt_req INTO DATA(ls_req).
      IF ls_req-sales_order IS INITIAL.
        flag = 'E'.
        msg = |'第'{ sy-tabix }'行【销售订单号】不能为空'| .
        RETURN.
      ENDIF.
      CASE ls_req-action.
        WHEN '01'.
          "行撤单
          IF ls_req-sales_order_item IS INITIAL.
            flag = 'E'.
            msg = |'第'{ sy-tabix }'行【销售订单行号】不能为空'| .
            RETURN.
          ENDIF.
        WHEN '02'.
          "行项目数量、金额、工厂修改
          IF ls_req-sales_order_item IS INITIAL.
            flag = 'E'.
            msg = |'第'{ sy-tabix }'行【销售订单行号】不能为空'| .
            RETURN.
          ENDIF.
          IF ls_req-requested_quantity IS INITIAL
          AND ls_req-plant IS INITIAL
          AND ls_req-condition_rate_value IS INITIAL .
            flag = 'E'.
            msg = |'行项目数量、金额、工厂修改操作时第'{ sy-tabix }'行【数量】/【工厂】/【价格】不能同时为空'| .
            RETURN.
          ENDIF.
        WHEN '03'.
          "行项目品种替换
          IF ls_req-sales_order_item IS INITIAL.
            flag = 'E'.
            msg = |'第'{ sy-tabix }'行【销售订单行号】不能为空'| .
            RETURN.
          ENDIF.
          IF ls_req-material IS INITIAL.
            flag = 'E'.
            msg = |'行项目品种替换操作时第'{ sy-tabix }'行【物料】不能为空'| .
            RETURN.
          ENDIF.
          IF ls_req-requested_quantity IS INITIAL.
            flag = 'E'.
            msg = |'行项目品种替换操作时第'{ sy-tabix }'行【数量】不能为空'| .
            RETURN.
          ENDIF.
          IF ls_req-requested_quantity_unit IS INITIAL.
            flag = 'E'.
            msg = |'行项目品种替换操作时第'{ sy-tabix }'行【单位】不能为空'| .
            RETURN.
          ENDIF.
          IF ls_req-plant IS INITIAL.
            flag = 'E'.
            msg = |'行项目品种替换操作时第'{ sy-tabix }'行【发货工厂】不能为空'| .
            RETURN.
          ENDIF.
          IF ls_req-condition_rate_value IS INITIAL.
            flag = 'E'.
            msg = |'行项目品种替换操作时第'{ sy-tabix }'行【价格】不能为空'| .
            RETURN.
          ENDIF.
        WHEN '05'.
          "修改抬头返利
          IF ls_req-condition_rate_value_rebates IS INITIAL.
            flag = 'E'.
            msg = |'抬头返利修改操作时第'{ sy-tabix }'行【价格】不能为空'| .
            RETURN.
          ENDIF.
        WHEN '04'.
          "新增行项目
          IF ls_req-underlying_purchase_order_item IS INITIAL.
            flag = 'E'.
            msg = |'第'{ sy-tabix }'行【进销存订单行编号】不能为空'| .
            RETURN.
          ENDIF.
          IF ls_req-material IS INITIAL.
            flag = 'E'.
            msg = |'新增行项目操作时第'{ sy-tabix }'行【物料】不能为空'| .
            RETURN.
          ENDIF.
          IF ls_req-requested_quantity IS INITIAL.
            flag = 'E'.
            msg = |'新增行项目操作时第'{ sy-tabix }'行【数量】不能为空'| .
            RETURN.
          ENDIF.
          IF ls_req-requested_quantity_unit IS INITIAL.
            flag = 'E'.
            msg = |'新增行项目操作时第'{ sy-tabix }'行【单位】不能为空'| .
            RETURN.
          ENDIF.
          IF ls_req-plant IS INITIAL.
            flag = 'E'.
            msg = |'新增行项目操作时第'{ sy-tabix }'行【发货工厂】不能为空'| .
            RETURN.
          ENDIF.
          IF ls_req-condition_rate_value IS INITIAL.
            flag = 'E'.
            msg = |'新增行项目操作时第'{ sy-tabix }'行【价格】不能为空'| .
            RETURN.
          ENDIF.
        WHEN OTHERS.
          flag = 'E'.
          msg = |'传入【操作类型】值异常'| .
          RETURN.
      ENDCASE.
    ENDLOOP.
  ENDMETHOD.


  METHOD deal_0001.
    DATA:lv_json TYPE string.
    DATA:lt_mapping TYPE /ui2/cl_json=>name_mappings.
    TYPES:BEGIN OF ty_heads,
            salesorder        TYPE string,
            customerreturn    TYPE string,
            creditmemorequest TYPE string,
            debitmemorequest  TYPE string,
          END OF ty_heads,
          BEGIN OF ty_ress,
            d TYPE ty_heads,
          END OF  ty_ress.
    TYPES BEGIN OF ty_item_return_price.
    TYPES: condition_type       TYPE string,
           condition_rate_value TYPE i_salesdocument-totalnetamount.
    TYPES END OF ty_item_return_price.
    TYPES BEGIN OF ty_item_return.
    TYPES: underlying_purchase_order_item TYPE string,
           material                       TYPE string,
           requested_quantity             TYPE menge_d,
           requested_quantity_unit        TYPE string,
           production_plant               TYPE string,
           material_by_customer           TYPE string,
           reference_sd_document          TYPE string,
           reference_sd_document_item     TYPE string,
           sales_order_item_category      TYPE string,
           purchase_order_by_customer     TYPE string,
           storage_location               TYPE string,
           custretitmfollowupactivity     TYPE string,
           nextfllwupactivityformatlinsp  TYPE string,
           returnsrefundtype              TYPE string,
           returnsrefundprocgmode         TYPE string,
           returnsrefundcode              TYPE string,
           returnsinspectioncode          TYPE string,
           retsinspiscrtedautomly         TYPE abap_bool,
           _itempricingelement            TYPE TABLE OF ty_item_return_price WITH DEFAULT KEY.
    TYPES END OF ty_item_return.
    TYPES BEGIN OF ty_return.
    TYPES: sales_order_type           TYPE string,
           sales_organization         TYPE string,
           distribution_channel       TYPE string,
           sddocumentreason           TYPE string,
           organization_division      TYPE string,
           transaction_currency       TYPE string,
           sold_to_party              TYPE string,
           customer_payment_terms     TYPE string,
           purchase_order_by_customer TYPE string,
           reference_sd_document      TYPE string,
           sales_district             TYPE string,
           _item                      TYPE TABLE OF ty_item_return WITH DEFAULT KEY.
    TYPES END OF ty_return.



    DATA:ls_return TYPE ty_return.
    DATA:ls_ress  TYPE ty_ress,
         ls_ress4 TYPE ty_heads.
    DATA:lv_flag_0                     TYPE char1,
         lv_purchase_order_by_customer TYPE i_salesdocument-purchaseorderbycustomer.

    TRY.
        IF ls_req-sales_order_type = 'CBAR'.
          "odata4
          DATA(lo_dest) = zzcl_comm_tool=>get_dest_odata4( ).
        ELSE.
          "odata2
          lo_dest = zzcl_comm_tool=>get_dest( ).
        ENDIF.
      CATCH cx_http_dest_provider_error INTO DATA(lx_http_dest_provider_error).
        EXIT.
    ENDTRY.

    lv_purchase_order_by_customer = ls_req-purchase_order_by_customer.
    SELECT SINGLE a~salesdocument AS sales_order,
           a~purchaseorderbycustomer AS purchase_order_by_customer,
           b~salesdocumentitem AS sales_order_item,
           b~purchaseorderbycustomer AS underlying_purchase_order_item
      FROM i_salesdocument WITH PRIVILEGED ACCESS AS a
      INNER JOIN i_salesdocumentitem  WITH PRIVILEGED ACCESS AS b
        ON a~salesdocument = b~salesdocument
     WHERE a~purchaseorderbycustomer = @lv_purchase_order_by_customer
       AND b~salesdocumentrjcnreason = ''
      INTO @DATA(ls_data).
    IF sy-subrc = 0 AND ( ls_req-sales_order_type = 'OR' OR ls_req-sales_order_type = 'DR' ).
      DATA(lv_created) = 'X'."是否已创建销售订单
      msg = ls_data-sales_order.
    ENDIF.
    IF lv_created IS INITIAL.
      "创建销售订单
      "填充固定值
      ls_req-distribution_channel = '10'.
      ls_req-organization_division = '10'.
      ls_req-transaction_currency = 'CNY'.
      IF fsysid = 'JXC' AND ls_req-sales_order_type = 'CBAR'.
        ls_req-sddocumentreason = '001'.
      ENDIF.
      IF fsysid = 'JXC'.
        ls_req-sales_district = 'Z00001'.
      ELSEIF fsysid = 'XYW'.
        ls_req-sales_district = 'Z00002'.
      ENDIF.
      LOOP AT ls_req-to_item-results ASSIGNING FIELD-SYMBOL(<fs_item>).
        CLEAR:lv_flag_0.
        <fs_item>-material_by_customer = <fs_item>-underlying_purchase_order_item.
        CLEAR:<fs_item>-underlying_purchase_order_item.
        LOOP AT <fs_item>-to_pricing_element-results[] ASSIGNING FIELD-SYMBOL(<fs_price>).
          <fs_price>-condition_type = 'ZPR0'.
          IF <fs_price>-condition_rate_value IS INITIAL OR <fs_price>-condition_rate_value = '0' OR <fs_price>-condition_rate_value = '0.00'.
            lv_flag_0 = 'X'.
            <fs_price>-condition_rate_value = '1'.
          ENDIF.
        ENDLOOP.
        IF lv_flag_0 = 'X'.
          <fs_item>-sales_order_item_category = 'CBXN'.
        ENDIF.
        IF ls_req-sales_order_type = 'CBAR'.
          SELECT SINGLE unitofmeasureisocode
                   FROM i_unitofmeasure WITH PRIVILEGED ACCESS
                  WHERE unitofmeasure_e = @<fs_item>-requested_quantity_unit
                   INTO @DATA(lv_isocode).
          <fs_item>-requested_quantity_unit = lv_isocode.
          <fs_item>-custretitmfollowupactivity = '0001'.
          <fs_item>-nextfllwupactivityformatlinsp = '0011'.
          <fs_item>-returnsrefundtype = ''.
*          <fs_item>-returnsrefundprocgmode = 'R'.
          IF <fs_item>-returnsrefundprocgmode = 'R'.
            <fs_item>-returnsrefundcode = '100'.
          ELSEIF <fs_item>-returnsrefundprocgmode = 'N'.
            <fs_item>-returnsrefundcode = ''.
          ENDIF.
          <fs_item>-returnsinspectioncode = '0001'.
          <fs_item>-retsinspiscrtedautomly = 'X'.
        ENDIF.
      ENDLOOP.

      IF ls_req-sales_order_type = 'CBAR'.
        MOVE-CORRESPONDING ls_req TO ls_return.
        LOOP AT ls_req-to_item-results ASSIGNING <fs_item>.
          APPEND INITIAL LINE TO ls_return-_item ASSIGNING FIELD-SYMBOL(<fs_item_return>).
          MOVE-CORRESPONDING <fs_item> TO <fs_item_return>.
          LOOP AT <fs_item>-to_pricing_element-results[] ASSIGNING <fs_price>.
            APPEND INITIAL LINE TO <fs_item_return>-_itempricingelement ASSIGNING FIELD-SYMBOL(<fs_item_return_price>).
            MOVE-CORRESPONDING <fs_price> TO <fs_item_return_price>.
          ENDLOOP.
        ENDLOOP.
      ENDIF.

      lt_mapping = VALUE #(
             ( abap = 'sales_order_type'                  json = 'SalesOrderType'              )
             ( abap = 'sales_organization'                json = 'SalesOrganization'           )
             ( abap = 'sales_district'                    json = 'SalesDistrict'               )
             ( abap = 'sold_to_party'                     json = 'SoldToParty'                 )
             ( abap = 'SDDocumentReason'                  json = 'SDDocumentReason'            )
             ( abap = 'distribution_channel'              json = 'DistributionChannel'         )
             ( abap = 'organization_division'             json = 'OrganizationDivision'        )
             ( abap = 'transaction_currency'              json = 'TransactionCurrency'         )
             ( abap = 'customer_payment_terms'            json = 'CustomerPaymentTerms'        )
             ( abap = 'purchase_order_by_customer'        json = 'PurchaseOrderByCustomer'     )
             ( abap = 'underlying_purchase_order_item'    json = 'UnderlyingPurchaseOrderItem' )
             ( abap = 'material'                          json = 'Material'                    )
             ( abap = 'material_by_customer'              json = 'MaterialByCustomer'          )
             ( abap = 'requested_quantity'                json = 'RequestedQuantity'           )
             ( abap = 'requested_quantity_unit'           json = 'RequestedQuantityUnit'       )
             ( abap = 'production_plant'                  json = 'ProductionPlant'             )
             ( abap = 'storage_location'                  json = 'StorageLocation'             )
             ( abap = 'condition_rate_value'              json = 'ConditionRateValue'          )
             ( abap = 'condition_type'                    json = 'ConditionType'               )
             ( abap = 'to_item'                           json = 'to_Item'                     )
             ( abap = 'to_pricing_element'                json = 'to_PricingElement'           )
             ( abap = 'sales_order_item_category'         json = 'SalesOrderItemCategory'      )
             ( abap = 'reference_sd_document'             json = 'ReferenceSDDocument'         )
             ( abap = 'reference_sd_document_item'        json = 'ReferenceSDDocumentItem'     )

             ( abap = 'CustRetItmFollowUpActivity'        json = 'CustRetItmFollowUpActivity'     )
             ( abap = 'NextFllwUpActivityForMatlInsp'     json = 'NextFllwUpActivityForMatlInsp'  )
             ( abap = 'ReturnsRefundType'                 json = 'ReturnsRefundType'              )
             ( abap = 'ReturnsRefundProcgMode'            json = 'ReturnsRefundProcgMode'         )
             ( abap = 'ReturnsRefundCode'                 json = 'ReturnsRefundCode'              )
             ( abap = 'ReturnsInspectionCode'             json = 'ReturnsInspectionCode'          )
             ( abap = 'RetsInspIsCrtedAutomly'            json = 'RetsInspIsCrtedAutomly'         )
             ( abap = '_Item'                             json = '_Item'                          )
             ( abap = '_ItemPricingElement'               json = '_ItemPricingElement'            )
             ).
      CASE ls_req-sales_order_type.
        WHEN 'DR'.
          READ TABLE lt_mapping ASSIGNING FIELD-SYMBOL(<fs_map>) WITH KEY abap = 'production_plant'.
          IF sy-subrc = 0.
            <fs_map>-json = 'Plant'.
          ENDIF.
        WHEN 'CBAR'.
          READ TABLE lt_mapping ASSIGNING <fs_map> WITH KEY abap = 'material'.
          IF sy-subrc = 0.
            <fs_map>-json = 'Product'.
          ENDIF.
          READ TABLE lt_mapping ASSIGNING <fs_map> WITH KEY abap = 'requested_quantity_unit'.
          IF sy-subrc = 0.
            <fs_map>-json = 'RequestedQuantityISOUnit'.
          ENDIF.
          READ TABLE lt_mapping ASSIGNING <fs_map> WITH KEY abap = 'production_plant'.
          IF sy-subrc = 0.
            <fs_map>-json = 'Plant'.
          ENDIF.
          READ TABLE lt_mapping ASSIGNING <fs_map> WITH KEY abap = 'condition_rate_value'.
          IF sy-subrc = 0.
            <fs_map>-json = 'ConditionRateAmount'.
          ENDIF.
      ENDCASE.
      "传入数据转JSON
      IF ls_req-sales_order_type = 'CBAR'.
        lv_json = /ui2/cl_json=>serialize(
       data          = ls_return
       compress      = abap_true
       pretty_name   = /ui2/cl_json=>pretty_mode-camel_case
       name_mappings = lt_mapping ).
      ELSE.
        lv_json = /ui2/cl_json=>serialize(
        data          = ls_req
        compress      = abap_true
        pretty_name   = /ui2/cl_json=>pretty_mode-camel_case
        name_mappings = lt_mapping ).
      ENDIF.
*&---接口HTTP 链接调用
      TRY.
          DATA(lo_http_client) = cl_web_http_client_manager=>create_by_http_destination( lo_dest ).
          DATA(lo_request) = lo_http_client->get_http_request(   ).
          lo_http_client->enable_path_prefix( ).
          CASE ls_req-sales_order_type.
            WHEN 'OR'.
              DATA(lv_uri_path) = |/API_SALES_ORDER_SRV/A_SalesOrder?sap-language=zh|.
            WHEN 'CBAR'.
              lv_uri_path = |/api_customerreturn/srvd_a2x/sap/customerreturn/0001/CustomerReturn?sap-language=zh|.
              REPLACE ALL OCCURRENCES OF 'SalesOrderType' IN lv_json WITH 'CustomerReturnType'.
            WHEN 'DR'.
              lv_uri_path = |/API_DEBIT_MEMO_REQUEST_SRV/A_DebitMemoRequest?sap-language=zh|.
              REPLACE ALL OCCURRENCES OF 'SalesOrderType' IN lv_json WITH 'DebitMemoRequestType'.
          ENDCASE.

          lo_request->set_uri_path( EXPORTING i_uri_path = lv_uri_path ).
          lo_request->set_header_field( i_name = 'Accept' i_value = 'application/json' ).
          "lo_request->set_header_field( i_name = 'If-Match' i_value = '*' ).
          lo_http_client->set_csrf_token(  ).

          lo_request->set_content_type( 'application/json' ).

          lo_request->set_text( lv_json ).

*&---执行http post 方法
          DATA(lo_response) = lo_http_client->execute( if_web_http_client=>post ).
*&---获取http reponse 数据
          DATA(lv_res) = lo_response->get_text(  ).
*&---确定http 状态
          DATA(status) = lo_response->get_status( ).
          IF status-code = '201'.

            /ui2/cl_json=>deserialize( EXPORTING json  = lv_res
                                        CHANGING data  = ls_ress ).
            /ui2/cl_json=>deserialize( EXPORTING json  = lv_res
                            CHANGING data  = ls_ress4 ).

            flag  = 'S'.
            CASE ls_req-sales_order_type.
              WHEN 'OR'.
                msg  = ls_ress-d-salesorder.
              WHEN 'CBAR'.
                msg  = ls_ress4-customerreturn.
              WHEN 'DR'.
                msg  = ls_ress-d-debitmemorequest.
            ENDCASE.
          ELSE.
            DATA:ls_rese  TYPE zzs_odata_fail,
                 ls_rese4 TYPE zzs_odata4_fail.
            IF ls_req-sales_order_type = 'CBAR'.
              /ui2/cl_json=>deserialize( EXPORTING json  = lv_res
                                         CHANGING data  = ls_rese4 ).
              flag = 'E'.
              msg = ls_rese4-error-message .
            ELSE.
              /ui2/cl_json=>deserialize( EXPORTING json  = lv_res
                                         CHANGING data  = ls_rese ).
              flag = 'E'.
              msg = ls_rese-error-message-value .
            ENDIF.


          ENDIF.
        CATCH cx_http_dest_provider_error INTO DATA(lo_error).
          flag = 'E'.
          msg = '接口调用异常1:' && lo_error->get_longtext( ) .
          RETURN.
        CATCH cx_web_http_client_error INTO DATA(lx_web_http_client_error).
          flag = 'E'.
          msg = '接口调用异常2:' && lx_web_http_client_error->get_longtext( ) .
          RETURN.
      ENDTRY.
      "关闭HTTP链接
      IF lo_http_client IS NOT INITIAL.
        TRY.
            lo_http_client->close( ).
          CATCH cx_web_http_client_error.
            "handle exception
        ENDTRY.
      ENDIF.
    ENDIF.
    "贷项凭证发票过账
    DATA:lv_sales_order TYPE i_salesorder-salesorder.
    IF flag NE 'E' AND ls_req-sales_order_type = 'DR'.
      lv_sales_order = msg.
      lv_sales_order = |{ lv_sales_order ALPHA = IN }|.
      me->deal_0001_fp( IMPORTING flag = flag
                                  msg  = msg
                        CHANGING  lv_sales_order = lv_sales_order ).
    ENDIF.

  ENDMETHOD.


  METHOD deal_0001_fp.
    DATA:lv_delivery_document TYPE vbeln_vl,
         lt_create            TYPE TABLE FOR ACTION IMPORT i_billingdocumenttp~createfromsddocument.

    APPEND INITIAL LINE TO lt_create ASSIGNING FIELD-SYMBOL(<fs_create>).
    <fs_create>-%param-%control = VALUE #( _reference = if_abap_behv=>mk-on ).
    CLEAR:lv_delivery_document.
    lv_delivery_document = lv_sales_order.
    lv_delivery_document = |{ lv_delivery_document ALPHA = IN }|.
    <fs_create>-%param-_reference = VALUE #( BASE <fs_create>-%param-_reference
                                             ( sddocument = lv_delivery_document %control = VALUE #( sddocument = if_abap_behv=>mk-on ) ) ).

    MODIFY ENTITIES OF i_billingdocumenttp PRIVILEGED
     ENTITY billingdocument
     EXECUTE createfromsddocument AUTO FILL CID
     WITH lt_create
     RESULT DATA(lt_result)
     FAILED DATA(ls_failed)
     REPORTED DATA(ls_reported).
    MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO FINAL(mtext).
    IF ls_failed IS NOT INITIAL.
      ROLLBACK ENTITIES.
      flag = 'E'.
      me->deal_0002_get_msg( EXPORTING ls_failed = ls_failed
                                      ls_reported = ls_reported
                                      lv_component = 'BILLINGDOCUMENT'
                            IMPORTING msg = msg     ).
      msg = |{ msg }'/'{ mtext }|.
      msg = |贷项凭证{ lv_delivery_document }预制发票创建失败:{ msg }|.
      RETURN.
    ELSE.
      COMMIT ENTITIES BEGIN
      RESPONSE OF i_billingdocumenttp
      FAILED FINAL(ls_failed_commit)
      REPORTED FINAL(ls_reported_commit).
      CONVERT KEY OF i_billingdocumenttp FROM lt_result[ 1 ]-%param-%pid TO DATA(ls_billingdocument).
      COMMIT ENTITIES END.
      IF sy-subrc NE 0.
        flag = 'E'.
        msg = |创建发票数据库提交失败，请联系管理员|.
        RETURN.
      ELSE.
        flag = 'S'.
      ENDIF.
    ENDIF.
  ENDMETHOD.


  METHOD deal_0002.
    DATA:lv_sales_order TYPE vbeln.
    READ TABLE lt_req INTO DATA(ls_req_1) INDEX 1.
    lv_sales_order = ls_req_1-sales_order.
    lv_sales_order = |{ lv_sales_order ALPHA = IN }|.
    SELECT SINGLE *
             FROM i_salesdocument WITH PRIVILEGED ACCESS
            WHERE salesdocument = @lv_sales_order
            INTO @DATA(ls_salesdocument).
    IF sy-subrc NE 0.
      flag = 'E'.
      msg = |传入SAP销售订单{ ls_req_1-sales_order }不存在，请检查|.
      RETURN.
    ELSE.
      CASE ls_salesdocument-salesdocumenttype.
        WHEN 'TA'.

        WHEN 'CBAR'.
          DATA(lv_return) = 'X'.
        WHEN OTHERS.
          flag = 'E'.
          msg = |传入SAP销售订单{ ls_req_1-sales_order }的订单类型不支持修改，请检查|.
          RETURN.
      ENDCASE.
    ENDIF.

    LOOP AT lt_req INTO DATA(ls_req).
      IF lv_return = 'X'.
        CASE ls_req-action.
          WHEN '01'.
            "行撤单
            me->deal_0002_act01_return( IMPORTING flag = flag
                                           msg  = msg
                                 CHANGING  ls_req = ls_req ).
          WHEN '02'.
            "行项目数量、金额、工厂修改
            me->deal_0002_act02_return( IMPORTING flag = flag
                                           msg  = msg
                                 CHANGING  ls_req = ls_req ).
          WHEN '03'.
            "行项目品种替换
            me->deal_0002_act03_return( IMPORTING flag = flag
                                           msg  = msg
                                 CHANGING  ls_req = ls_req ).
          WHEN '04'.
            "新增行项目
            me->deal_0002_act04_return( IMPORTING flag = flag
                                 msg  = msg
                       CHANGING  ls_req = ls_req ).
        ENDCASE.
      ELSE.
        CASE ls_req-action.
          WHEN '01'.
            "行撤单
            me->deal_0002_act01( IMPORTING flag = flag
                                           msg  = msg
                                 CHANGING  ls_req = ls_req ).
          WHEN '02'.
            "行项目数量、金额、工厂修改
            me->deal_0002_act02( IMPORTING flag = flag
                                           msg  = msg
                                 CHANGING  ls_req = ls_req ).
          WHEN '03'.
            "行项目品种替换
            me->deal_0002_act03( IMPORTING flag = flag
                                           msg  = msg
                                 CHANGING  ls_req = ls_req ).
          WHEN '04'.
            "新增行项目
            me->deal_0002_act04( IMPORTING flag = flag
                                 msg  = msg
                       CHANGING  ls_req = ls_req ).
          WHEN OTHERS.
            flag = 'E'.
            msg = |第{ sy-tabix }传入【action】操作类型不支持,请检查|.
        ENDCASE.
      ENDIF.

      IF flag = 'E'.
        EXIT.
      ENDIF.
    ENDLOOP.
    IF flag = 'E'.
      ROLLBACK ENTITIES.
    ELSE.
      flag = 'S'.
      COMMIT ENTITIES
      RESPONSES
      REPORTED DATA(ls_reported2)
      FAILED DATA(ls_failed2).
      IF ls_failed2 IS NOT INITIAL.
        flag = 'E'.
        msg = '数据库提交失败，请联系管理员'.
        RETURN.
      ELSE.
        msg = ls_req-sales_order.
      ENDIF.
    ENDIF.
  ENDMETHOD.


  METHOD deal_0002_act01.
    DATA:lv_msg              TYPE bapi_msg,
         ls_t100key          TYPE scx_t100key,
         lv_msgid            TYPE symsgid,
         lv_msgno            TYPE symsgno,
         lv_msgv1            LIKE sy-msgv1,
         lv_msgv2            LIKE sy-msgv2,
         lv_msgv3            LIKE sy-msgv3,
         lv_msgv4            LIKE sy-msgv4,
         lv_sales_order      TYPE vbeln,
         lv_sales_order_item TYPE posnr.

    FIELD-SYMBOLS:<fs_salesorder_tab> TYPE STANDARD TABLE,
                  <fs_salesorder>     TYPE any,
                  <fs_msg>            TYPE REF TO if_abap_behv_message,
                  <fs_t100key>        TYPE any.
    lv_sales_order = ls_req-sales_order.
    lv_sales_order = |{ lv_sales_order ALPHA = IN }|.
    lv_sales_order_item = ls_req-sales_order_item.

    MODIFY ENTITIES OF i_salesordertp PRIVILEGED
    ENTITY salesorderitem
    UPDATE
    FIELDS ( salesdocumentrjcnreason )
    WITH VALUE #( ( salesdocumentrjcnreason = '60'
     %key-salesorder = lv_sales_order
     %key-salesorderitem = lv_sales_order_item ) )
    REPORTED DATA(ls_reported)
    FAILED DATA(ls_failed).
    MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO FINAL(mtext).
    IF ls_failed IS NOT INITIAL.
      flag = 'E'.
      me->deal_0002_get_msg( EXPORTING ls_failed = ls_failed
                                       ls_reported = ls_reported
                                       lv_component = 'SALESORDERITEM'
                             IMPORTING msg = msg     ).
      IF msg IS INITIAL.
        me->deal_0002_get_msg( EXPORTING ls_failed = ls_failed
                                         ls_reported = ls_reported
                                         lv_component = 'SALESORDER'
                               IMPORTING msg = msg     ).
      ENDIF.
      msg = |{ msg }'/'{ mtext }|.
      msg = |'订单'{ lv_sales_order }'项目'{ lv_sales_order_item }'撤单修改失败:'{ msg }|.
      RETURN.
    ENDIF.
  ENDMETHOD.


  METHOD deal_0002_act01_return.
    DATA:lv_msg              TYPE bapi_msg,
         ls_t100key          TYPE scx_t100key,
         lv_msgid            TYPE symsgid,
         lv_msgno            TYPE symsgno,
         lv_msgv1            LIKE sy-msgv1,
         lv_msgv2            LIKE sy-msgv2,
         lv_msgv3            LIKE sy-msgv3,
         lv_msgv4            LIKE sy-msgv4,
         lv_sales_order      TYPE vbeln,
         lv_sales_order_item TYPE posnr.

    lv_sales_order = ls_req-sales_order.
    lv_sales_order = |{ lv_sales_order ALPHA = IN }|.
    lv_sales_order_item = ls_req-sales_order_item.

    MODIFY ENTITIES OF i_customerreturntp PRIVILEGED
    ENTITY customerreturnitem
    UPDATE
    FIELDS ( salesdocumentrjcnreason )
    WITH VALUE #( ( salesdocumentrjcnreason = '60'
     %key-customerreturn = lv_sales_order
     %key-customerreturnitem = lv_sales_order_item ) )
    REPORTED DATA(ls_reported)
    FAILED DATA(ls_failed).
    MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO FINAL(mtext).
    IF ls_failed IS NOT INITIAL.
      flag = 'E'.
      me->deal_0002_get_msg( EXPORTING ls_failed = ls_failed
                                       ls_reported = ls_reported
                                       lv_component = 'CUSTOMERRETURNITEM'
                             IMPORTING msg = msg     ).
      IF msg IS INITIAL.
        me->deal_0002_get_msg( EXPORTING ls_failed = ls_failed
                                         ls_reported = ls_reported
                                         lv_component = 'CUSTOMERRETURN'
                               IMPORTING msg = msg     ).
      ENDIF.
      msg = |{ msg }'/'{ mtext }|.
      msg = |'订单'{ lv_sales_order }'项目'{ lv_sales_order_item }'撤单修改失败:'{ msg }|.
      RETURN.
    ENDIF.
  ENDMETHOD.


  METHOD deal_0002_act02.
    DATA:lv_msg                      TYPE bapi_msg,
         ls_t100key                  TYPE scx_t100key,
         lv_msgid                    TYPE symsgid,
         lv_msgno                    TYPE symsgno,
         lv_msgv1                    LIKE sy-msgv1,
         lv_msgv2                    LIKE sy-msgv2,
         lv_msgv3                    LIKE sy-msgv3,
         lv_msgv4                    LIKE sy-msgv4,
         lv_sales_order              TYPE vbeln,
         lv_sales_order_item         TYPE posnr,
         ls_sales_order_item         TYPE i_salesorderitemtp,
         ls_sales_order_item_pricing TYPE i_salesorderitemprcgelmnttp.
    FIELD-SYMBOLS:<fs_salesorder_tab> TYPE STANDARD TABLE,
                  <fs_salesorder>     TYPE any,
                  <fs_msg>            TYPE REF TO if_abap_behv_message,
                  <fs_t100key>        TYPE any.
    lv_sales_order = ls_req-sales_order.
    lv_sales_order = |{ lv_sales_order ALPHA = IN }|.
    lv_sales_order_item = ls_req-sales_order_item.
    CONDENSE ls_req-requested_quantity NO-GAPS.
    ls_sales_order_item-requestedquantity = ls_req-requested_quantity.
    ls_sales_order_item-plant = ls_req-plant.
    CONDENSE ls_req-condition_rate_value NO-GAPS.
    ls_sales_order_item_pricing-conditionrateamount = ls_req-condition_rate_value.

    SELECT SINGLE *
      FROM i_salesorderitemtp WITH PRIVILEGED ACCESS
     WHERE salesorder = @lv_sales_order
       AND salesorderitem = @lv_sales_order_item
       INTO @DATA(ls_item).
    IF ls_sales_order_item-requestedquantity IS NOT INITIAL AND ls_sales_order_item-requestedquantity NE ls_item-requestedquantity.
      DATA(lv_item_change) = 'X'.
    ENDIF.

    IF ls_sales_order_item-plant IS NOT INITIAL AND ls_sales_order_item-plant NE ls_item-plant.
      lv_item_change = 'X'.
    ENDIF.

    SELECT SINGLE *
          FROM i_salesorderitemprcgelmnttp WITH PRIVILEGED ACCESS
         WHERE salesorder = @lv_sales_order
           AND salesorderitem = @lv_sales_order_item
           AND conditiontype = 'ZPR0'
           INTO @DATA(ls_item_price).
    IF ls_sales_order_item_pricing-conditionrateamount IS NOT INITIAL AND ls_sales_order_item_pricing-conditionrateamount NE ls_item_price-conditionrateamount.
      DATA(lv_item_price_change) = 'X'.
    ENDIF.

    IF lv_item_change IS INITIAL AND lv_item_price_change IS INITIAL.
      flag = 'E'.
      msg = |'订单'{ lv_sales_order }'项目'{ lv_sales_order_item }'【数量】【发货工厂】【金额】未发生变化，无需修改'|.
      RETURN.
    ENDIF.

    IF lv_item_change = 'X'.
      "数量、发货工厂修改
      MODIFY ENTITIES OF i_salesordertp PRIVILEGED
      ENTITY salesorderitem
      UPDATE
      FIELDS ( requestedquantity plant )
      WITH VALUE #( ( requestedquantity = ls_sales_order_item-requestedquantity
       plant = ls_sales_order_item-plant
       %key-salesorder = lv_sales_order
       %key-salesorderitem = lv_sales_order_item ) )
      REPORTED DATA(ls_reported_item)
      FAILED DATA(ls_failed_item).
      MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO FINAL(mtext).
      IF ls_failed_item IS NOT INITIAL.
        flag = 'E'.
        me->deal_0002_get_msg( EXPORTING ls_failed = ls_failed_item
                                         ls_reported = ls_reported_item
                                         lv_component = 'SALESORDERITEM'
                               IMPORTING msg = msg     ).
        IF msg IS INITIAL.
          me->deal_0002_get_msg( EXPORTING ls_failed = ls_failed_item
                                           ls_reported = ls_reported_item
                                           lv_component = 'SALESORDER'
                                 IMPORTING msg = msg     ).
        ENDIF.
        msg = |{ msg }'/'{ mtext }|.
        msg = |'订单'{ lv_sales_order }'项目'{ lv_sales_order_item }'【数量】【发货工厂】修改失败:' { msg }|.
        RETURN.
      ENDIF.
    ENDIF.

    IF lv_item_price_change = 'X'.
      "金额修改
      MODIFY ENTITIES OF i_salesordertp PRIVILEGED
       ENTITY salesorderitempricingelement
       UPDATE
       FIELDS ( conditionrateamount )
       WITH VALUE #( ( %key = VALUE #( salesorder = lv_sales_order
       salesorderitem = lv_sales_order_item
       pricingprocedurestep = ls_item_price-pricingprocedurestep
       pricingprocedurecounter = ls_item_price-pricingprocedurecounter )
       conditionrateamount = ls_sales_order_item_pricing-conditionrateamount ) )
            REPORTED DATA(ls_reported_item_price)
            FAILED DATA(ls_failed_item_price).
      MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO FINAL(mtext1).
      IF ls_failed_item_price IS NOT INITIAL.
        flag = 'E'.
        me->deal_0002_get_msg( EXPORTING ls_failed = ls_failed_item_price
                                         ls_reported = ls_reported_item_price
                                         lv_component = 'SALESORDERITEMPRICINGELEMENT'
                               IMPORTING msg = msg     ).
        IF msg IS INITIAL.
          me->deal_0002_get_msg( EXPORTING ls_failed = ls_failed_item
                                           ls_reported = ls_reported_item
                                           lv_component = 'SALESORDERITEM'
                                 IMPORTING msg = msg     ).
        ENDIF.
        IF msg IS INITIAL.
          me->deal_0002_get_msg( EXPORTING ls_failed = ls_failed_item
                                           ls_reported = ls_reported_item
                                           lv_component = 'SALESORDER'
                                 IMPORTING msg = msg     ).
        ENDIF.
        msg = |{ msg }'/'{ mtext1 }|.
        msg = |'订单'{ lv_sales_order }'项目'{ lv_sales_order_item }'金额修改失败:'{ msg }|.
        RETURN.
      ENDIF.
    ENDIF.


  ENDMETHOD.


  METHOD deal_0002_act02_return.
    DATA:lv_msg                      TYPE bapi_msg,
         ls_t100key                  TYPE scx_t100key,
         lv_msgid                    TYPE symsgid,
         lv_msgno                    TYPE symsgno,
         lv_msgv1                    LIKE sy-msgv1,
         lv_msgv2                    LIKE sy-msgv2,
         lv_msgv3                    LIKE sy-msgv3,
         lv_msgv4                    LIKE sy-msgv4,
         lv_sales_order              TYPE vbeln,
         lv_sales_order_item         TYPE posnr,
         ls_sales_order_item         TYPE i_salesorderitemtp,
         ls_sales_order_item_pricing TYPE i_salesorderitemprcgelmnttp.
    FIELD-SYMBOLS:<fs_salesorder_tab> TYPE STANDARD TABLE,
                  <fs_salesorder>     TYPE any,
                  <fs_msg>            TYPE REF TO if_abap_behv_message,
                  <fs_t100key>        TYPE any.
    lv_sales_order = ls_req-sales_order.
    lv_sales_order = |{ lv_sales_order ALPHA = IN }|.
    lv_sales_order_item = ls_req-sales_order_item.
    CONDENSE ls_req-requested_quantity NO-GAPS.
    ls_sales_order_item-requestedquantity = ls_req-requested_quantity.
    ls_sales_order_item-plant = ls_req-plant.
    CONDENSE ls_req-condition_rate_value NO-GAPS.
    ls_sales_order_item_pricing-conditionrateamount = ls_req-condition_rate_value.

    SELECT SINGLE *
      FROM i_customerreturnitemtp WITH PRIVILEGED ACCESS
     WHERE customerreturn = @lv_sales_order
       AND customerreturnitem = @lv_sales_order_item
       INTO @DATA(ls_item).
    IF ls_sales_order_item-requestedquantity IS NOT INITIAL AND ls_sales_order_item-requestedquantity NE ls_item-requestedquantity.
      DATA(lv_item_change) = 'X'.
    ENDIF.

    IF ls_sales_order_item-plant IS NOT INITIAL AND ls_sales_order_item-plant NE ls_item-productionplant.
      lv_item_change = 'X'.
    ENDIF.

    SELECT SINGLE *
          FROM i_custretitempricingelementtp WITH PRIVILEGED ACCESS
         WHERE customerreturn = @lv_sales_order
           AND customerreturnitem = @lv_sales_order_item
           AND conditiontype = 'ZPR0'
           INTO @DATA(ls_item_price).
    IF ls_sales_order_item_pricing-conditionrateamount IS NOT INITIAL AND ls_sales_order_item_pricing-conditionrateamount NE ls_item_price-conditionrateamount.
      DATA(lv_item_price_change) = 'X'.
    ENDIF.

    IF lv_item_change IS INITIAL AND lv_item_price_change IS INITIAL.
      flag = 'E'.
      msg = |'订单'{ lv_sales_order }'项目'{ lv_sales_order_item }'【数量】【发货工厂】【金额】未发生变化，无需修改'|.
      RETURN.
    ENDIF.

    IF lv_item_change = 'X'.
      "数量、发货工厂修改
      MODIFY ENTITIES OF i_customerreturntp PRIVILEGED
      ENTITY customerreturnitem
      UPDATE
      FIELDS ( requestedquantity productionplant )
      WITH VALUE #( ( requestedquantity = ls_sales_order_item-requestedquantity
       productionplant = ls_sales_order_item-plant
       %key-customerreturn = lv_sales_order
       %key-customerreturnitem = lv_sales_order_item ) )
      REPORTED DATA(ls_reported_item)
      FAILED DATA(ls_failed_item).
      MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO FINAL(mtext).
      IF ls_failed_item IS NOT INITIAL.
        flag = 'E'.
        me->deal_0002_get_msg( EXPORTING ls_failed = ls_failed_item
                                         ls_reported = ls_reported_item
                                         lv_component = 'CUSTOMERRETURNITEM'
                               IMPORTING msg = msg     ).
        IF msg IS INITIAL.
          me->deal_0002_get_msg( EXPORTING ls_failed = ls_failed_item
                                           ls_reported = ls_reported_item
                                           lv_component = 'CUSTOMERRETURN'
                                 IMPORTING msg = msg     ).
        ENDIF.
        msg = |{ msg }'/'{ mtext }|.
        msg = |'订单'{ lv_sales_order }'项目'{ lv_sales_order_item }'【数量】【发货工厂】修改失败:' { msg }|.
        RETURN.
      ENDIF.
    ENDIF.

    IF lv_item_price_change = 'X'.
      "金额修改
      MODIFY ENTITIES OF i_customerreturntp PRIVILEGED
       ENTITY custreturnitempricingelement
       UPDATE
       FIELDS ( conditionrateamount )
       WITH VALUE #( ( %key = VALUE #( customerreturn = lv_sales_order
       customerreturnitem = lv_sales_order_item
       pricingprocedurestep = ls_item_price-pricingprocedurestep
       pricingprocedurecounter = ls_item_price-pricingprocedurecounter )
       conditionrateamount = ls_sales_order_item_pricing-conditionrateamount ) )
            REPORTED DATA(ls_reported_item_price)
            FAILED DATA(ls_failed_item_price).
      MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO FINAL(mtext1).
      IF ls_failed_item_price IS NOT INITIAL.
        flag = 'E'.
        me->deal_0002_get_msg( EXPORTING ls_failed = ls_failed_item_price
                                         ls_reported = ls_reported_item_price
                                         lv_component = 'CUSTRETURNITEMPRICINGELEMENT'
                               IMPORTING msg = msg     ).
        IF msg IS INITIAL.
          me->deal_0002_get_msg( EXPORTING ls_failed = ls_failed_item
                                           ls_reported = ls_reported_item
                                           lv_component = 'CUSTOMERRETURNITEM'
                                 IMPORTING msg = msg     ).
        ENDIF.
        IF msg IS INITIAL.
          me->deal_0002_get_msg( EXPORTING ls_failed = ls_failed_item
                                           ls_reported = ls_reported_item
                                           lv_component = 'CUSTOMERRETURN'
                                 IMPORTING msg = msg     ).
        ENDIF.
        msg = |{ msg }/{ mtext1 }|.
        msg = |'订单'{ lv_sales_order }'项目'{ lv_sales_order_item }'金额修改失败:'{ msg }|.
        RETURN.
      ENDIF.
    ENDIF.


  ENDMETHOD.


  METHOD deal_0002_act03.
    DATA:lv_msg                      TYPE bapi_msg,
         ls_t100key                  TYPE scx_t100key,
         lv_msgid                    TYPE symsgid,
         lv_msgno                    TYPE symsgno,
         lv_msgv1                    LIKE sy-msgv1,
         lv_msgv2                    LIKE sy-msgv2,
         lv_msgv3                    LIKE sy-msgv3,
         lv_msgv4                    LIKE sy-msgv4,
         lv_sales_order              TYPE vbeln,
         lv_sales_order_item         TYPE posnr,
         ls_sales_order_item         TYPE i_salesorderitemtp,
         ls_sales_order_item_pricing TYPE i_salesorderitemprcgelmnttp,
         lv_product                  TYPE char18.
    FIELD-SYMBOLS:<fs_salesorder_tab> TYPE STANDARD TABLE,
                  <fs_salesorder>     TYPE any,
                  <fs_msg>            TYPE REF TO if_abap_behv_message,
                  <fs_t100key>        TYPE any.
    lv_sales_order = ls_req-sales_order.
    lv_sales_order = |{ lv_sales_order ALPHA = IN }|.
    lv_sales_order_item = ls_req-sales_order_item.
    lv_product = ls_req-material.
    lv_product = |{ lv_product ALPHA = IN }|.
    ls_sales_order_item-product = lv_product.
    CONDENSE ls_req-requested_quantity NO-GAPS.
    ls_sales_order_item-requestedquantity = ls_req-requested_quantity.
    ls_sales_order_item-requestedquantityunit = ls_req-requested_quantity_unit.
    ls_sales_order_item-plant = ls_req-plant.
    ls_sales_order_item-materialbycustomer = ls_req-material_by_customer.
    CONDENSE ls_req-condition_rate_value NO-GAPS.
    ls_sales_order_item_pricing-conditionrateamount = ls_req-condition_rate_value.

    SELECT SINGLE *
      FROM i_salesorderitemtp WITH PRIVILEGED ACCESS
     WHERE salesorder = @lv_sales_order
       AND salesorderitem = @lv_sales_order_item
       INTO @DATA(ls_item).
    IF ls_sales_order_item-product NE ls_item-product.
      DATA(lv_item_change) = 'X'.
    ELSE.
      flag = 'E'.
      msg = |'订单'{ lv_sales_order }'项目'{ lv_sales_order_item }'传入物料跟原物料一样,无需替换,请检查'|.
      RETURN.
    ENDIF.

    SELECT SINGLE *
             FROM i_unitofmeasure
            WHERE unitofmeasure_e = @ls_sales_order_item-requestedquantityunit
             INTO @DATA(ls_unit).
    IF sy-subrc NE 0.
      flag = 'E'.
      msg = |'订单'{ lv_sales_order }'项目'{ lv_sales_order_item }'品种替换-步骤1-原项目撤单失败:'|
      && |单位{ ls_sales_order_item-requestedquantityunit }不存在|.
      RETURN.
    ENDIF.

    IF lv_item_change = 'X'.
      "品种发生替换,原行项目打拒绝标识
      MODIFY ENTITIES OF i_salesordertp PRIVILEGED
      ENTITY salesorderitem
      UPDATE
      FIELDS ( salesdocumentrjcnreason )
      WITH VALUE #( ( salesdocumentrjcnreason = '60'
       %key-salesorder = lv_sales_order
       %key-salesorderitem = lv_sales_order_item ) )
      REPORTED DATA(ls_reported_item_old)
      FAILED DATA(ls_failed_item_old).
      MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO FINAL(mtext).
      IF ls_failed_item_old IS NOT INITIAL.
        flag = 'E'.
        me->deal_0002_get_msg( EXPORTING ls_failed = ls_failed_item_old
                                         ls_reported = ls_reported_item_old
                                         lv_component = 'SALESORDERITEM'
                               IMPORTING msg = msg     ).
        IF msg IS INITIAL.
          me->deal_0002_get_msg( EXPORTING ls_failed = ls_failed_item_old
                                           ls_reported = ls_reported_item_old
                                           lv_component = 'SALESORDER'
                                 IMPORTING msg = msg     ).
        ENDIF.
        msg = |{ msg }'/'{ mtext }|.
        msg = |'订单'{ lv_sales_order }'项目'{ lv_sales_order_item }'品种替换-步骤1-原项目撤单失败:'{ msg }|.
        RETURN.
      ENDIF.
      "品种发生替换,插入新行项目
      MODIFY ENTITIES OF i_salesordertp PRIVILEGED
       ENTITY salesorder
       CREATE BY \_item
       FIELDS ( product requestedquantity requestedquantityunit plant materialbycustomer )
       WITH VALUE #( (
       salesorder = lv_sales_order
       %target = VALUE #( ( %cid = 'I001'
       product = ls_sales_order_item-product
       plant   = ls_sales_order_item-plant
       requestedquantity = ls_sales_order_item-requestedquantity
       requestedquantityunit = ls_unit-unitofmeasure
       materialbycustomer = ls_item-materialbycustomer ) ) ) )
       ENTITY salesorderitem
       CREATE BY \_itempricingelement
       FIELDS ( conditiontype
       conditionrateamount  )
       WITH VALUE #( ( %cid_ref = 'I001'
       salesorder = lv_sales_order
       salesorderitem = space
       %target = VALUE #( ( %cid = 'IP001'
       conditiontype = 'ZPR0'
       conditionrateamount = ls_sales_order_item_pricing-conditionrateamount ) ) ) )
       FAILED DATA(ls_failed_item_new)
       REPORTED DATA(ls_reported_item_new).
      MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO FINAL(mtext1).
      IF ls_failed_item_new IS NOT INITIAL.
        flag = 'E'.
        me->deal_0002_get_msg( EXPORTING ls_failed = ls_failed_item_new
                                         ls_reported = ls_reported_item_new
                                         lv_component = 'SALESORDERITEM'
                               IMPORTING msg = msg     ).
        IF msg IS INITIAL.
          me->deal_0002_get_msg( EXPORTING ls_failed = ls_failed_item_new
                                           ls_reported = ls_reported_item_new
                                           lv_component = 'SALESORDER'
                                 IMPORTING msg = msg     ).
        ENDIF.
        IF msg IS INITIAL.
          me->deal_0002_get_msg( EXPORTING ls_failed = ls_failed_item_new
                                           ls_reported = ls_reported_item_new
                                           lv_component = 'SALESORDERITEMPRICINGELEMENT'
                                 IMPORTING msg = msg     ).
        ENDIF.
        msg = |{ msg }'/'{ mtext1 }|.
        msg = |'订单'{ lv_sales_order }'项目'{ lv_sales_order_item }'品种替换-步骤2-项目新增行失败:'{ msg }|.
        RETURN.
      ENDIF.
    ENDIF.

  ENDMETHOD.


  METHOD deal_0002_act03_return.
    DATA:lv_msg                      TYPE bapi_msg,
         ls_t100key                  TYPE scx_t100key,
         lv_msgid                    TYPE symsgid,
         lv_msgno                    TYPE symsgno,
         lv_msgv1                    LIKE sy-msgv1,
         lv_msgv2                    LIKE sy-msgv2,
         lv_msgv3                    LIKE sy-msgv3,
         lv_msgv4                    LIKE sy-msgv4,
         lv_sales_order              TYPE vbeln,
         lv_sales_order_item         TYPE posnr,
         ls_sales_order_item         TYPE i_salesorderitemtp,
         ls_sales_order_item_pricing TYPE i_salesorderitemprcgelmnttp,
         lv_product                  TYPE char18.
    FIELD-SYMBOLS:<fs_salesorder_tab> TYPE STANDARD TABLE,
                  <fs_salesorder>     TYPE any,
                  <fs_msg>            TYPE REF TO if_abap_behv_message,
                  <fs_t100key>        TYPE any.
    lv_sales_order = ls_req-sales_order.
    lv_sales_order = |{ lv_sales_order ALPHA = IN }|.
    lv_sales_order_item = ls_req-sales_order_item.
    lv_product = ls_req-material.
    lv_product = |{ lv_product ALPHA = IN }|.
    ls_sales_order_item-product = lv_product.
    CONDENSE ls_req-requested_quantity NO-GAPS.
    ls_sales_order_item-requestedquantity = ls_req-requested_quantity.
    ls_sales_order_item-requestedquantityunit = ls_req-requested_quantity_unit.
    ls_sales_order_item-plant = ls_req-plant.
    ls_sales_order_item-materialbycustomer = ls_req-material_by_customer.
    CONDENSE ls_req-condition_rate_value NO-GAPS.
    ls_sales_order_item_pricing-conditionrateamount = ls_req-condition_rate_value.

    SELECT SINGLE *
      FROM i_customerreturnitemtp WITH PRIVILEGED ACCESS
     WHERE customerreturn = @lv_sales_order
       AND customerreturnitem = @lv_sales_order_item
       INTO @DATA(ls_item).
    IF ls_sales_order_item-product NE ls_item-product.
      DATA(lv_item_change) = 'X'.
    ELSE.
      flag = 'E'.
      msg = |'订单'{ lv_sales_order }'项目'{ lv_sales_order_item }'传入物料跟原物料一样,无需替换,请检查'|.
      RETURN.
    ENDIF.

    SELECT SINGLE *
             FROM i_unitofmeasure
            WHERE unitofmeasure_e = @ls_sales_order_item-requestedquantityunit
             INTO @DATA(ls_unit).
    IF sy-subrc NE 0.
      flag = 'E'.
      msg = |'订单'{ lv_sales_order }'项目'{ lv_sales_order_item }'品种替换-步骤1-原项目撤单失败:'|
      && |单位{ ls_sales_order_item-requestedquantityunit }不存在|.
      RETURN.
    ENDIF.

    IF lv_item_change = 'X'.
      "品种发生替换,原行项目打拒绝标识
      MODIFY ENTITIES OF i_customerreturntp PRIVILEGED
      ENTITY customerreturnitem
      UPDATE
      FIELDS ( salesdocumentrjcnreason )
      WITH VALUE #( ( salesdocumentrjcnreason = '60'
       %key-customerreturn = lv_sales_order
       %key-customerreturnitem = lv_sales_order_item ) )
      REPORTED DATA(ls_reported_item_old)
      FAILED DATA(ls_failed_item_old).
      MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO FINAL(mtext).
      IF ls_failed_item_old IS NOT INITIAL.
        flag = 'E'.
        me->deal_0002_get_msg( EXPORTING ls_failed = ls_failed_item_old
                                         ls_reported = ls_reported_item_old
                                         lv_component = 'CUSTOMERRETURNITEM'
                               IMPORTING msg = msg     ).
        IF msg IS INITIAL.
          me->deal_0002_get_msg( EXPORTING ls_failed = ls_failed_item_old
                                           ls_reported = ls_reported_item_old
                                           lv_component = 'CUSTOMERRETURN'
                                 IMPORTING msg = msg     ).
        ENDIF.
        msg = |{ msg }'/'{ mtext }|.
        msg = |'订单'{ lv_sales_order }'项目'{ lv_sales_order_item }'品种替换-步骤1-原项目撤单失败:'{ msg }|.
        RETURN.
      ENDIF.

      "品种发生替换,插入新行项目
      MODIFY ENTITIES OF i_customerreturntp PRIVILEGED
       ENTITY customerreturn
       CREATE BY \_item
       FIELDS ( product requestedquantity requestedquantityunit productionplant materialbycustomer )
       WITH VALUE #( (
       customerreturn = lv_sales_order
       %target = VALUE #( ( %cid = 'I001'
       product = ls_sales_order_item-product
       productionplant   = ls_sales_order_item-plant
       requestedquantity = ls_sales_order_item-requestedquantity
       requestedquantityunit = ls_unit-unitofmeasure
       materialbycustomer = ls_item-materialbycustomer ) ) ) )
       ENTITY customerreturnitem
       CREATE BY \_itempricingelement
       FIELDS ( conditiontype
       conditionrateamount  )
       WITH VALUE #( ( %cid_ref = 'I001'
       customerreturn = lv_sales_order
       customerreturnitem = space
       %target = VALUE #( ( %cid = 'IP001'
       conditiontype = 'ZPR0'
       conditionrateamount = ls_sales_order_item_pricing-conditionrateamount ) ) ) )
       FAILED DATA(ls_failed_item_new)
       REPORTED DATA(ls_reported_item_new).
      MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO FINAL(mtext1).
      IF ls_failed_item_new IS NOT INITIAL.
        flag = 'E'.
        me->deal_0002_get_msg( EXPORTING ls_failed = ls_failed_item_new
                                         ls_reported = ls_reported_item_new
                                         lv_component = 'CUSTOMERRETURNITEM'
                               IMPORTING msg = msg     ).
        IF msg IS INITIAL.
          me->deal_0002_get_msg( EXPORTING ls_failed = ls_failed_item_new
                                           ls_reported = ls_reported_item_new
                                           lv_component = 'CUSTOMERRETURN'
                                 IMPORTING msg = msg     ).
        ENDIF.
        IF msg IS INITIAL.
          me->deal_0002_get_msg( EXPORTING ls_failed = ls_failed_item_new
                                           ls_reported = ls_reported_item_new
                                           lv_component = 'CUSTRETURNITEMPRICINGELEMENT'
                                 IMPORTING msg = msg     ).
        ENDIF.
        msg = |{ msg }'/'{ mtext1 }|.
        msg = |'订单'{ lv_sales_order }'项目'{ lv_sales_order_item }'品种替换-步骤2-项目新增行失败:'{ msg }|.
        RETURN.
      ENDIF.
    ENDIF.

  ENDMETHOD.


  METHOD deal_0002_act04.
    DATA:lv_msg                      TYPE bapi_msg,
         ls_t100key                  TYPE scx_t100key,
         lv_msgid                    TYPE symsgid,
         lv_msgno                    TYPE symsgno,
         lv_msgv1                    LIKE sy-msgv1,
         lv_msgv2                    LIKE sy-msgv2,
         lv_msgv3                    LIKE sy-msgv3,
         lv_msgv4                    LIKE sy-msgv4,
         lv_sales_order              TYPE vbeln,
         lv_sales_order_item         TYPE posnr,
         ls_sales_order_item         TYPE i_salesorderitemtp,
         ls_sales_order_item_pricing TYPE i_salesorderitemprcgelmnttp,
         lv_product                  TYPE char18.
    FIELD-SYMBOLS:<fs_salesorder_tab> TYPE STANDARD TABLE,
                  <fs_salesorder>     TYPE any,
                  <fs_msg>            TYPE REF TO if_abap_behv_message,
                  <fs_t100key>        TYPE any.
    lv_sales_order = ls_req-sales_order.
    lv_sales_order = |{ lv_sales_order ALPHA = IN }|.
    lv_sales_order_item = ls_req-sales_order_item.
    lv_product = ls_req-material.
    lv_product = |{ lv_product ALPHA = IN }|.
    ls_sales_order_item-product = lv_product.
    CONDENSE ls_req-requested_quantity NO-GAPS.
    ls_sales_order_item-requestedquantity = ls_req-requested_quantity.
    ls_sales_order_item-requestedquantityunit = ls_req-requested_quantity_unit.
    ls_sales_order_item-plant = ls_req-plant.
    ls_sales_order_item-materialbycustomer = ls_req-material_by_customer.
    CONDENSE ls_req-condition_rate_value NO-GAPS.
    ls_sales_order_item_pricing-conditionrateamount = ls_req-condition_rate_value.
    DATA(lv_out_line_no) = ls_req-underlying_purchase_order_item.

    SELECT SINGLE *
      FROM i_salesorderitemtp WITH PRIVILEGED ACCESS
     WHERE salesorder = @lv_sales_order
       AND salesorderitem = @lv_sales_order_item
       INTO @DATA(ls_item).
    IF ls_sales_order_item-product NE ls_item-product.
      DATA(lv_item_change) = 'X'.
    ENDIF.

    SELECT SINGLE *
             FROM i_unitofmeasure
            WHERE unitofmeasure_e = @ls_sales_order_item-requestedquantityunit
             INTO @DATA(ls_unit).
    IF sy-subrc NE 0.
      flag = 'E'.
      msg = |'订单'{ lv_sales_order }'项目'{ lv_sales_order_item }'新增行失败:'|
      && |单位{ ls_sales_order_item-requestedquantityunit }不存在|.
      RETURN.
    ENDIF.

    IF lv_item_change = 'X'.
      "插入新行项目
      MODIFY ENTITIES OF i_salesordertp PRIVILEGED
       ENTITY salesorder
       CREATE BY \_item
       FIELDS ( product plant requestedquantity requestedquantityunit materialbycustomer )
       WITH VALUE #( (
       salesorder = lv_sales_order
       %target = VALUE #( ( %cid = 'I001'
       product = ls_sales_order_item-product
       plant   = ls_sales_order_item-plant
       requestedquantity = ls_sales_order_item-requestedquantity
       requestedquantityunit = ls_unit-unitofmeasure
       materialbycustomer = ls_req-underlying_purchase_order_item ) ) ) )
       ENTITY salesorderitem
       CREATE BY \_itempricingelement
       FIELDS ( conditiontype
       conditionrateamount  )
       WITH VALUE #( ( %cid_ref = 'I001'
       salesorder = lv_sales_order
       salesorderitem = space
       %target = VALUE #( ( %cid = 'IP001'
       conditiontype = 'ZPR0'
       conditionrateamount = ls_sales_order_item_pricing-conditionrateamount ) ) ) )
       FAILED DATA(ls_failed_item_new)
       REPORTED DATA(ls_reported_item_new).
      MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO FINAL(mtext).
      IF ls_failed_item_new IS NOT INITIAL.
        flag = 'E'.
        me->deal_0002_get_msg( EXPORTING ls_failed = ls_failed_item_new
                                         ls_reported = ls_reported_item_new
                                         lv_component = 'SALESORDERITEM'
                               IMPORTING msg = msg     ).
        IF msg IS INITIAL.
          me->deal_0002_get_msg( EXPORTING ls_failed = ls_failed_item_new
                                           ls_reported = ls_failed_item_new
                                           lv_component = 'SALESORDER'
                                 IMPORTING msg = msg     ).
        ENDIF.
        IF msg IS INITIAL.
          me->deal_0002_get_msg( EXPORTING ls_failed = ls_failed_item_new
                                           ls_reported = ls_reported_item_new
                                           lv_component = 'SALESORDERITEMPRICINGELEMENT'
                                 IMPORTING msg = msg     ).
        ENDIF.
        msg = |{ msg }'/'{ mtext }|.
        msg = |'订单'{ lv_sales_order }'进项存系统项目编号'{ lv_out_line_no }'新增SAP项目行失败:'{ msg }|.
        RETURN.
      ENDIF.
    ENDIF.

  ENDMETHOD.


  METHOD deal_0002_act04_return.
    DATA:lv_msg                      TYPE bapi_msg,
         ls_t100key                  TYPE scx_t100key,
         lv_msgid                    TYPE symsgid,
         lv_msgno                    TYPE symsgno,
         lv_msgv1                    LIKE sy-msgv1,
         lv_msgv2                    LIKE sy-msgv2,
         lv_msgv3                    LIKE sy-msgv3,
         lv_msgv4                    LIKE sy-msgv4,
         lv_sales_order              TYPE vbeln,
         lv_sales_order_item         TYPE posnr,
         ls_sales_order_item         TYPE i_salesorderitemtp,
         ls_sales_order_item_pricing TYPE i_salesorderitemprcgelmnttp,
         lv_product                  TYPE char18.
    FIELD-SYMBOLS:<fs_salesorder_tab> TYPE STANDARD TABLE,
                  <fs_salesorder>     TYPE any,
                  <fs_msg>            TYPE REF TO if_abap_behv_message,
                  <fs_t100key>        TYPE any.
    lv_sales_order = ls_req-sales_order.
    lv_sales_order = |{ lv_sales_order ALPHA = IN }|.
    lv_sales_order_item = ls_req-sales_order_item.
    lv_product = ls_req-material.
    lv_product = |{ lv_product ALPHA = IN }|.
    ls_sales_order_item-product = lv_product.
    CONDENSE ls_req-requested_quantity NO-GAPS.
    ls_sales_order_item-requestedquantity = ls_req-requested_quantity.
    ls_sales_order_item-requestedquantityunit = ls_req-requested_quantity_unit.
    ls_sales_order_item-plant = ls_req-plant.
    ls_sales_order_item-materialbycustomer = ls_req-material_by_customer.
    CONDENSE ls_req-condition_rate_value NO-GAPS.
    ls_sales_order_item_pricing-conditionrateamount = ls_req-condition_rate_value.
    DATA(lv_out_line_no) = ls_req-underlying_purchase_order_item.

    SELECT SINGLE *
      FROM i_customerreturnitemtp WITH PRIVILEGED ACCESS
     WHERE customerreturn = @lv_sales_order
       AND customerreturnitem = @lv_sales_order_item
       INTO @DATA(ls_item).
    IF ls_sales_order_item-product NE ls_item-product.
      DATA(lv_item_change) = 'X'.
    ENDIF.

    SELECT SINGLE *
             FROM i_unitofmeasure
            WHERE unitofmeasure_e = @ls_sales_order_item-requestedquantityunit
             INTO @DATA(ls_unit).
    IF sy-subrc NE 0.
      flag = 'E'.
      msg = |'订单'{ lv_sales_order }'项目'{ lv_sales_order_item }'新增行失败:'|
      && |单位{ ls_sales_order_item-requestedquantityunit }不存在|.
      RETURN.
    ENDIF.

    IF lv_item_change = 'X'.
      "插入新行项目
      MODIFY ENTITIES OF i_customerreturntp PRIVILEGED
       ENTITY customerreturn
       CREATE BY \_item
       FIELDS ( product productionplant requestedquantity requestedquantityunit materialbycustomer )
       WITH VALUE #( (
       customerreturn = lv_sales_order
       %target = VALUE #( ( %cid = 'I001'
       product = ls_sales_order_item-product
       productionplant   = ls_sales_order_item-plant
       requestedquantity = ls_sales_order_item-requestedquantity
       requestedquantityunit = ls_unit-unitofmeasure
       materialbycustomer = ls_req-underlying_purchase_order_item ) ) ) )
       ENTITY customerreturnitem
       CREATE BY \_itempricingelement
       FIELDS ( conditiontype
       conditionrateamount  )
       WITH VALUE #( ( %cid_ref = 'I001'
       customerreturn = lv_sales_order
       customerreturnitem = space
       %target = VALUE #( ( %cid = 'IP001'
       conditiontype = 'ZPR0'
       conditionrateamount = ls_sales_order_item_pricing-conditionrateamount ) ) ) )
       FAILED DATA(ls_failed_item_new)
       REPORTED DATA(ls_reported_item_new).
      MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO FINAL(mtext).
      IF ls_failed_item_new IS NOT INITIAL.
        flag = 'E'.
        me->deal_0002_get_msg( EXPORTING ls_failed = ls_failed_item_new
                                         ls_reported = ls_reported_item_new
                                         lv_component = 'CUSTOMERRETURNITEM'
                               IMPORTING msg = msg     ).
        IF msg IS INITIAL.
          me->deal_0002_get_msg( EXPORTING ls_failed = ls_failed_item_new
                                           ls_reported = ls_failed_item_new
                                           lv_component = 'CUSTOMERRETURN'
                                 IMPORTING msg = msg     ).
        ENDIF.
        IF msg IS INITIAL.
          me->deal_0002_get_msg( EXPORTING ls_failed = ls_failed_item_new
                                           ls_reported = ls_reported_item_new
                                           lv_component = 'CUSTRETURNITEMPRICINGELEMENT'
                                 IMPORTING msg = msg     ).
        ENDIF.
        msg = |{ msg }'/'{ mtext }|.
        msg = |'订单'{ lv_sales_order }'进项存系统项目编号'{ lv_out_line_no }'新增SAP项目行失败:'{ msg }|.
        RETURN.
      ENDIF.
    ENDIF.

  ENDMETHOD.


  METHOD deal_0002_act05.
    DATA:lv_msg                 TYPE bapi_msg,
         ls_t100key             TYPE scx_t100key,
         lv_msgid               TYPE symsgid,
         lv_msgno               TYPE symsgno,
         lv_msgv1               LIKE sy-msgv1,
         lv_msgv2               LIKE sy-msgv2,
         lv_msgv3               LIKE sy-msgv3,
         lv_msgv4               LIKE sy-msgv4,
         lv_sales_order         TYPE vbeln,
         lv_sales_order_item    TYPE posnr,
         ls_sales_order_item    TYPE i_salesorderitemtp,
         ls_sales_order_pricing TYPE i_salesorderpricingelementtp.
    FIELD-SYMBOLS:<fs_salesorder_tab> TYPE STANDARD TABLE,
                  <fs_salesorder>     TYPE any,
                  <fs_msg>            TYPE REF TO if_abap_behv_message,
                  <fs_t100key>        TYPE any.
    lv_sales_order = ls_req-sales_order.
    lv_sales_order = |{ lv_sales_order ALPHA = IN }|.
    CONDENSE ls_req-condition_rate_value_rebates NO-GAPS.
    ls_sales_order_pricing-conditionrateamount = ls_req-condition_rate_value_rebates.

    SELECT SINGLE *
          FROM i_salesorderpricingelementtp WITH PRIVILEGED ACCESS
         WHERE salesorder = @lv_sales_order
           AND conditiontype = 'ZD10'
           INTO @DATA(ls_item_price).
    IF ls_sales_order_pricing-conditionrateamount NE ls_item_price-conditionrateamount.
      DATA(lv_price_change) = 'X'.
    ENDIF.

    IF lv_price_change IS INITIAL.
      flag = 'E'.
      msg = |'订单'{ lv_sales_order }'项目抬头【返利金额】未发生变化，无需修改'|.
      RETURN.
    ENDIF.

    IF lv_price_change = 'X'.

      MODIFY ENTITIES OF i_salesordertp PRIVILEGED
           ENTITY salesorder
           CREATE BY \_pricingelement
           FIELDS ( conditiontype
           conditionrateamount  )
           WITH VALUE #( (
           salesorder = lv_sales_order
           %target = VALUE #( ( %cid = 'IP001'
           conditiontype = 'ZD10'
           conditionrateamount = ls_sales_order_pricing-conditionrateamount ) ) ) )
           FAILED DATA(ls_failed_price)
           REPORTED DATA(ls_reported_price).
      MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO FINAL(mtext).
      IF ls_failed_price IS NOT INITIAL.
        flag = 'E'.
        me->deal_0002_get_msg( EXPORTING ls_failed = ls_failed_price
                                         ls_reported = ls_reported_price
                                         lv_component = 'SALESORDERPRICINGELEMENT'
                               IMPORTING msg = msg     ).
        IF msg IS INITIAL.
          me->deal_0002_get_msg( EXPORTING ls_failed = ls_failed_price
                                           ls_reported = ls_reported_price
                                           lv_component = 'SALESORDER'
                                 IMPORTING msg = msg     ).
        ENDIF.
        msg = |{ msg }'/'{ mtext }|.
        msg = |'订单'{ lv_sales_order }'项目抬头【返利金额】修改失败:'{ msg }|.

        RETURN.
      ENDIF.
    ENDIF.

  ENDMETHOD.


  METHOD  deal_0002_get_msg.
    DATA:lv_msg     TYPE bapi_msg,
         ls_t100key TYPE scx_t100key,
         lv_msgid   TYPE symsgid,
         lv_msgno   TYPE symsgno,
         lv_msgv1   LIKE sy-msgv1,
         lv_msgv2   LIKE sy-msgv2,
         lv_msgv3   LIKE sy-msgv3,
         lv_msgv4   LIKE sy-msgv4.

    FIELD-SYMBOLS:<fs_salesorder_tab> TYPE STANDARD TABLE,
                  <fs_salesorder>     TYPE any,
                  <fs_msg>            TYPE REF TO if_abap_behv_message,
                  <fs_t100key>        TYPE any.

    ASSIGN COMPONENT lv_component OF STRUCTURE ls_reported TO <fs_salesorder_tab>.
    IF <fs_salesorder_tab> IS ASSIGNED AND <fs_salesorder_tab> IS NOT INITIAL.

      LOOP AT <fs_salesorder_tab> ASSIGNING <fs_salesorder>.
        CLEAR:lv_msgid,lv_msgno,lv_msgv1,lv_msgv2,lv_msgv3,lv_msgv3.
        ASSIGN COMPONENT '%MSG' OF STRUCTURE <fs_salesorder> TO <fs_msg>.
        IF <fs_msg> IS ASSIGNED AND <fs_msg> IS NOT INITIAL.
          ASSIGN <fs_msg>->('IF_T100_MESSAGE~T100KEY') TO <fs_t100key>.
          IF <fs_t100key> IS ASSIGNED AND <fs_t100key> IS NOT INITIAL.
            ASSIGN COMPONENT 'MSGID' OF STRUCTURE <fs_t100key> TO FIELD-SYMBOL(<fs_msgid>).
            ASSIGN COMPONENT 'MSGNO' OF STRUCTURE <fs_t100key> TO FIELD-SYMBOL(<fs_msgno>).
          ENDIF.
          ASSIGN <fs_msg>->('IF_T100_DYN_MSG~MSGV1') TO FIELD-SYMBOL(<fs_msgv1>).
          ASSIGN <fs_msg>->('IF_T100_DYN_MSG~MSGV2') TO FIELD-SYMBOL(<fs_msgv2>).
          ASSIGN <fs_msg>->('IF_T100_DYN_MSG~MSGV3') TO FIELD-SYMBOL(<fs_msgv3>).
          ASSIGN <fs_msg>->('IF_T100_DYN_MSG~MSGV4') TO FIELD-SYMBOL(<fs_msgv4>).
          IF <fs_msgid> IS ASSIGNED AND <fs_msgid> IS NOT INITIAL.
            lv_msgid = <fs_msgid>.
          ENDIF.
          IF <fs_msgno> IS ASSIGNED AND <fs_msgno> IS NOT INITIAL.
            lv_msgno = <fs_msgno>.
          ENDIF.
          IF <fs_msgv1> IS ASSIGNED AND <fs_msgv1> IS NOT INITIAL.
            lv_msgv1 = <fs_msgv1>.
          ENDIF.
          IF <fs_msgv2> IS ASSIGNED AND <fs_msgv2> IS NOT INITIAL.
            lv_msgv2 = <fs_msgv2>.
          ENDIF.
          IF <fs_msgv3> IS ASSIGNED AND <fs_msgv3> IS NOT INITIAL.
            lv_msgv3 = <fs_msgv3>.
          ENDIF.
          IF <fs_msgv4> IS ASSIGNED AND <fs_msgv4> IS NOT INITIAL.
            lv_msgv4 = <fs_msgv4>.
          ENDIF.
          IF lv_msgid IS NOT INITIAL
            AND lv_msgno IS NOT INITIAL.
            MESSAGE ID lv_msgid TYPE 'S' NUMBER lv_msgno
              INTO FINAL(mtext1)
              WITH lv_msgv1 lv_msgv2 lv_msgv3 lv_msgv4.
            IF msg IS INITIAL.
              msg = mtext1.
            ELSE.
              msg = |{ msg }/{ mtext1 }|.
            ENDIF.
          ENDIF.
          UNASSIGN:<fs_msgid>,<fs_msgno>,<fs_msgv1>,<fs_msgv2>,<fs_msgv3>,<fs_msgv4>.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.


  METHOD  save_zztsd_0001.
    DATA:lt_zztsd_0001 TYPE TABLE OF zztsd_0001.
    SELECT a~salesdocument AS sales_order,
           a~purchaseorderbycustomer AS purchase_order_by_customer,
           b~salesdocumentitem AS sales_order_item,
           b~materialbycustomer AS underlying_purchase_order_item
      FROM i_salesdocument WITH PRIVILEGED ACCESS AS a
      INNER JOIN i_salesdocumentitem  WITH PRIVILEGED ACCESS AS b
        ON a~salesdocument = b~salesdocument
     WHERE a~salesdocument = @lv_sales_order
       AND b~salesdocumentrjcnreason = ''
      INTO TABLE @DATA(lt_data).
    lt_zzt_sdi002_0001_out = CORRESPONDING #( DEEP lt_data ).
    LOOP AT lt_zzt_sdi002_0001_out ASSIGNING FIELD-SYMBOL(<fs_out>).
      <fs_out>-underlying_purchase_order_item = |{ <fs_out>-underlying_purchase_order_item ALPHA = OUT }|.
    ENDLOOP.
    lt_zztsd_0001 = CORRESPONDING #( DEEP lt_data ).
    LOOP AT lt_zztsd_0001 ASSIGNING FIELD-SYMBOL(<fs_zztsd_0001>).
      <fs_zztsd_0001>-zdate = cl_abap_context_info=>get_system_date( ).
      <fs_zztsd_0001>-ztime = cl_abap_context_info=>get_system_time( ).
      <fs_zztsd_0001>-zuser = cl_abap_context_info=>get_user_technical_name( ).
    ENDLOOP.
    MODIFY zztsd_0001 FROM TABLE @lt_zztsd_0001.
  ENDMETHOD.
ENDCLASS.
