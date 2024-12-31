FUNCTION zzfm_sd_005.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(I_REQ) TYPE  ZZS_SDI005_REQ OPTIONAL
*"  EXPORTING
*"     REFERENCE(O_RESP) TYPE  ZZS_SDI005_RES
*"----------------------------------------------------------------------
  .

  TYPES:BEGIN OF ty_deliverydocument,
          billoflading TYPE string,
        END OF ty_deliverydocument,
        BEGIN OF ty_udata,
          d TYPE ty_deliverydocument,
        END OF ty_udata.
  DATA:lt_mapping TYPE /ui2/cl_json=>name_mappings.
  DATA:lv_json TYPE string.
  DATA:ls_udata                TYPE ty_udata.
  DATA:ls_out TYPE zzs_sdi005_dlv_out.
  DATA:lv_deliverydocument TYPE i_deliverydocument-deliverydocument.

  DATA(lt_tmp) = i_req-req-deliverydocument.
  DATA(lo_dest) = zzcl_comm_tool=>get_dest( ).

  o_resp-msgty = 'S'.
  o_resp-msgtx = '数据接收成功，请看详细处理结果'.

  LOOP AT lt_tmp INTO DATA(ls_tmp).
    CLEAR:ls_out.
    ls_out-deliverydocument = ls_tmp.
    lv_deliverydocument = |{ ls_tmp ALPHA = IN }|.
    "获取销售订单类型
    SELECT SINGLE sddocumentcategory
      FROM i_deliverydocument WITH PRIVILEGED ACCESS
     WHERE deliverydocument = @lv_deliverydocument
      INTO @DATA(lv_sddocumentcategory).

    IF sy-subrc = 0.
      CASE lv_sddocumentcategory.
        WHEN 'J'."标准外向交货
          gv_srv = 'API_OUTBOUND_DELIVERY_SRV'.
          gv_flowhead = 'A_OutbDeliveryHeader'.
          gv_flowitem = 'A_OutbDeliveryItem'.
        WHEN 'T'."客户退货
          gv_srv = 'API_CUSTOMER_RETURNS_DELIVERY_SRV'.
          gv_flowhead = 'A_ReturnsDeliveryHeader'.
          gv_flowitem = 'A_ReturnsDeliveryItem'.
      ENDCASE.
    ELSE.
      ls_out-msgty = 'E'.
      ls_out-msgtx = '交货单不存在！'.
      APPEND ls_out TO o_resp-res.
      RETURN.
    ENDIF.

    ls_udata-d-billoflading = '签收确认'.
    "eg
    "配合增强使用，增强YY1_LE_SHP_SAVE_DOCUMENT_PREPA 里判断billoflading = '签收确认'，
    "清空 外部计划控制权转移日期

*&---导入结构json MAPPING
    lt_mapping = VALUE #(
         ( abap = 'd'                              json = 'd'                )
         ( abap = 'BillOfLading'                   json = 'BillOfLading'     )
       ).

*&---接口http 链接调用
    TRY.
        DATA(lo_http_client) = cl_web_http_client_manager=>create_by_http_destination( lo_dest ).
        DATA(lo_request) = lo_http_client->get_http_request(   ).

        DATA(lv_uri_path) = |/{ gv_srv };v=0002/{ gv_flowhead }('{ lv_deliverydocument }')| && |?{ gv_langu }| .
        lo_request->set_uri_path( EXPORTING i_uri_path = lv_uri_path ).
        lo_request->set_header_field( i_name = 'Content-Type' i_value = 'application/json' ).
        lo_request->set_header_field( i_name = 'Accept' i_value = 'application/json' ).
        lo_request->set_header_field( i_name = 'If-Match' i_value = '*' ).
        lo_http_client->set_csrf_token(  ).

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

          ls_out-msgty = 'E'.
          ls_out-msgtx =  ls_rese-error-message-value .
        ELSE.
          ls_out-msgty = 'S'.
          ls_out-msgtx =  'success' .
        ENDIF.
        APPEND ls_out TO o_resp-res.
        lo_http_client->close( ).
      CATCH cx_web_http_client_error INTO DATA(lx_web_http_client_error).
        RETURN.
    ENDTRY.

  ENDLOOP.

ENDFUNCTION.
