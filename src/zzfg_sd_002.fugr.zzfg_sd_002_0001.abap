FUNCTION zzfg_sd_002_0001.
*"----------------------------------------------------------------------
*"*"本地接口：
*"  IMPORTING
*"     REFERENCE(I_REQ) TYPE  ZZS_SDI002_0001_REQ OPTIONAL
*"  EXPORTING
*"     REFERENCE(O_RESP) TYPE  ZZS_SDI002_0001_RES
*"----------------------------------------------------------------------
  .
  DATA: ls_req         TYPE zzs_sdi002_0001_in,
        lo_util        TYPE REF TO zcl_sdi002_util,
        lv_sales_order TYPE vbeln.
  CLEAR:gv_flag,gv_msg.
  ls_req = i_req-req.

*1.检查数据
  CREATE OBJECT lo_util.
  lo_util->check_0001( EXPORTING ls_req = ls_req
                       IMPORTING flag = gv_flag
                                 msg  = gv_msg ).
  IF gv_flag = 'E'.
    o_resp-msgty = 'E'.
    o_resp-msgtx = gv_msg .
    RETURN.
  ENDIF.
*2.处理数据
  lo_util->deal_0001(  EXPORTING fsysid = i_req-fsysid
                       IMPORTING flag = gv_flag
                                 msg  = gv_msg
                       CHANGING ls_req = ls_req ).
  IF gv_flag = 'S'.
    o_resp-msgty = 'S'.
    o_resp-msgtx = '处理成功' .
    lv_sales_order = gv_msg.
    lv_sales_order = |{ lv_sales_order ALPHA = IN }|.
    o_resp-sapnum = lv_sales_order .
    lo_util->save_zztsd_0001( EXPORTING lv_sales_order = lv_sales_order
                              CHANGING lt_zzt_sdi002_0001_out = o_resp-res ).
    COMMIT WORK.
  ELSE.
    o_resp-msgty = 'E'.
    o_resp-msgtx = gv_msg .
  ENDIF.

ENDFUNCTION.
