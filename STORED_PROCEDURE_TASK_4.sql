CREATE OR REPLACE PROCEDURE GET_REPORT
AS
    CURSOR report_cursor IS
        SELECT 
            TO_NUMBER(SUBSTR(OM.ORDER_REF, 3)) AS ORDER_REF_NUM,
            TO_CHAR(TO_DATE(OM.ORDER_DATE, 'DD-MM-YYYY'), 'MM-YYYY') AS ORDER_PERIOD,
            INITCAP(S.SUPPLIER_NAME) AS SUPPLIER_NAME,
            TO_CHAR(SUM(OM.ORDER_TOTAL_AMOUNT), '999,999,999.00') AS ORDER_TOTAL_AMOUNT,
            OM.ORDER_STATUS,
            SUBSTR(I.INVOICE_REF, 1, 9) AS INVOICE_REFERENCE,
            TO_CHAR(SUM(I.INVOICE_AMOUNT), '999,999,999.00') AS TOTAL_INVOICE_AMOUNT,
            MIN(
                CASE 
                    WHEN EXISTS (SELECT 1 FROM INVOICES_NUMBER x
                                 WHERE x.ORDER_PARENT_REF LIKE '%' || OM.ORDER_REF || '%'
                                 AND x.INVOICE_STATUS = 'Pending') 
                    THEN 'To follow up'
                    WHEN EXISTS (SELECT 1 FROM INVOICES_NUMBER x 
                                 WHERE x.ORDER_PARENT_REF LIKE '%' || OM.ORDER_REF || '%'
                                 AND (x.INVOICE_STATUS IS NULL OR x.INVOICE_STATUS = '')) 
                    THEN 'To verify'
                    ELSE 'OK'
                END
            ) AS ACTION
        FROM 
            ORDER_MAIN OM
        JOIN 
            SUPPLIER S ON OM.SUPPLIER_ID = S.SUPPLIER_ID
        JOIN 
            ORDER_LINE OL ON OM.ORDER_REF = OL.ORDER_PARENT_REF 
        JOIN 
            INVOICES_NUMBER I ON OL.ORDER_ID = I.ORDER_ID 
        WHERE 
            I.INVOICE_REF IS NOT NULL
        GROUP BY 
            TO_NUMBER(SUBSTR(OM.ORDER_REF, 3)),
            TO_CHAR(TO_DATE(OM.ORDER_DATE, 'DD-MM-YYYY'), 'MM-YYYY'),
            INITCAP(S.SUPPLIER_NAME),
            OM.ORDER_STATUS,
            SUBSTR(I.INVOICE_REF, 1, 9);

BEGIN
    FOR report_record IN report_cursor LOOP
        
        DBMS_OUTPUT.PUT_LINE('Order Ref: ' || report_record.ORDER_REF_NUM || 
                             ', Supplier: ' || report_record.SUPPLIER_NAME || 
                             ', Order Total: ' || report_record.ORDER_TOTAL_AMOUNT ||
                             ', Action: ' || report_record.ACTION);
    END LOOP;
END;
/