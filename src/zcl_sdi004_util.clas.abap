CLASS zcl_sdi004_util DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    METHODS check_0001
      IMPORTING lt_req TYPE zzt_sdi004_0001_item_in
      EXPORTING flag   TYPE bapi_mtype
                msg    TYPE bapi_msg.
    METHODS deal_0001
      IMPORTING defaultbillingdocumentdate TYPE string OPTIONAL
      EXPORTING flag   TYPE bapi_mtype
                msg    TYPE bapi_msg
      CHANGING  lt_req TYPE zzt_sdi004_0001_item_in.
                .
    METHODS deal_0001_fl
      EXPORTING flag   TYPE bapi_mtype
                msg    TYPE bapi_msg
      CHANGING  ls_req TYPE zzs_sdi004_0001_item_in.
    METHODS deal_0001_fp
      IMPORTING defaultbillingdocumentdate TYPE string OPTIONAL
      EXPORTING flag                       TYPE bapi_mtype
                msg                        TYPE bapi_msg
      CHANGING  lt_req                     TYPE zzt_sdi004_0001_item_in.
    METHODS deal_0001_get_msg
      IMPORTING ls_failed    TYPE any
                ls_reported  TYPE any
                lv_component TYPE string
      EXPORTING msg          TYPE bapi_msg.
PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_SDI004_UTIL IMPLEMENTATION.


  METHOD check_0001.
    LOOP AT lt_req INTO DATA(ls_req).
      IF ls_req IS INITIAL.
        flag = 'E'.
        msg = |传入项目为空| .
        EXIT.
      ENDIF.

      "1.检查抬头
      IF ls_req-delivery_document IS INITIAL.
        flag = 'E'.
        msg = |第{ sy-tabix }【SAP交货单号】不能为空|.
        EXIT.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD deal_0001.
    DATA:lv_rebates TYPE i_salesorderpricingelementtp-conditionrateamount.
    "1.如果传入返利金额不为空，则先修改销售订单返利
    LOOP AT lt_req INTO DATA(ls_req).
      CONDENSE ls_req-condition_rate_value_rebates NO-GAPS.
      lv_rebates = lv_rebates + ls_req-condition_rate_value_rebates.
    ENDLOOP.
    DATA(ls_req_fl) = ls_req.
    ls_req_fl-condition_rate_value_rebates = lv_rebates.
    CONDENSE ls_req_fl-condition_rate_value_rebates NO-GAPS.
    IF lv_rebates IS NOT INITIAL AND lv_rebates NE 0.
      me->deal_0001_fl( IMPORTING flag = flag
                                   msg  = msg
                        CHANGING  ls_req = ls_req_fl ).
      IF flag = 'E'.
        RETURN.
      ENDIF.
    ENDIF.
    "2.创建预制发票并过账
    me->deal_0001_fp( EXPORTING defaultbillingdocumentdate = defaultbillingdocumentdate
                      IMPORTING flag = flag
                                msg  = msg
                      CHANGING  lt_req = lt_req ).
  ENDMETHOD.


  METHOD deal_0001_fl.
    DATA:lv_delivery_document   TYPE vbeln_vl,
         ls_sales_order_pricing TYPE i_salesorderpricingelementtp.
    FIELD-SYMBOLS:<fs_salesorder_tab> TYPE STANDARD TABLE,
                  <fs_salesorder>     TYPE any,
                  <fs_msg>            TYPE REF TO if_abap_behv_message,
                  <fs_t100key>        TYPE any.
    ls_sales_order_pricing-conditionrateamount = ls_req-condition_rate_value_rebates.
    lv_delivery_document = ls_req-delivery_document.
    lv_delivery_document = |{ lv_delivery_document ALPHA = IN }|.

    SELECT SINGLE referencesddocument
         FROM i_deliverydocumentitem WITH PRIVILEGED ACCESS
        WHERE deliverydocument = @lv_delivery_document
          INTO @DATA(lv_sales_order).
    IF sy-subrc NE 0.
      flag = 'E'.
      msg = |交货单{ lv_delivery_document }不存在|.
      RETURN.
    ENDIF.

    SELECT SINGLE *
          FROM i_salesorderpricingelementtp WITH PRIVILEGED ACCESS
         WHERE salesorder = @lv_sales_order
           AND conditiontype = 'ZD10'
           INTO @DATA(ls_price).
    IF sy-subrc NE 0.
      "新增返利

    ELSE.
      "返利修改,先删除原返利，再新插入
      MODIFY ENTITIES OF i_salesordertp PRIVILEGED
       ENTITY salesorderpricingelement
       DELETE FROM VALUE #( ( %key-salesorder = lv_sales_order
       %key-pricingprocedurestep = ls_price-pricingprocedurestep
       %key-pricingprocedurecounter = ls_price-pricingprocedurecounter ) )
       FAILED DATA(ls_failed)
       REPORTED DATA(ls_reported).
      MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO FINAL(mtext1).
      IF ls_failed IS NOT INITIAL.
        flag = 'E'.
        me->deal_0001_get_msg( EXPORTING ls_failed = ls_failed
                                        ls_reported = ls_reported
                                        lv_component = 'SALESORDERPRICINGELEMENT'
                              IMPORTING msg = msg     ).
        IF msg IS INITIAL.
          me->deal_0001_get_msg( EXPORTING ls_failed = ls_failed
                                           ls_reported = ls_reported
                                           lv_component = 'SALESORDER'
                                 IMPORTING msg = msg     ).
        ENDIF.
        msg = |{ msg }'/'{ mtext1 }|.
        msg = |订单{ lv_sales_order }项目抬头【返利金额】设置失败:{ msg }|.
        RETURN.
      ENDIF.
    ENDIF.

    MODIFY ENTITIES OF i_salesordertp PRIVILEGED
           ENTITY salesorder
           CREATE BY \_pricingelement
           FIELDS ( conditiontype
           conditionrateamount  )
           WITH VALUE #( (
           salesorder = lv_sales_order
           %target = VALUE #( ( %cid = 'IP001'
           conditiontype = 'ZD10'
           conditionrateamount = ls_sales_order_pricing-conditionrateamount ) ) ) )
           FAILED DATA(ls_failed_item_new)
           REPORTED DATA(ls_reported_item_new).
    MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO FINAL(mtext).
    IF ls_failed_item_new IS NOT INITIAL.
      ROLLBACK ENTITIES.
      flag = 'E'.
      me->deal_0001_get_msg( EXPORTING ls_failed = ls_failed_item_new
                                      ls_reported = ls_reported_item_new
                                      lv_component = 'SALESORDERPRICINGELEMENT'
                            IMPORTING msg = msg     ).
      IF msg IS INITIAL.
        me->deal_0001_get_msg( EXPORTING ls_failed = ls_failed_item_new
                                         ls_reported = ls_reported_item_new
                                         lv_component = 'SALESORDER'
                               IMPORTING msg = msg     ).
      ENDIF.
      msg = |{ msg }'/'{ mtext }|.
      msg = |订单{ lv_sales_order }项目抬头【返利金额】设置失败:{ msg }|.
      RETURN.
    ELSE.
      COMMIT ENTITIES
      RESPONSES
      FAILED FINAL(ls_failed_commit)
      REPORTED FINAL(ls_reported_commit).
      IF sy-subrc NE 0.
        flag = 'E'.
        msg = |修改返利数据库提交失败，请联系管理员|.
        RETURN.
      ENDIF.
    ENDIF.
  ENDMETHOD.


  METHOD deal_0001_fp.
    DATA:lv_defaultbillingdocumentdate type dats,
         lv_delivery_document TYPE vbeln_vl,
         lt_create            TYPE TABLE FOR ACTION IMPORT i_billingdocumenttp~createfromsddocument.
    if defaultbillingdocumentdate is initial.
      lv_defaultbillingdocumentdate = sy-datum.
    else.
      lv_defaultbillingdocumentdate = defaultbillingdocumentdate.
    endif.
    APPEND INITIAL LINE TO lt_create ASSIGNING FIELD-SYMBOL(<fs_create>).
    <fs_create>-%param-%control = VALUE #( _reference = if_abap_behv=>mk-on
                                           _control = if_abap_behv=>mk-on ).
    LOOP AT lt_req INTO DATA(ls_req).
      CLEAR:lv_delivery_document.
      lv_delivery_document = ls_req-delivery_document.
      lv_delivery_document = |{ lv_delivery_document ALPHA = IN }|.
      <fs_create>-%param-_control = VALUE #( defaultbillingdocumentdate = lv_defaultbillingdocumentdate %control = VALUE #( defaultbillingdocumentdate = if_abap_behv=>mk-on ) ).
      <fs_create>-%param-_reference = VALUE #( BASE <fs_create>-%param-_reference
                                               ( sddocument = lv_delivery_document %control = VALUE #( sddocument = if_abap_behv=>mk-on ) ) ).
    ENDLOOP.

    MODIFY ENTITIES OF i_billingdocumenttp PRIVILEGED
     ENTITY billingdocument
     EXECUTE createfromsddocument AUTO FILL CID
     WITH lt_create
     RESULT DATA(lt_result)
     FAILED DATA(ls_failed)
     REPORTED DATA(ls_reported).
    MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO FINAL(mtext).
    IF ls_failed IS NOT INITIAL.
      ROLLBACK ENTITIES.
      flag = 'E'.
      me->deal_0001_get_msg( EXPORTING ls_failed = ls_failed
                                      ls_reported = ls_reported
                                      lv_component = 'BILLINGDOCUMENT'
                            IMPORTING msg = msg     ).
      msg = |{ msg }'/'{ mtext }|.
      msg = |交货单{ lv_delivery_document }预制发票创建失败:{ msg }|.
      RETURN.
    ELSE.
      COMMIT ENTITIES BEGIN
      RESPONSE OF i_billingdocumenttp
      FAILED FINAL(ls_failed_commit)
      REPORTED FINAL(ls_reported_commit).
      CONVERT KEY OF i_billingdocumenttp FROM lt_result[ 1 ]-%param-%pid TO DATA(ls_billingdocument).
      COMMIT ENTITIES END.
      IF sy-subrc NE 0.
        flag = 'E'.
        msg = |创建发票数据库提交失败，请联系管理员|.
        RETURN.
      ELSE.
        flag = 'S'.
        msg = ls_billingdocument-billingdocument.
      ENDIF.
    ENDIF.
  ENDMETHOD.


  METHOD  deal_0001_get_msg.
    DATA:lv_msg     TYPE bapi_msg,
         ls_t100key TYPE scx_t100key,
         lv_msgid   TYPE symsgid,
         lv_msgno   TYPE symsgno,
         lv_msgv1   LIKE sy-msgv1,
         lv_msgv2   LIKE sy-msgv2,
         lv_msgv3   LIKE sy-msgv3,
         lv_msgv4   LIKE sy-msgv4.

    FIELD-SYMBOLS:<fs_salesorder_tab> TYPE STANDARD TABLE,
                  <fs_salesorder>     TYPE any,
                  <fs_msg>            TYPE REF TO if_abap_behv_message,
                  <fs_t100key>        TYPE any.

    ASSIGN COMPONENT lv_component OF STRUCTURE ls_reported TO <fs_salesorder_tab>.
    IF <fs_salesorder_tab> IS ASSIGNED AND <fs_salesorder_tab> IS NOT INITIAL.

      LOOP AT <fs_salesorder_tab> ASSIGNING <fs_salesorder>.
        CLEAR:lv_msgid,lv_msgno,lv_msgv1,lv_msgv2,lv_msgv3,lv_msgv3.
        ASSIGN COMPONENT '%MSG' OF STRUCTURE <fs_salesorder> TO <fs_msg>.
        IF <fs_msg> IS ASSIGNED AND <fs_msg> IS NOT INITIAL.
          ASSIGN <fs_msg>->('IF_T100_MESSAGE~T100KEY') TO <fs_t100key>.
          IF <fs_t100key> IS ASSIGNED AND <fs_t100key> IS NOT INITIAL.
            ASSIGN COMPONENT 'MSGID' OF STRUCTURE <fs_t100key> TO FIELD-SYMBOL(<fs_msgid>).
            ASSIGN COMPONENT 'MSGNO' OF STRUCTURE <fs_t100key> TO FIELD-SYMBOL(<fs_msgno>).
          ENDIF.
          ASSIGN <fs_msg>->('IF_T100_DYN_MSG~MSGV1') TO FIELD-SYMBOL(<fs_msgv1>).
          ASSIGN <fs_msg>->('IF_T100_DYN_MSG~MSGV2') TO FIELD-SYMBOL(<fs_msgv2>).
          ASSIGN <fs_msg>->('IF_T100_DYN_MSG~MSGV3') TO FIELD-SYMBOL(<fs_msgv3>).
          ASSIGN <fs_msg>->('IF_T100_DYN_MSG~MSGV4') TO FIELD-SYMBOL(<fs_msgv4>).
          IF <fs_msgid> IS ASSIGNED AND <fs_msgid> IS NOT INITIAL.
            lv_msgid = <fs_msgid>.
          ENDIF.
          IF <fs_msgno> IS ASSIGNED AND <fs_msgno> IS NOT INITIAL.
            lv_msgno = <fs_msgno>.
          ENDIF.
          IF <fs_msgv1> IS ASSIGNED AND <fs_msgv1> IS NOT INITIAL.
            lv_msgv1 = <fs_msgv1>.
          ENDIF.
          IF <fs_msgv2> IS ASSIGNED AND <fs_msgv2> IS NOT INITIAL.
            lv_msgv2 = <fs_msgv2>.
          ENDIF.
          IF <fs_msgv3> IS ASSIGNED AND <fs_msgv3> IS NOT INITIAL.
            lv_msgv3 = <fs_msgv3>.
          ENDIF.
          IF <fs_msgv4> IS ASSIGNED AND <fs_msgv4> IS NOT INITIAL.
            lv_msgv4 = <fs_msgv4>.
          ENDIF.
          IF lv_msgid IS NOT INITIAL
            AND lv_msgno IS NOT INITIAL.
            MESSAGE ID lv_msgid TYPE 'S' NUMBER lv_msgno
              INTO FINAL(mtext1)
              WITH lv_msgv1 lv_msgv2 lv_msgv3 lv_msgv4.
            IF msg IS INITIAL.
              msg = mtext1.
            ELSE.
              msg = |{ msg }/{ mtext1 }|.
            ENDIF.
          ENDIF.
          UNASSIGN:<fs_msgid>,<fs_msgno>,<fs_msgv1>,<fs_msgv2>,<fs_msgv3>,<fs_msgv4>.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
