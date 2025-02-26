FUNCTION zzfm_sd_001.
*"----------------------------------------------------------------------
*"*"本地接口：
*"  IMPORTING
*"     REFERENCE(I_REQ) TYPE  ZZS_SDI001_REQ OPTIONAL
*"  EXPORTING
*"     REFERENCE(O_RESP) TYPE  ZZS_REST_OUT
*"----------------------------------------------------------------------
  " You can use the template 'functionModuleParameter' to add here the signature!
  .
  TYPES: BEGIN OF ty_emailaddress,
           emailaddress TYPE string,
         END OF ty_emailaddress,
         BEGIN OF ty_phonenumber,
           phonenumber TYPE string,
         END OF ty_phonenumber,

         BEGIN OF ty_businesspartneraddres,
           country         TYPE string,
           language        TYPE string,
           streetname      TYPE string,
           to_phonenumber  TYPE TABLE OF ty_phonenumber WITH EMPTY KEY,
           to_emailaddress TYPE TABLE OF ty_emailaddress WITH EMPTY KEY,
         END OF ty_businesspartneraddres,
         BEGIN OF ty_businesspartnertax,
           bptaxtype       TYPE string,
           bptaxlongnumber TYPE string,
         END OF ty_businesspartnertax,
         BEGIN OF ty_businesspartnerrole,
           businesspartnerrole TYPE string,
         END OF ty_businesspartnerrole,
         BEGIN OF ty_partnerfunction,
           partnerfunction TYPE string,
         END OF ty_partnerfunction,
         BEGIN OF ty_salesareatax,
           departurecountry          TYPE string,
           customertaxcategory       TYPE string,
           customertaxclassification TYPE string,
         END OF ty_salesareatax,
         BEGIN OF ty_businesspartnerbank,
           businesspartner          TYPE string,
           bankidentification       TYPE string,
           bankcountrykey           TYPE string,
           banknumber               TYPE string,
           bankaccount              TYPE string,
           bankaccountreferencetext TYPE string,
         END OF ty_businesspartnerbank,

         BEGIN OF ty_customersalesarea,
           customeraccountgroup           TYPE string,
           salesorganization              TYPE string,
           distributionchannel            TYPE string,
           division                       TYPE string,
           currency                       TYPE string,
           customeraccountassignmentgroup TYPE string,
           customerpaymentterms           TYPE string,
           incotermsclassification        TYPE string,
           incotermslocation1             TYPE string,
           shippingcondition              TYPE string,
           customerpricingprocedure       TYPE string,
           supplyingplant                 TYPE string,
           to_salesareatax                TYPE TABLE OF ty_salesareatax    WITH EMPTY KEY,
           to_partnerfunction             TYPE TABLE OF ty_partnerfunction WITH EMPTY KEY,
         END OF ty_customersalesarea,
         BEGIN OF ty_customercompany,
           companycode           TYPE string,
           paymentterms          TYPE string,
           reconciliationaccount TYPE string,
           layoutsortingrule     TYPE string,
         END OF ty_customercompany,

         BEGIN OF ty_customer,
           to_customersalesarea TYPE TABLE OF ty_customersalesarea WITH EMPTY KEY,
           to_customercompany   TYPE TABLE OF ty_customercompany WITH EMPTY KEY,
         END OF ty_customer,

         BEGIN OF ty_data,
           businesspartner           TYPE string,
           businesspartnergrouping   TYPE string,
           businesspartnercategory   TYPE string,
           organizationbpname1       TYPE string,
           searchterm1               TYPE char20,
           formofaddress             TYPE string,
           to_businesspartneraddress TYPE TABLE OF ty_businesspartneraddres WITH EMPTY KEY,
           to_businesspartnertax     TYPE TABLE OF ty_businesspartnertax WITH EMPTY KEY,
           to_businesspartnerrole    TYPE TABLE OF ty_businesspartnerrole WITH EMPTY KEY,
           to_businesspartnerbank    TYPE TABLE OF ty_businesspartnerbank WITH EMPTY KEY,
           to_customer               TYPE ty_customer,
         END OF ty_data.

  DATA:lv_json TYPE string.
  DATA:ls_data TYPE ty_data.
  DATA:lv_flag TYPE abap_boolean.
  DATA:ls_businesspartneraddres TYPE ty_businesspartneraddres.
  DATA:lt_mapping TYPE /ui2/cl_json=>name_mappings.

  DATA(ls_req) = i_req-req.
  DATA(lo_dest) = zzcl_comm_tool=>get_dest( ).

  gv_businesspartner = |{  ls_req-businesspartner ALPHA = IN }|.

  "判断创建还是修改
  SELECT COUNT(*)
    FROM i_businesspartner WITH PRIVILEGED ACCESS
   WHERE businesspartner = @gv_businesspartner.
  IF sy-subrc = 0.
    lv_flag = 'U'.
  ELSE.
    lv_flag = 'I'.
  ENDIF.

