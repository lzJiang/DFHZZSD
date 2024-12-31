FUNCTION zzfm_sd_001_tax.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(I_REQ) TYPE  ZZS_SDI001_REQ OPTIONAL
*"  EXPORTING
*"     REFERENCE(O_RESP) TYPE  ZZS_REST_OUT
*"----------------------------------------------------------------------
  .
  TYPES:BEGIN OF ty_utax,
          BPTaxNumber        TYPE string,
          BPTaxLongNumber    TYPE string,
          AuthorizationGroup TYPE string,
        END OF ty_utax,
        BEGIN OF ty_udata,
          d TYPE ty_utax,
        END OF ty_udata,
        BEGIN OF ty_cdata,
          BusinessPartner    TYPE string,
          BPTaxType          TYPE string,
          BPTaxNumber        TYPE string,
          BPTaxLongNumber    TYPE string,
          AuthorizationGroup TYPE string,
        END OF ty_cdata .
  DATA:lv_json TYPE string.
  DATA:ls_udata TYPE ty_udata.
  DATA:ls_cdata TYPE ty_cdata.


  DATA:lt_mapping TYPE /ui2/cl_json=>name_mappings.

  DATA(ls_req) = i_req-req.
  DATA(lo_dest) = zzcl_comm_tool=>get_dest( ).

  lt_mapping = VALUE #(
       ( abap = 'd'                            json = 'd'                    )
       ( abap = 'BusinessPartner'              json = 'BusinessPartner'      )
       ( abap = 'BPTaxType'                    json = 'BPTaxType'            )
       ( abap = 'BPTaxNumber'                  json = 'BPTaxNumber'          )
       ( abap = 'BPTaxLongNumber'              json = 'BPTaxLongNumber'      )
       ( abap = 'AuthorizationGroup'           json = 'AuthorizationGroup'   )
     ).

  "读取税号
  SELECT SINGLE *  "#EC CI_ALL_FIELDS_NEEDED
    FROM I_Businesspartnertaxnumber WITH PRIVILEGED ACCESS
   WHERE BusinessPartner = @gv_BusinessPartner
    INTO @DATA(ls_TaxNmbr).

  IF sy-subrc = 0.

    ls_udata-d-bptaxlongnumber = ls_req-bptaxlongnumber.
    "更新
*&---接口HTTP 链接调用
    TRY.
        DATA(lo_http_client) = cl_web_http_client_manager=>create_by_http_destination( lo_dest ).
        DATA(lo_request) = lo_http_client->get_http_request(   ).
        lo_http_client->enable_path_prefix( ).

        DATA(lv_uri_path) = |/API_BUSINESS_PARTNER/A_BusinessPartnerTaxNumber|.
        lv_uri_path = lv_uri_path && |(BusinessPartner='{ gv_BusinessPartner }',| &&
                                     |BPTaxType='CN5')|.

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
          o_resp-msgtx = '税号信息更新失败' && ls_rese-error-message-value .
        ENDIF.

        lo_http_client->close( ).
        FREE:lo_http_client,lo_request,lv_uri_path,lo_request.

      CATCH cx_web_http_client_error INTO DATA(lx_web_http_client_error).
        RETURN.
    ENDTRY.

  ELSE.
    "创建
    ls_cdata-businesspartner = gv_BusinessPartner.
    ls_cdata-BPTaxType = 'CN5'.
    ls_cdata-bptaxlongnumber = ls_req-bptaxlongnumber.

    TRY.
        lo_http_client = cl_web_http_client_manager=>create_by_http_destination( lo_dest ).
        lo_request = lo_http_client->get_http_request(   ).
        lo_http_client->enable_path_prefix( ).
        lv_uri_path = |/API_BUSINESS_PARTNER/A_BusinessPartnerTaxNumber|.
        lo_request->set_uri_path( EXPORTING i_uri_path = lv_uri_path ).
        lo_request->set_header_field( i_name = 'Accept' i_value = 'application/json' ).
*       lo_request->set_header_field( i_name = 'If-Match' i_value = '*' ).
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
          o_resp-msgtx = '税号信息更新失败' && ls_rese-error-message-value .
        ENDIF.
        lo_http_client->close( ).
      CATCH cx_web_http_client_error INTO lx_web_http_client_error.
        RETURN.
    ENDTRY.

  ENDIF.



ENDFUNCTION.
