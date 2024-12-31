FUNCTION zzfm_sd_006.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(I_REQ) TYPE  ZZS_SDI006_REQ OPTIONAL
*"  EXPORTING
*"     REFERENCE(O_RESP) TYPE  ZZS_REST_OUT
*"----------------------------------------------------------------------
  .
  DATA:lt_sub TYPE zzt_sdi006_in.

  DATA(lt_tmp) = i_req-req-item.
  SORT lt_tmp BY deliverydocumentitem batch.
  READ TABLE lt_tmp INTO DATA(ls_tmp) INDEX 1.

  gv_deliverydocument = |{ ls_tmp-deliverydocument ALPHA = IN }|.

  "获取历史数据
  "行项目
  SELECT a~deliverydocument,
         a~deliverydocumentitem,
         a~actualdeliveredqtyinbaseunit,
         a~batch,
         a~storagelocation
    FROM i_deliverydocumentitem WITH PRIVILEGED ACCESS AS a
    WHERE a~deliverydocument = @gv_deliverydocument
    INTO TABLE @gt_lips.


  gv_srv = 'API_OUTBOUND_DELIVERY_SRV'.
  gv_flowhead = 'A_OutbDeliveryHeader'.
  gv_flowitem = 'A_OutbDeliveryItem'.


  "更新抬头日期
  gs_head-actualgoodsmovementdate = i_req-req-head-actualgoodsmovementdate.
  gs_head-deliverydocumentbysupplier = i_req-req-head-deliverydocumentbysupplier.
  IF gs_head IS NOT INITIAL.
    gs_head-actualgoodsmovementdate = zzcl_comm_tool=>date2iso( gs_head-actualgoodsmovementdate ).
    CALL FUNCTION 'ZZFM_SD_006_HEAD'
      IMPORTING
        o_resp = o_resp.
  ENDIF.

  "判断是否批次拆分
  LOOP AT lt_tmp INTO ls_tmp GROUP BY ( itemid = ls_tmp-deliverydocumentitem
                                        count = GROUP SIZE ) INTO DATA(ls_group).
    IF ls_group-count <> 1.
      LOOP AT GROUP ls_group INTO DATA(ls_sub).
        APPEND ls_sub TO lt_sub.
      ENDLOOP.
    ENDIF.
  ENDLOOP.
  SORT lt_sub BY deliverydocumentitem.
  DELETE ADJACENT DUPLICATES FROM lt_sub COMPARING deliverydocumentitem.

  LOOP AT lt_tmp INTO ls_tmp.
    CLEAR:gs_data.
    gs_data-deliverydocument = ls_tmp-deliverydocument.
    gs_data-deliverydocumentitem = ls_tmp-deliverydocumentitem.
    gs_data-actualdeliveryquantity = ls_tmp-actualdeliveryquantity.
    gs_data-deliveryquantityunit = ls_tmp-deliveryquantityunit.
    gs_data-storagelocation = ls_tmp-storagelocation.
    gs_data-batch = ls_tmp-batch.
    "批次拆分
    READ TABLE lt_sub TRANSPORTING NO FIELDS WITH KEY deliverydocumentitem = ls_tmp-deliverydocumentitem  BINARY SEARCH.
    IF sy-subrc = 0.
      "批次拆分行，先拆批次，再更改库存地点
      CALL FUNCTION 'ZZFM_SD_006_SPLIT'
        IMPORTING
          o_resp = o_resp.
    ELSE.
      "非批次拆分行，先直接更改批次,库存地点
      CALL FUNCTION 'ZZFM_SD_006_UPDATE'
        IMPORTING
          o_resp = o_resp.
    ENDIF.

    IF o_resp-msgty = 'E'.
      EXIT.
    ENDIF.
  ENDLOOP.

  IF o_resp-msgty = 'E'.
    CALL FUNCTION 'ZZFM_SD_006_ROLLBACK'
      IMPORTING
        o_resp = o_resp.
    RETURN.
  ENDIF.

  "交货单过账
  CALL FUNCTION 'ZZFM_SD_006_POST'
    IMPORTING
      o_resp = o_resp.

  IF o_resp-msgty = 'E'.
    CALL FUNCTION 'ZZFM_SD_006_ROLLBACK'
      IMPORTING
        o_resp = o_resp.
    RETURN.
  ENDIF.

ENDFUNCTION.