*&---导入结构JSON MAPPING
  lt_mapping = VALUE #(
       ( abap = 'BusinessPartnerGrouping'              json = 'BusinessPartnerGrouping'      )
       ( abap = 'BusinessPartnerCategory'              json = 'BusinessPartnerCategory'      )
       ( abap = 'OrganizationBPName1'                  json = 'OrganizationBPName1'          )
       ( abap = 'SearchTerm1'                          json = 'SearchTerm1'                  )
       ( abap = 'FormOfAddress'                        json = 'FormOfAddress'                )

       ( abap = 'to_BusinessPartnerAddress'            json = 'to_BusinessPartnerAddress'    )
       ( abap = 'Country'                              json = 'Country'                      )
       ( abap = 'Language'                             json = 'Language'                     )
       ( abap = 'StreetName'                           json = 'StreetName'                   )
       ( abap = 'to_PhoneNumber'                       json = 'to_PhoneNumber'               )
       ( abap = 'PhoneNumber'                          json = 'PhoneNumber'                  )
       ( abap = 'to_EmailAddress'                      json = 'to_EmailAddress'              )
       ( abap = 'EmailAddress'                         json = 'EmailAddress'                 )

       ( abap = 'to_BusinessPartnerTax'                json = 'to_BusinessPartnerTax'        )
       ( abap = 'BPTaxType'                            json = 'BPTaxType'                    )
       ( abap = 'BPTaxLongNumber'                      json = 'BPTaxLongNumber'              )

       ( abap = 'to_BusinessPartnerRole'               json = 'to_BusinessPartnerRole'       )
       ( abap = 'BusinessPartnerRole'                  json = 'BusinessPartnerRole'          )

       ( abap = 'to_Customer'                          json = 'to_Customer'                  )
       ( abap = 'to_CustomerSalesArea'                 json = 'to_CustomerSalesArea'         )
       ( abap = 'SalesOrganization'                    json = 'SalesOrganization'            )
       ( abap = 'DistributionChannel'                  json = 'DistributionChannel'          )
       ( abap = 'Division'                             json = 'Division'                     )
       ( abap = 'Currency'                             json = 'Currency'                     )
       ( abap = 'CustomerAccountAssignmentGroup'       json = 'CustomerAccountAssignmentGroup'  )
       ( abap = 'CustomerPaymentTerms'                 json = 'CustomerPaymentTerms'         )
       ( abap = 'CustomerPricingProcedure'             json = 'CustomerPricingProcedure'     )
       ( abap = 'ShippingCondition'                    json = 'ShippingCondition'            )
       ( abap = 'SupplyingPlant'                       json = 'SupplyingPlant'               )
       ( abap = 'IncotermsClassification'              json = 'IncotermsClassification'      )
       ( abap = 'IncotermsLocation1'                   json = 'IncotermsLocation1'           )
       ( abap = 'CustomerAccountGroup'                 json = 'CustomerAccountGroup'         )

       ( abap = 'to_SalesAreaTax'                      json = 'to_SalesAreaTax'              )
       ( abap = 'DepartureCountry'                     json = 'DepartureCountry'             )
       ( abap = 'CustomerTaxCategory'                  json = 'CustomerTaxCategory'          )
       ( abap = 'CustomerTaxClassification'            json = 'CustomerTaxClassification'    )

       ( abap = 'to_PartnerFunction'                   json = 'to_PartnerFunction'           )
       ( abap = 'PartnerFunction'                      json = 'PartnerFunction'              )
       ( abap = 'PartnerCounter'                       json = 'PartnerCounter'               )

       ( abap = 'to_CustomerCompany'                   json = 'to_CustomerCompany'           )
       ( abap = 'CompanyCode'                          json = 'CompanyCode'                  )
       ( abap = 'PaymentTerms'                         json = 'PaymentTerms'                 )
       ( abap = 'ReconciliationAccount'                json = 'ReconciliationAccount'        )
       ( abap = 'LayoutSortingRule'                    json = 'LayoutSortingRule'            )
).


  CASE  lv_flag.
    WHEN 'I'.

      "默认值------BEGIN-------
      "基础视图
      ls_data-businesspartner = ls_req-businesspartner. "合作伙伴编码
      ls_data-businesspartnercategory = '2'. "业务伙伴类别
      ls_data-formofaddress = '0003'. "称谓
      ls_data-businesspartnergrouping = 'Z002'. "业务伙伴分组
      ls_data-organizationbpname1 = ls_req-organizationbpname1. "组织名称 1
      ls_data-searchterm1 = ls_req-searchterm1. "搜索项 1

      "地址
      ls_businesspartneraddres-country = 'CN'.
      ls_businesspartneraddres-language = 'ZH'.
      ls_businesspartneraddres-streetname = ls_req-streetname.
      "邮箱
      IF ls_req-emailaddress IS NOT INITIAL.
        APPEND VALUE #(
         emailaddress = ls_req-emailaddress
        ) TO ls_businesspartneraddres-to_emailaddress.
      ENDIF.
      "电话
      APPEND VALUE #(
                      phonenumber = ls_req-phonenumber
      ) TO ls_businesspartneraddres-to_phonenumber.

      APPEND ls_businesspartneraddres TO ls_data-to_businesspartneraddress.

      "税号
      IF ls_req-bptaxlongnumber IS NOT INITIAL.
        APPEND VALUE #(
                  bptaxtype       = 'CN5'
                  bptaxlongnumber = ls_req-bptaxlongnumber
         ) TO ls_data-to_businesspartnertax.
      ENDIF.

      "角色
      APPEND VALUE #(
              businesspartnerrole       = 'FLCU00'
        ) TO ls_data-to_businesspartnerrole.
      APPEND VALUE #(
              businesspartnerrole       = 'FLCU01'
        ) TO ls_data-to_businesspartnerrole.

      "银行视图
      IF ls_req-bankaccount IS NOT INITIAL.
        APPEND VALUE #(
                    bankidentification = '0001'      "标识
                    bankcountrykey = 'CN'            "银行国家
                    banknumber = ls_req-banknumber   "银行代码
                    bankaccount = ls_req-bankaccount "银行账号
                    bankaccountreferencetext = ls_req-bankaccountreferencetext "参考明细
         ) TO ls_data-to_businesspartnerbank.
      ENDIF.
      "销售视图
      APPEND VALUE #(
              customeraccountgroup = 'CUST'           "客户科目组
              salesorganization    = '1100'           "销售组织
              distributionchannel  = '10'             "分销渠道
              division             = '10'             "产品组
              currency             = 'CNY'            "货币
              customeraccountassignmentgroup = '01'   "客户科目分配组
              customerpaymentterms = 'N001'           "客户付款条件
              incotermsclassification = 'DAP'         "国际贸易条款
              incotermslocation1   = ls_req-searchterm1           "国际贸易条款位置1
              shippingcondition    = '02'             "装运条件
              customerpricingprocedure = '01'         "Cust.Pric.过程
              supplyingplant       = '1100'           "装运工厂
              to_salesareatax = VALUE #( ( departurecountry = 'CN'
                                           customertaxcategory = 'TTX1'
                                           customertaxclassification = '1'
              ) )
              to_partnerfunction = VALUE #( ( partnerfunction = 'SP' )
                                            ( partnerfunction = 'BP' )
                                            ( partnerfunction = 'PY' )
                                            ( partnerfunction = 'SH' )
               )
       ) TO ls_data-to_customer-to_customersalesarea.
      APPEND VALUE #(
              customeraccountgroup = 'CUST'           "客户科目组
              salesorganization    = '1200'           "销售组织
              distributionchannel  = '10'             "分销渠道
              division             = '10'             "产品组
              currency             = 'CNY'            "货币
              customeraccountassignmentgroup = '01'   "客户科目分配组
              customerpaymentterms = 'N001'           "客户付款条件
              incotermsclassification = 'DAP'         "国际贸易条款
              incotermslocation1   = ls_req-searchterm1          "国际贸易条款位置1
              shippingcondition    = '02'             "装运条件
              customerpricingprocedure = '01'         "Cust.Pric.过程
              supplyingplant       = '1200'           "装运工厂
              to_salesareatax = VALUE #( ( departurecountry    = 'CN'
                                           customertaxcategory = 'TTX1'
                                           customertaxclassification = '1'
              ) )
              to_partnerfunction = VALUE #( ( partnerfunction = 'SP' )
                                            ( partnerfunction = 'BP' )
                                            ( partnerfunction = 'PY' )
                                            ( partnerfunction = 'SH' )
               )
       ) TO ls_data-to_customer-to_customersalesarea.

      "公司代码视图
      APPEND VALUE #(
           companycode            = '1100'           "公司代码
           paymentterms           = 'N001'           "付款条件
           reconciliationaccount  = '2205020100'     "统驭科目
           layoutsortingrule      = '009'            "排序
       ) TO ls_data-to_customer-to_customercompany.
      APPEND VALUE #(
           companycode            = '1200'           "公司代码
           paymentterms           = 'N001'           "付款条件
           reconciliationaccount  = '2205020100'     "统驭科目
           layoutsortingrule      = '009'            "排序
       ) TO ls_data-to_customer-to_customercompany.

      "默认值------END-------


