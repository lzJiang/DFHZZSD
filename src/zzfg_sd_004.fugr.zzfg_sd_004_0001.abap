FUNCTION zzfg_sd_004_0001.
*"----------------------------------------------------------------------
*"*"本地接口：
*"  IMPORTING
*"     REFERENCE(I_REQ) TYPE  ZZS_SDI004_0001_REQ OPTIONAL
*"  EXPORTING
*"     REFERENCE(O_RESP) TYPE  ZZS_REST_OUT
*"----------------------------------------------------------------------
  .
  DATA: ls_req      TYPE zzs_sdi004_0001_in,
        lt_req_item TYPE zzt_sdi004_0001_item_in,
        lo_util     TYPE REF TO zcl_sdi004_util,
        lv_billno   TYPE vbeln.
  CLEAR:gv_flag,gv_msg.
  ls_req = i_req-req.


*1.检查数据
  CREATE OBJECT lo_util.
  lo_util->check_0001( EXPORTING lt_req = ls_req-item[]
                       IMPORTING flag = gv_flag
                                 msg  = gv_msg ).
  IF gv_flag = 'E'.
    o_resp-msgty = 'E'.
    o_resp-msgtx = gv_msg .
    RETURN.
  ENDIF.
*2.处理数据
  lo_util->deal_0001(  EXPORTING defaultbillingdocumentdate = ls_req-default_billing_document_date
                       IMPORTING flag = gv_flag
                                 msg  = gv_msg
                       CHANGING lt_req = ls_req-item[] ).
  IF gv_flag = 'S'.
    o_resp-msgty = 'S'.
    o_resp-msgtx = '处理成功' .
    lv_billno = gv_msg.
    lv_billno = |{ lv_billno ALPHA = IN }|.
    o_resp-sapnum = lv_billno .
  ELSE.
    o_resp-msgty = 'E'.
    o_resp-msgtx = gv_msg .
  ENDIF.






ENDFUNCTION.
