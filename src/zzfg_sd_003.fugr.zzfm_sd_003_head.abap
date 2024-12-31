FUNCTION zzfm_sd_003_head.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  EXPORTING
*"     REFERENCE(O_RESP) TYPE  ZZS_REST_OUT
*"----------------------------------------------------------------------
  .



  TYPES:BEGIN OF ty_delivery,
          actualgoodsmovementdate    TYPE string,
          actualgoodsmovementtime    TYPE string,
          deliverydocumentbysupplier TYPE string,
        END OF ty_delivery,
        BEGIN OF ty_deliverys,
          d TYPE ty_delivery,
        END OF ty_deliverys.
  DATA:lv_json TYPE string.
  DATA:lt_mapping TYPE /ui2/cl_json=>name_mappings.
  DATA:ls_delivery TYPE ty_deliverys.

  DATA(lo_dest) = zzcl_comm_tool=>get_dest( ).


*&---导入结构JSON MAPPING
  lt_mapping = VALUE #(
       ( abap = 'd'                                json = 'd'                            )
       ( abap = 'ActualGoodsMovementDate'          json = 'ActualGoodsMovementDate'      )
       ( abap = 'ActualGoodsMovementTime'          json = 'ActualGoodsMovementTime'      )
       ( abap = 'DeliveryDocumentBySupplier'       json = 'DeliveryDocumentBySupplier'      )


       ).

  ls_delivery-d-actualgoodsmovementdate =  gs_head-actualgoodsmovementdate.
  ls_delivery-d-deliverydocumentbysupplier =  gs_head-deliverydocumentbysupplier.

*&---接口http 链接调用
  TRY.
      DATA(lo_http_client) = cl_web_http_client_manager=>create_by_http_destination( lo_dest ).
      DATA(lo_request) = lo_http_client->get_http_request(   ).
*      lo_http_client->enable_path_prefix( ).

      DATA(lv_uri_path) = |/{ gv_srv };v=0002/{ gv_flowhead }('{ gv_deliverydocument }')| .
      lo_request->set_uri_path( EXPORTING i_uri_path = lv_uri_path ).
      lo_request->set_header_field( i_name = 'Content-Type' i_value = 'application/json' ).
      lo_request->set_header_field( i_name = 'Accept' i_value = 'application/json' ).


      lo_request->set_header_field( i_name = 'If-Match' i_value = '*' ).
      lo_http_client->set_csrf_token(  ).
      "传入数据转JSON
      lv_json = /ui2/cl_json=>serialize(
            data          = ls_delivery
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
        o_resp-msgtx = ls_rese-error-message-value .
      ENDIF.
      lo_http_client->close( ).
    CATCH cx_web_http_client_error INTO DATA(lx_web_http_client_error).
      RETURN.
  ENDTRY.



ENDFUNCTION.