*&---接口HTTP 链接调用
      TRY.
          DATA(lo_http_client) = cl_web_http_client_manager=>create_by_http_destination( lo_dest ).
          DATA(lo_request) = lo_http_client->get_http_request(   ).
          lo_http_client->enable_path_prefix( ).

          DATA(lv_uri_path) = |/API_BUSINESS_PARTNER/A_BusinessPartner|.

          lv_uri_path = lv_uri_path && |?sap-language=zh|.
          lo_request->set_uri_path( EXPORTING i_uri_path = lv_uri_path ).
          lo_request->set_header_field( i_name = 'Accept' i_value = 'application/json' ).
          "lo_request->set_header_field( i_name = 'If-Match' i_value = '*' ).
          lo_http_client->set_csrf_token(  ).

          lo_request->set_content_type( 'application/json' ).
          "传入数据转JSON
          lv_json = /ui2/cl_json=>serialize(
                data          = ls_data
                compress      = abap_true
                name_mappings = lt_mapping ).

          lo_request->set_text( lv_json ).

*&---执行http post 方法
          DATA(lo_response) = lo_http_client->execute( if_web_http_client=>post ).
*&---获取http reponse 数据
          DATA(lv_res) = lo_response->get_text(  ).
*&---确定http 状态
          DATA(status) = lo_response->get_status( ).
          IF status-code = '201'.
            TYPES:BEGIN OF ty_heads,
                    businesspartner TYPE string,
                  END OF ty_heads,
                  BEGIN OF ty_ress,
                    d TYPE ty_heads,
                  END OF  ty_ress.
            DATA:ls_ress TYPE ty_ress.
            /ui2/cl_json=>deserialize( EXPORTING json  = lv_res
                                        CHANGING data  = ls_ress ).

            o_resp-msgty  = 'S'.
            o_resp-msgtx  = 'success'.
            o_resp-sapnum = |{ ls_ress-d-businesspartner }|.


          ELSE.
            DATA:ls_rese TYPE zzs_odata_fail.
            /ui2/cl_json=>deserialize( EXPORTING json  = lv_res
                                        CHANGING data  = ls_rese ).
            o_resp-msgty = 'E'.
            o_resp-msgtx = ls_rese-error-message-value .

          ENDIF.

          lo_http_client->close( ).
        CATCH cx_web_http_client_error INTO DATA(lx_web_http_client_error).
          RETURN.
      ENDTRY.


    WHEN 'U'."修改

      "读取号码
      SELECT SINGLE a~addressid
        FROM i_buspartaddress WITH PRIVILEGED ACCESS AS a
       WHERE a~businesspartner = @gv_businesspartner
        INTO @gv_addressid.

      "更新抬头
      IF ls_req-organizationbpname1 IS NOT INITIAL
         OR ls_req-searchterm1 IS NOT INITIAL.
        CALL FUNCTION 'ZZFM_SD_001_BASIC'
          EXPORTING
            i_req  = i_req
          IMPORTING
            o_resp = o_resp.
        CHECK o_resp-msgty <> 'E'.
      ENDIF.


      "更新税号
      IF ls_req-bptaxlongnumber IS NOT INITIAL.
        CALL FUNCTION 'ZZFM_SD_001_TAX'
          EXPORTING
            i_req  = i_req
          IMPORTING
            o_resp = o_resp.
        CHECK o_resp-msgty <> 'E'.
      ENDIF.

      "更新银行
      IF ls_req-bankaccount IS NOT INITIAL.
        CALL FUNCTION 'ZZFM_SD_001_BANK'
          EXPORTING
            i_req  = i_req
          IMPORTING
            o_resp = o_resp.
        CHECK o_resp-msgty <> 'E'.
      ENDIF.

      "更新地址
      IF ls_req-streetname IS NOT INITIAL.
        CALL FUNCTION 'ZZFM_SD_001_ADDRESS'
          EXPORTING
            i_req  = i_req
          IMPORTING
            o_resp = o_resp.
        CHECK o_resp-msgty <> 'E'.
      ENDIF.

      "更新邮件
      IF ls_req-emailaddress IS NOT INITIAL.
        CALL FUNCTION 'ZZFM_SD_001_EMAIL'
          EXPORTING
            i_req  = i_req
          IMPORTING
            o_resp = o_resp.
        CHECK o_resp-msgty <> 'E'.
      ENDIF.

      "更新电话
      IF ls_req-phonenumber IS NOT INITIAL.
        CALL FUNCTION 'ZZFM_SD_001_PHONE'
          EXPORTING
            i_req  = i_req
          IMPORTING
            o_resp = o_resp.
        CHECK o_resp-msgty <> 'E'.
      ENDIF.

      IF o_resp-msgty = ''.
        o_resp-msgty = 'S'.
        o_resp-msgtx = 'Success'.
        o_resp-sapnum = |{ gv_businesspartner ALPHA = OUT }|.
      ENDIF.
  ENDCASE.

ENDFUNCTION.
