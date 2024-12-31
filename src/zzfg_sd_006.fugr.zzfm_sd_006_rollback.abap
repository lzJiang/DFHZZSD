FUNCTION zzfm_sd_006_rollback.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  EXPORTING
*"     REFERENCE(O_RESP) TYPE  ZZS_REST_OUT
*"----------------------------------------------------------------------
  .


  TYPES:BEGIN OF ty_delivery,
          batch                        TYPE string,
          storagelocation              TYPE string,
          actualdeliveredqtyinbaseunit TYPE string,
        END OF ty_delivery,
        BEGIN OF ty_deliverys,
          d TYPE ty_delivery,
        END OF ty_deliverys.
  TYPES:BEGIN OF ty_head,
          actualgoodsmovementdate TYPE string,
          actualgoodsmovementtime TYPE string,
        END OF ty_head,
        BEGIN OF ty_heads,
          d TYPE ty_head,
        END OF ty_heads.

  DATA:lv_json TYPE string.
  DATA:lt_mapping TYPE /ui2/cl_json=>name_mappings.
  DATA:ls_delivery TYPE ty_deliverys.
  DATA:ls_head TYPE ty_heads.


*&---=============================使用API 步骤01
*&---=========1.API 类使用变量
  DATA(lo_dest) = zzcl_comm_tool=>get_dest( ).

*&---导入结构JSON MAPPING
  lt_mapping = VALUE #(
       ( abap = 'd'                                json = 'd'                            )
       ( abap = 'Batch'                            json = 'Batch'                        )
       ( abap = 'StorageLocation'                  json = 'StorageLocation'              )
       ( abap = 'ActualGoodsMovementDate'          json = 'ActualGoodsMovementDate'      )
       ( abap = 'ActualGoodsMovementTime'          json = 'ActualGoodsMovementTime'      )
       ( abap = 'ActualDeliveredQtyInBaseUnit'     json = 'ActualDeliveredQtyInBaseUnit' )
       ).

  "抬头回滚
  ls_head-d-actualgoodsmovementdate =  'NULL'.
  ls_head-d-actualgoodsmovementtime = 'NULL'.
  TRY.
      DATA(lo_http_client) = cl_web_http_client_manager=>create_by_http_destination( lo_dest ).
      DATA(lo_request) = lo_http_client->get_http_request(   ).
      DATA(lv_uri_path) = |/{ gv_srv };v=0002/{ gv_flowhead }(| &&
                          |DeliveryDocument='{ gv_deliverydocument }')| .
      lo_request->set_uri_path( EXPORTING i_uri_path = lv_uri_path ).
      lo_request->set_header_field( i_name = 'Content-Type' i_value = 'application/json' ).
      lo_request->set_header_field( i_name = 'Accept' i_value = 'application/json' ).
      lo_request->set_header_field( i_name = 'If-Match' i_value = '*' ).
      lo_http_client->set_csrf_token(  ).
      "传入数据转JSON
      lv_json = /ui2/cl_json=>serialize(
            data          = ls_head
            name_mappings = lt_mapping ).
      REPLACE ALL OCCURRENCES OF |"NULL"| IN  lv_json WITH 'null' .
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
        o_resp-msgtx = '回滚失败' && ls_rese-error-message-value .
      ENDIF.
      lo_http_client->close( ).
    CATCH cx_web_http_client_error INTO DATA(lx_web_http_client_error).
      RETURN.
  ENDTRY.


  "删除拆分行
  LOOP AT gt_lips_split INTO DATA(gs_lips_split).
*&---接口http 链接调用
    TRY.
        lo_http_client = cl_web_http_client_manager=>create_by_http_destination( lo_dest ).
        lo_request = lo_http_client->get_http_request(   ).
        lo_http_client->enable_path_prefix( ).

        lv_uri_path = |/{ gv_srv };v=0002/{ gv_flowitem }(| &&
                           |DeliveryDocument='{ gs_lips_split-deliverydocument }',| &&
                           |DeliveryDocumentItem='{ gs_lips_split-deliverydocumentitem }')| .
        lo_request->set_uri_path( EXPORTING i_uri_path = lv_uri_path ).
        lo_request->set_header_field( i_name = 'Accept' i_value = 'application/json' ).
        lo_request->set_header_field( i_name = 'If-Match' i_value = '*' ).
        lo_http_client->set_csrf_token(  ).

