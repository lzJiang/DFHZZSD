FUNCTION zzfm_sd_003_post.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  EXPORTING
*"     REFERENCE(O_RESP) TYPE  ZZS_REST_OUT
*"----------------------------------------------------------------------
  .

  DATA(lo_dest) = zzcl_comm_tool=>get_dest( ).
*&---接口http 链接调用
  TRY.
      DATA(lo_http_client) = cl_web_http_client_manager=>create_by_http_destination( lo_dest ).
      DATA(lo_request) = lo_http_client->get_http_request(   ).
      lo_http_client->enable_path_prefix( ).


      CASE gv_srv.
        WHEN 'API_OUTBOUND_DELIVERY_SRV'.
          DATA(lv_uri_path) = |/{ gv_srv };v=0002/PostGoodsIssue?| &&
                              |DeliveryDocument='{ gv_deliverydocument }'|.
        WHEN 'API_CUSTOMER_RETURNS_DELIVERY_SRV'.
          lv_uri_path = |/{ gv_srv };v=0002/PostGoodsReceipt?|  &&
                        |DeliveryDocument='{ gv_deliverydocument }'|.
      ENDCASE.

      lo_request->set_uri_path( EXPORTING i_uri_path = lv_uri_path ).
      lo_request->set_header_field( i_name = 'Accept' i_value = 'application/json' ).
      lo_request->set_header_field( i_name = 'If-Match' i_value = '*' ).
      lo_http_client->set_csrf_token(  ).

*&---执行http post 方法
      DATA(lo_response) = lo_http_client->execute( if_web_http_client=>post ).
*&---获取http reponse 数据
      DATA(lv_res) = lo_response->get_text(  ).
*&---确定http 状态
      DATA(status) = lo_response->get_status( ).
      IF status-code = '200'.
        o_resp-msgty  = 'S'.
        o_resp-msgtx  = 'success'.
      ELSE.
        DATA:ls_rese TYPE zzs_odata_fail.
        /ui2/cl_json=>deserialize( EXPORTING json  = lv_res
                                    CHANGING data  = ls_rese ).
        o_resp-msgty = 'E'.
        o_resp-msgtx = '交货单过账失败:' && ls_rese-error-message-value .

      ENDIF.
      lo_http_client->close( ).
    CATCH cx_web_http_client_error INTO DATA(lx_web_http_client_error).
      RETURN.
  ENDTRY.

ENDFUNCTION.
