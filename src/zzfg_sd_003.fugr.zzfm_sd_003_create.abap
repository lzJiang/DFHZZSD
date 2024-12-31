FUNCTION zzfm_sd_003_create.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  EXPORTING
*"     REFERENCE(O_RESP) TYPE  ZZS_REST_OUT
*"----------------------------------------------------------------------
  .
  TYPES:BEGIN OF ty_deliverydocumentitem,
          referencesddocument     TYPE string,
          referencesddocumentitem TYPE string,
          actualdeliveryquantity  TYPE string,
          deliveryquantityunit    TYPE string,
        END OF ty_deliverydocumentitem,
        BEGIN OF ty_result,
          results TYPE TABLE OF ty_deliverydocumentitem WITH EMPTY KEY,
        END OF ty_result,
        BEGIN OF ty_cdata,
          shippingpoint           TYPE string,
          to_deliverydocumentitem TYPE ty_result,
        END OF ty_cdata.
  DATA:lt_mapping TYPE /ui2/cl_json=>name_mappings.
  DATA:lv_json TYPE string.
  DATA:ls_cdata                TYPE ty_cdata,
       ls_deliverydocumentitem TYPE ty_deliverydocumentitem.

  DATA(lo_dest) = zzcl_comm_tool=>get_dest( ).


*&---导入结构json MAPPING
  lt_mapping = VALUE #(
       ( abap = 'ShippingPoint'                        json = 'ShippingPoint'                )
       ( abap = 'to_DeliveryDocumentItem'              json = 'to_DeliveryDocumentItem'      )
       ( abap = 'results'                              json = 'results'                      )
       ( abap = 'ActualGoodsMovementDate'              json = 'ActualGoodsMovementDate'       )
       ( abap = 'ActualDeliveryQuantity'               json = 'ActualDeliveryQuantity'       )
       ( abap = 'DeliveryQuantityUnit'                 json = 'DeliveryQuantityUnit'         )
       ( abap = 'ReferenceSDDocument'                  json = 'ReferenceSDDocument'          )
       ( abap = 'ReferenceSDDocumentItem'              json = 'ReferenceSDDocumentItem'      )
     ).

  LOOP AT gt_create INTO DATA(gs_create).
    CLEAR:ls_deliverydocumentitem.
    MOVE-CORRESPONDING gs_create TO ls_deliverydocumentitem.
    CONDENSE ls_deliverydocumentitem-actualdeliveryquantity NO-GAPS.
    ls_deliverydocumentitem-deliveryquantityunit = gs_create-deliveryquantityunit.
    APPEND ls_deliverydocumentitem TO ls_cdata-to_deliverydocumentitem-results.
  ENDLOOP.

  ls_cdata-shippingpoint = '1000'.
*&---接口http 链接调用
  TRY.
      DATA(lo_http_client) = cl_web_http_client_manager=>create_by_http_destination( lo_dest ).
      DATA(lo_request) = lo_http_client->get_http_request(   ).
      lo_http_client->enable_path_prefix( ).

      DATA(lv_uri_path) = |/{ gv_srv };v=0002/| && gv_flowhead && |?{ gv_langu }|.

      lo_request->set_uri_path( EXPORTING i_uri_path = lv_uri_path ).
      lo_request->set_header_field( i_name = 'Content-Type' i_value = 'application/json' ).
      lo_request->set_header_field( i_name = 'Accept' i_value = 'application/json' ).
*      lo_request->set_header_field( i_name = 'If-Match' i_value = '*' ).
      lo_http_client->set_csrf_token(  ).

      "传入数据转JSON
      lv_json = /ui2/cl_json=>serialize(
            data          = ls_cdata
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
                deliverydocument TYPE string,
              END OF ty_heads,
              BEGIN OF ty_ress,
                d TYPE ty_heads,
              END OF  ty_ress.
        DATA:ls_ress TYPE ty_ress.
        /ui2/cl_json=>deserialize( EXPORTING json  = lv_res
                                    CHANGING data  = ls_ress ).

        o_resp-msgty  = 'S'.
        o_resp-msgtx  = 'success'.

        gv_deliverydocument = ls_ress-d-deliverydocument.
        gv_deliverydocument = |{ gv_deliverydocument ALPHA = IN }|.

      ELSE.
        DATA:ls_rese TYPE zzs_odata_fail.
        /ui2/cl_json=>deserialize( EXPORTING json  = lv_res
                                    CHANGING data  = ls_rese ).
        o_resp-msgty = 'E'.
        o_resp-msgtx = '创建交货单出错:' && ls_rese-error-message-value .

      ENDIF.
      lo_http_client->close( ).
    CATCH cx_web_http_client_error INTO DATA(lx_web_http_client_error).
      RETURN.
  ENDTRY.


ENDFUNCTION.