*&---执行http post 方法
        lo_response = lo_http_client->execute( if_web_http_client=>delete ).
*&---获取http reponse 数据
        lv_res = lo_response->get_text(  ).
*&---确定http 状态
        status = lo_response->get_status( ).
        IF status-code <> '204'.
          /ui2/cl_json=>deserialize( EXPORTING json  = lv_res
                                      CHANGING data  = ls_rese ).
          o_resp-msgty = 'E'.
          o_resp-msgtx = '回滚失败' && ls_rese-error-message-value .

        ENDIF.
        lo_http_client->close( ).
        FREE: lo_http_client,lo_request,lo_response.
      CATCH cx_web_http_client_error INTO lx_web_http_client_error.
        RETURN.
    ENDTRY.
  ENDLOOP.

  "原始行回滚
*&---接口http 链接调用
  LOOP AT gt_lips INTO DATA(gs_lips) .
    CLEAR:ls_delivery,lv_json.
    ls_delivery-d-actualdeliveredqtyinbaseunit = gs_lips-actualdeliveredqtyinbaseunit.
    CONDENSE ls_delivery-d-actualdeliveredqtyinbaseunit NO-GAPS.
    ls_delivery-d-batch           = gs_lips-batch.
    ls_delivery-d-storagelocation = gs_lips-storagelocation.
    IF ls_delivery-d-batch IS INITIAL.
      ls_delivery-d-batch  = 'NULL'.
    ENDIF.
    IF ls_delivery-d-storagelocation IS INITIAL.
      ls_delivery-d-storagelocation  = 'NULL'.
    ENDIF.
    TRY.
        lo_http_client = cl_web_http_client_manager=>create_by_http_destination( lo_dest ).
        lo_request = lo_http_client->get_http_request(   ).
*      lo_http_client->enable_path_prefix( ).

        lv_uri_path = |/{ gv_srv };v=0002/{ gv_flowitem }(| &&
                            |DeliveryDocument='{ gs_lips-deliverydocument }',| &&
                            |DeliveryDocumentItem='{ gs_lips-deliverydocumentitem }')| .
        lo_request->set_uri_path( EXPORTING i_uri_path = lv_uri_path ).
        lo_request->set_header_field( i_name = 'Content-Type' i_value = 'application/json' ).
        lo_request->set_header_field( i_name = 'Accept' i_value = 'application/json' ).
        lo_request->set_header_field( i_name = 'If-Match' i_value = '*' ).
        lo_http_client->set_csrf_token(  ).
        "传入数据转JSON
        lv_json = /ui2/cl_json=>serialize(
              data          = ls_delivery
              name_mappings = lt_mapping ).
        REPLACE ALL OCCURRENCES OF |"NULL"| IN  lv_json WITH 'null' .
        lo_request->set_text( lv_json ).
*&---执行http post 方法
        lo_response = lo_http_client->execute( if_web_http_client=>patch ).
*&---获取http reponse 数据
        lv_res = lo_response->get_text(  ).
*&---确定http 状态
        status = lo_response->get_status( ).
        IF status-code <> '204'.
          /ui2/cl_json=>deserialize( EXPORTING json  = lv_res
                                      CHANGING data  = ls_rese ).
          o_resp-msgty = 'E'.
          o_resp-msgtx = '回滚失败' && ls_rese-error-message-value .
        ENDIF.
        lo_http_client->close( ).
      CATCH cx_web_http_client_error INTO lx_web_http_client_error.
        RETURN.
    ENDTRY.
  ENDLOOP.



ENDFUNCTION.
