FUNCTION zzfm_sd_006_update.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  EXPORTING
*"     REFERENCE(O_RESP) TYPE  ZZS_REST_OUT
*"----------------------------------------------------------------------
  .

  TYPES:BEGIN OF ty_deliverydocumentitem,
          batch           TYPE string,
          storagelocation TYPE string,
        END OF ty_deliverydocumentitem,
        BEGIN OF ty_cdata,
          d TYPE ty_deliverydocumentitem,
        END OF ty_cdata.
  DATA:lt_mapping TYPE /ui2/cl_json=>name_mappings.
  DATA:lv_json TYPE string.
  DATA:ls_cdata                TYPE ty_cdata,
       ls_deliverydocumentitem TYPE ty_deliverydocumentitem.

  DATA(lo_dest) = zzcl_comm_tool=>get_dest( ).

  ls_cdata-d-batch = gs_data-batch.
  ls_cdata-d-storagelocation = gs_data-storagelocation.
*&---导入结构json MAPPING
  lt_mapping = VALUE #(
       ( abap = 'd'                              json = 'd'                )
       ( abap = 'Batch'                          json = 'Batch'            )
       ( abap = 'StorageLocation'                json = 'StorageLocation'  )
     ).


*&---接口http 链接调用
  TRY.
      DATA(lo_http_client) = cl_web_http_client_manager=>create_by_http_destination( lo_dest ).
      DATA(lo_request) = lo_http_client->get_http_request(   ).
*      lo_http_client->enable_path_prefix( ).

      DATA(lv_uri_path) = |/{ gv_srv };v=0002/{ gv_flowitem }(| &&
                          |DeliveryDocument='{ gs_data-deliverydocument }',| &&
                          |DeliveryDocumentItem='{ gs_data-deliverydocumentitem }')| .
      lo_request->set_uri_path( EXPORTING i_uri_path = lv_uri_path ).
      lo_request->set_header_field( i_name = 'Content-Type' i_value = 'application/json' ).
      lo_request->set_header_field( i_name = 'Accept' i_value = 'application/json' ).
      lo_request->set_header_field( i_name = 'If-Match' i_value = '*' ).
      lo_http_client->set_csrf_token(  ).

      lv_json = /ui2/cl_json=>serialize(
                 data          = ls_cdata
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
        o_resp-msgtx = '交货单行更新失败:' && ls_rese-error-message-value .
      ENDIF.
      lo_http_client->close( ).
    CATCH cx_web_http_client_error INTO DATA(lx_web_http_client_error).
      RETURN.
  ENDTRY.


ENDFUNCTION.
