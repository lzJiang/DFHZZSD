FUNCTION zzfm_sd_001_bank.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(I_REQ) TYPE  ZZS_SDI001_REQ OPTIONAL
*"  EXPORTING
*"     REFERENCE(O_RESP) TYPE  ZZS_REST_OUT
*"----------------------------------------------------------------------
  .

  TYPES:BEGIN OF ty_utax,
          BankCountryKey           TYPE string,
          BankNumber               TYPE string,
          BankName                 TYPE string,
          BankAccount              TYPE string,
          BankAccountReferenceText TYPE string,
        END OF ty_utax,
        BEGIN OF ty_udata,
          d TYPE ty_utax,
        END OF ty_udata,
        BEGIN OF ty_cdata,
          BusinessPartner          TYPE string,
          BankIdentification       TYPE string,
          BankCountryKey           TYPE string,
          BankNumber               TYPE string,
          BankAccount              TYPE string,
          BankAccountReferenceText TYPE string,
        END OF ty_cdata .
  DATA:lv_BusinessPartner TYPE I_BusinessPartner-BusinessPartner.
  DATA:lv_json TYPE string.
  DATA:ls_udata TYPE ty_udata.
  DATA:ls_cdata TYPE ty_cdata.


  DATA:lt_mapping TYPE /ui2/cl_json=>name_mappings.

  DATA(ls_req) = i_req-req.
  DATA(lo_dest) = zzcl_comm_tool=>get_dest( ).

  lv_BusinessPartner = |{ ls_req-BusinessPartner ALPHA = IN }|.

  lt_mapping = VALUE #(
       ( abap = 'd'                            json = 'd'                    )
       ( abap = 'BusinessPartner'              json = 'BusinessPartner'      )
       ( abap = 'BankIdentification'           json = 'BankIdentification'   )
       ( abap = 'BankCountryKey'               json = 'BankCountryKey'       )
       ( abap = 'BankNumber'                   json = 'BankNumber'           )
       ( abap = 'BankName'                     json = 'BankName'             )
       ( abap = 'BankAccount'                  json = 'BankAccount'          )
       ( abap = 'BankAccountReferenceText'     json = 'BankAccountReferenceText'   )
     ).


  "读取税号
  SELECT SINGLE BusinessPartner,BankIdentification
    FROM I_BusinessPartnerBank WITH PRIVILEGED ACCESS
   WHERE BusinessPartner = @lv_BusinessPartner
    INTO @DATA(ls_Bank).
  IF sy-subrc = 0.
    ls_udata-d-BankCountryKey = 'CN'.            "银行国家
    ls_udata-d-BankNumber = ls_req-BankNumber.
    ls_udata-d-BankAccount = ls_req-BankAccount.
    ls_udata-d-BankAccountReferenceText = ls_req-BankAccountReferenceText.
    "更新
*&---接口HTTP 链接调用
    TRY.
        DATA(lo_http_client) = cl_web_http_client_manager=>create_by_http_destination( lo_dest ).
        DATA(lo_request) = lo_http_client->get_http_request(   ).
        lo_http_client->enable_path_prefix( ).

        DATA(lv_uri_path) = |/API_BUSINESS_PARTNER/A_BusinessPartnerBank|.
        lv_uri_path = lv_uri_path && |(BusinessPartner='{ lv_BusinessPartner }',| &&
                                     |BankIdentification='{ ls_Bank-BankIdentification }')|.

        lo_request->set_uri_path( EXPORTING i_uri_path = lv_uri_path ).
        lo_request->set_header_field( i_name = 'Accept' i_value = 'application/json' ).
        lo_request->set_header_field( i_name = 'If-Match' i_value = '*' ).
        lo_http_client->set_csrf_token(  ).

        lo_request->set_content_type( 'application/json' ).
        "传入数据转JSON
        lv_json = /ui2/cl_json=>serialize(
              data          = ls_udata
              compress      = abap_true
              name_mappings = lt_mapping ).

        lo_request->set_text( lv_json ).

*&---执行http post 方法
        DATA(lo_response) = lo_http_client->execute( if_web_http_client=>patch ).
*&---获取http reponse 数据
        DATA(lv_res) = lo_response->get_text(  ).
*&---确定http 状态
        DATA(status) = lo_response->get_status( ).
        IF status-code <> '204'.
          DATA:ls_rese TYPE zzs_odata_fail.
          /ui2/cl_json=>deserialize( EXPORTING json  = lv_res
                                      CHANGING data  = ls_rese ).
          o_resp-msgty = 'E'.
          o_resp-msgtx = '银行信息更新失败' && ls_rese-error-message-value .
        ENDIF.

        lo_http_client->close( ).
        FREE:lo_http_client,lo_request,lv_uri_path,lo_request.

      CATCH cx_web_http_client_error INTO DATA(lx_web_http_client_error).
        RETURN.
    ENDTRY.
  ELSE.
    "创建
    ls_cdata-BusinessPartner = lv_BusinessPartner .     "客户
    ls_cdata-BankIdentification = '0001' .     "标识
    ls_cdata-BankCountryKey = 'CN'.            "银行国家
    ls_cdata-BankNumber = ls_req-BankNumber.   "银行代码
    ls_cdata-BankAccount = ls_req-BankAccount. "银行账号
    ls_cdata-BankAccountReferenceText = ls_req-BankAccountReferenceText ."参考明细

    TRY.
        lo_http_client = cl_web_http_client_manager=>create_by_http_destination( lo_dest ).
        lo_request = lo_http_client->get_http_request(   ).
        lo_http_client->enable_path_prefix( ).
        lv_uri_path = |/API_BUSINESS_PARTNER/A_BusinessPartnerBank|.
        lo_request->set_uri_path( EXPORTING i_uri_path = lv_uri_path ).
        lo_request->set_header_field( i_name = 'Accept' i_value = 'application/json' ).
*        lo_request->set_header_field( i_name = 'If-Match' i_value = '*' ).
        lo_http_client->set_csrf_token(  ).
        lo_request->set_content_type( 'application/json' ).
        "传入数据转JSON
        lv_json = /ui2/cl_json=>serialize(
              data          = ls_cdata
              compress      = abap_true
              name_mappings = lt_mapping ).

        lo_request->set_text( lv_json ).
*&---执行http post 方法
        lo_response = lo_http_client->execute( if_web_http_client=>post ).
*&---获取http reponse 数据
        lv_res = lo_response->get_text(  ).
*&---确定http 状态
        status = lo_response->get_status( ).
        IF status-code = '201'.
          o_resp-msgty  = 'S'.
          o_resp-msgtx  = 'success'.
        ELSE.
          /ui2/cl_json=>deserialize( EXPORTING json  = lv_res
                                      CHANGING data  = ls_rese ).
          o_resp-msgty = 'E'.
          o_resp-msgtx = '银行信息更新失败' &&  ls_rese-error-message-value .
        ENDIF.
        lo_http_client->close( ).
      CATCH cx_web_http_client_error INTO lx_web_http_client_error.
        RETURN.
    ENDTRY.

  ENDIF.



ENDFUNCTION.
