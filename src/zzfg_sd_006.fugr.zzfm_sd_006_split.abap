FUNCTION zzfm_sd_006_split.
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

      DATA(lv_deliveryquantityunit) = cl_web_http_utility=>escape_url( CONV #( gs_data-deliveryquantityunit ) ).

      DATA(lv_uri_path) = |/{ gv_srv };v=0002/CreateBatchSplitItem?| &&
                          |Batch='{ gs_data-batch }'&| &&
                          |DeliveryDocument='{ gs_data-deliverydocument }'&| &&
                          |DeliveryDocumentItem='{ gs_data-deliverydocumentitem }'&| &&
                          |ActualDeliveryQuantity={ gs_data-actualdeliveryquantity }M&|  &&
                          |DeliveryQuantityUnit='{ lv_deliveryquantityunit }'&| && gv_langu.
      .
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

      lo_http_client->close( ).
      FREE:lo_http_client,lo_request,lo_response.
      IF status-code = '200'.
        TYPES:BEGIN OF ty_item,
                deliverydocument     TYPE string,
                deliverydocumentitem TYPE string,
              END OF ty_item,
              BEGIN OF ty_heads,
                createbatchsplititem TYPE ty_item,
              END OF ty_heads,
              BEGIN OF ty_ress,
                d TYPE ty_heads,
              END OF  ty_ress.
        DATA:ls_ress TYPE ty_ress.
        /ui2/cl_json=>deserialize( EXPORTING json  = lv_res
                                    CHANGING data  = ls_ress ).
        o_resp-msgty  = 'S'.
        o_resp-msgtx  = 'success'.

        IF gs_data-storagelocation IS NOT INITIAL.
          "更新库存地点
          gs_data-deliverydocumentitem = ls_ress-d-createbatchsplititem-deliverydocumentitem.
          CALL FUNCTION 'ZZFM_SD_006_UPDATE'
            IMPORTING
              o_resp = o_resp.
          "存储批次拆分行
          APPEND VALUE #( deliverydocument = gv_deliverydocument
                          deliverydocumentitem = gs_data-deliverydocumentitem
                        ) TO gt_lips_split.
        ENDIF.
      ELSE.
        DATA:ls_rese TYPE zzs_odata_fail.
        /ui2/cl_json=>deserialize( EXPORTING json  = lv_res
                                    CHANGING data  = ls_rese ).
        o_resp-msgty = 'E'.
        o_resp-msgtx = '交货单批次拆分失败:' && ls_rese-error-message-value .

      ENDIF.

    CATCH cx_web_http_client_error INTO DATA(lx_web_http_client_error).
      RETURN.
  ENDTRY.




ENDFUNCTION.
