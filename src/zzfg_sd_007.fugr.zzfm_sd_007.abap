FUNCTION zzfm_sd_007.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(I_REQ) TYPE  ZZS_SDI007_REQ OPTIONAL
*"  EXPORTING
*"     REFERENCE(O_RESP) TYPE  ZZS_SDI007_RES
*"----------------------------------------------------------------------
  " You can use the template 'functionModuleParameter' to add here the signature!
  .
  DATA(lt_tmp) = i_req-req.
  DATA:ls_req005 TYPE zzs_sdi005_req.
  DATA:ls_res005 TYPE zzs_sdi005_res.
  DATA:ls_out TYPE zzs_sdi007_out.
  DATA: lv_document TYPE vbeln_vl,
        lv_date     TYPE sy-datum,
        lt_create   TYPE TABLE FOR ACTION IMPORT i_billingdocumenttp~createfromsddocument.
  DATA:lv_flag TYPE abap_boolean.


  o_resp-msgty = 'S'.
  o_resp-msgtx = '数据接收成功，请看详细处理结果'.

  LOOP AT lt_tmp INTO DATA(ls_tmp).
    CLEAR:ls_out.
    ls_out-sddocument = ls_tmp-sddocument.

    lv_document = ls_tmp-sddocument.
    lv_document = |{ lv_document ALPHA = IN }|.
    SELECT a~deliverydocument,
           b~deliverydocumentitem,
           a~salesorganization,
           b~plant
      FROM i_deliverydocument WITH PRIVILEGED ACCESS AS a
      JOIN i_deliverydocumentitem WITH PRIVILEGED ACCESS AS b ON a~deliverydocument = b~deliverydocument
     WHERE a~deliverydocument = @lv_document
     INTO TABLE @DATA(lt_delivery).
    IF sy-subrc <> 0.
      ls_out-msgty = 'E'.
      ls_out-msgtx = |交货单{ ls_tmp-sddocument }不存在！|.
      APPEND ls_out TO o_resp-res.
      CONTINUE.
    ENDIF.


    "首先进行签收确认
    CLEAR:ls_req005,ls_res005,ls_out.
    APPEND ls_tmp-sddocument TO ls_req005-req-deliverydocument.
    CALL FUNCTION 'ZZFM_SD_005'
      EXPORTING
        i_req  = ls_req005
      IMPORTING
        o_resp = ls_res005.
    IF ls_res005-msgty = 'E'.
      ls_out-msgty = 'E'.
      ls_out-msgtx = |签收确认失败：{ ls_res005-res[ 1 ]-msgtx }|.
      APPEND ls_out TO o_resp-res.
      CONTINUE.
    ENDIF.

    "创建F2的发票
    CLEAR:lt_create,lv_date.
    IF ls_tmp-defaultbillingdocumentdate IS INITIAL.
      lv_date = sy-datum.
    ELSE.
      lv_date = ls_tmp-defaultbillingdocumentdate.
    ENDIF.

    APPEND INITIAL LINE TO lt_create ASSIGNING FIELD-SYMBOL(<fs_create>).
    <fs_create>-%param-%control = VALUE #( _reference = if_abap_behv=>mk-on
                                           _control = if_abap_behv=>mk-on ).

    <fs_create>-%param-_control = VALUE #( defaultbillingdocumentdate = lv_date
                                           defaultbillingdocumenttype = 'F2'
                                           %control = VALUE #( defaultbillingdocumentdate = if_abap_behv=>mk-on
                                                               defaultbillingdocumenttype = if_abap_behv=>mk-on  ) ).
    <fs_create>-%param-_reference = VALUE #( BASE <fs_create>-%param-_reference
                                           ( sddocument = lv_document
                                             %control = VALUE #( sddocument = if_abap_behv=>mk-on ) ) ).

    MODIFY ENTITIES OF i_billingdocumenttp PRIVILEGED
    ENTITY billingdocument
   EXECUTE createfromsddocument AUTO FILL CID WITH lt_create
    RESULT DATA(lt_result)
    FAILED DATA(ls_failed)
  REPORTED DATA(ls_reported).
    IF ls_failed IS NOT INITIAL.
      ROLLBACK ENTITIES.
      DATA(lv_msg) = zzcl_comm_tool=>get_bo_msg( is_reported = ls_reported iv_component = 'BILLINGDOCUMENT' ).

      ls_out-msgty = 'E'.
      ls_out-msgtx = |F2发票创建失败：{ lv_msg }|.
      APPEND ls_out TO o_resp-res.
      CONTINUE.

    ELSE.
      COMMIT ENTITIES BEGIN
      RESPONSE OF i_billingdocumenttp
      FAILED FINAL(ls_failed_commit)
      REPORTED FINAL(ls_reported_commit).
      CONVERT KEY OF i_billingdocumenttp FROM lt_result[ 1 ]-%param-%pid TO DATA(ls_billingdocument).
      COMMIT ENTITIES END.
    ENDIF.


    "创建IV2的发票
    CLEAR:lv_flag.
    LOOP AT lt_delivery INTO DATA(ls_delivery).
      IF ls_delivery-salesorganization <> ls_delivery-plant.
        lv_flag = abap_true.
        EXIT.
      ENDIF.
    ENDLOOP.

    IF lv_flag = abap_true.
      CLEAR:lt_create,lv_date,lt_result,ls_failed,ls_reported.
      IF ls_tmp-defaultbillingdocumentdate IS INITIAL.
        lv_date = sy-datum.
      ELSE.
        lv_date = ls_tmp-defaultbillingdocumentdate.
      ENDIF.

      APPEND INITIAL LINE TO lt_create ASSIGNING <fs_create>.
      <fs_create>-%param-%control = VALUE #( _reference = if_abap_behv=>mk-on
                                             _control = if_abap_behv=>mk-on ).

      <fs_create>-%param-_control = VALUE #( defaultbillingdocumentdate = lv_date
                                             defaultbillingdocumenttype = 'IV2'
                                             %control = VALUE #( defaultbillingdocumentdate = if_abap_behv=>mk-on
                                                                 defaultbillingdocumenttype = if_abap_behv=>mk-on  ) ).
      <fs_create>-%param-_reference = VALUE #( BASE <fs_create>-%param-_reference
                                             ( sddocument = lv_document
                                               %control = VALUE #( sddocument = if_abap_behv=>mk-on ) ) ).

      MODIFY ENTITIES OF i_billingdocumenttp PRIVILEGED
      ENTITY billingdocument
     EXECUTE createfromsddocument AUTO FILL CID WITH lt_create
      RESULT lt_result
      FAILED ls_failed
    REPORTED ls_reported.
      IF ls_failed IS NOT INITIAL.
        ROLLBACK ENTITIES.
        lv_msg = zzcl_comm_tool=>get_bo_msg( is_reported = ls_reported iv_component = 'BILLINGDOCUMENT' ).
        ls_out-msgty = 'E'.
        ls_out-msgtx = |IV2发票创建失败：{ lv_msg }|.
        APPEND ls_out TO o_resp-res.
        CONTINUE.

      ELSE.
        COMMIT ENTITIES BEGIN
        RESPONSE OF i_billingdocumenttp
        FAILED FINAL(ls_failed_commit2)
        REPORTED FINAL(ls_reported_commit2).
        CONVERT KEY OF i_billingdocumenttp FROM lt_result[ 1 ]-%param-%pid TO ls_billingdocument.
        COMMIT ENTITIES END.
      ENDIF.
    ENDIF.

    IF ls_out-msgty IS INITIAL.
      ls_out-msgty = 'S'.
      ls_out-msgtx = 'SUCCESS'.
      APPEND ls_out TO o_resp-res.
    ENDIF.

  ENDLOOP.

*  DATA:lv_defaultbillingdocumentdate TYPE dats,
*       lv_delivery_document          TYPE vbeln_vl,
*       lt_create                     TYPE TABLE FOR ACTION IMPORT i_billingdocumenttp~createfromsddocument.
*  IF defaultbillingdocumentdate IS INITIAL.
*    lv_defaultbillingdocumentdate = sy-datum.
*  ELSE.
*    lv_defaultbillingdocumentdate = defaultbillingdocumentdate.
*  ENDIF.
*  APPEND INITIAL LINE TO lt_create ASSIGNING FIELD-SYMBOL(<fs_create>).
*  <fs_create>-%param-%control = VALUE #( _reference = if_abap_behv=>mk-on
*                                         _control = if_abap_behv=>mk-on ).
*  LOOP AT lt_req INTO DATA(ls_req).
*    CLEAR:lv_delivery_document.
*    lv_delivery_document = ls_req-delivery_document.
*    lv_delivery_document = |{ lv_delivery_document ALPHA = IN }|.
*    <fs_create>-%param-_control = VALUE #( defaultbillingdocumentdate = lv_defaultbillingdocumentdate %control = VALUE #( defaultbillingdocumentdate = if_abap_behv=>mk-on ) ).
*    <fs_create>-%param-_reference = VALUE #( BASE <fs_create>-%param-_reference
*                                             ( sddocument = lv_delivery_document %control = VALUE #( sddocument = if_abap_behv=>mk-on ) ) ).
*  ENDLOOP.
*
*  MODIFY ENTITIES OF i_billingdocumenttp PRIVILEGED
*   ENTITY billingdocument
*   EXECUTE createfromsddocument AUTO FILL CID
*   WITH lt_create
*   RESULT DATA(lt_result)
*   FAILED DATA(ls_failed)
*   REPORTED DATA(ls_reported).
*  MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO FINAL(mtext).
*  IF ls_failed IS NOT INITIAL.
*    ROLLBACK ENTITIES.
*    flag = 'E'.
*    me->deal_0001_get_msg( EXPORTING ls_failed = ls_failed
*                                    ls_reported = ls_reported
*                                    lv_component = 'BILLINGDOCUMENT'
*                          IMPORTING msg = msg     ).
*    msg = |{ msg }'/'{ mtext }|.
*    msg = |交货单{ lv_delivery_document }预制发票创建失败:{ msg }|.
*    RETURN.
*  ELSE.
*    COMMIT ENTITIES BEGIN
*    RESPONSE OF i_billingdocumenttp
*    FAILED FINAL(ls_failed_commit)
*    REPORTED FINAL(ls_reported_commit).
*    CONVERT KEY OF i_billingdocumenttp FROM lt_result[ 1 ]-%param-%pid TO DATA(ls_billingdocument).
*    COMMIT ENTITIES END.
*    IF sy-subrc NE 0.
*      flag = 'E'.
*      msg = |创建发票数据库提交失败，请联系管理员|.
*      RETURN.
*    ELSE.
*      flag = 'S'.
*      msg = ls_billingdocument-billingdocument.
*    ENDIF.
*  ENDIF.



ENDFUNCTION.
