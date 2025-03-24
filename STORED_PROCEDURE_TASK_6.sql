CREATE OR REPLACE PROCEDURE GET_REPORT_SUPPLIERS
AS
    CURSOR report_cursor_supplier IS
        SELECT 
            S.SUPPLIER_NAME, 
            S.SUPP_CONTACT_NAME, 
            CASE 
                WHEN LENGTH(REGEXP_SUBSTR(S.SUPP_CONTACT_NUMBER, '[0-9]+', 1, 1)) = 7 
                THEN REGEXP_REPLACE(REGEXP_SUBSTR(S.SUPP_CONTACT_NUMBER, '[0-9]+', 1, 1), '(\d{3})(\d{4})', '\1-\2')
                WHEN LENGTH(REGEXP_SUBSTR(S.SUPP_CONTACT_NUMBER, '[0-9]+', 1, 1)) = 8 
                THEN REGEXP_REPLACE(REGEXP_SUBSTR(S.SUPP_CONTACT_NUMBER, '[0-9]+', 1, 1), '(\d{4})(\d{4})', '\1-\2')
                ELSE NULL 
            END AS CONTACT_NO1,
            CASE 
                WHEN LENGTH(REGEXP_SUBSTR(S.SUPP_CONTACT_NUMBER, '[0-9]+', 1, 2)) = 7 
                THEN REGEXP_REPLACE(REGEXP_SUBSTR(S.SUPP_CONTACT_NUMBER, '[0-9]+', 1, 2), '(\d{3})(\d{4})', '\1-\2')
                WHEN LENGTH(REGEXP_SUBSTR(S.SUPP_CONTACT_NUMBER, '[0-9]+', 1, 2)) = 8 
                THEN REGEXP_REPLACE(REGEXP_SUBSTR(S.SUPP_CONTACT_NUMBER, '[0-9]+', 1, 2), '(\d{4})(\d{4})', '\1-\2')
                ELSE ' - ' 
            END AS CONTACT_NO2,
            COUNT(OM.ORDER_REF) AS TOTAL_ORDERS,
            TO_CHAR(SUM(OL.ORDER_LINE_AMOUNT), '99,999,990.00') AS ORDER_TOTAL_AMOUNT
        FROM SUPPLIER S
        JOIN ORDER_MAIN OM 
            ON OM.SUPPLIER_ID = S.SUPPLIER_ID
        JOIN ORDER_LINE OL 
            ON OL.ORDER_PARENT_REF = OM.ORDER_REF
        WHERE TO_DATE(OM.ORDER_DATE, 'DD-MM-YYYY') 
              BETWEEN TO_DATE('01-01-2022', 'DD-MM-YYYY') 
              AND TO_DATE('31-08-2022', 'DD-MM-YYYY')
        GROUP BY 
            S.SUPPLIER_NAME, 
            S.SUPP_CONTACT_NAME,
            S.SUPP_CONTACT_NUMBER
        ORDER BY ORDER_TOTAL_AMOUNT DESC;

BEGIN
    FOR report_record IN report_cursor_supplier LOOP
    
        DBMS_OUTPUT.PUT_LINE('Order Ref: ' || report_record.SUPPLIER_NAME || 
                             ', Supplier: ' || report_record.SUPPLIER_NAME || 
                             ', Contact Name: ' || report_record.SUPP_CONTACT_NAME || 
                             ', Contact No 1: ' || report_record.CONTACT_NO1 || 
                             ', Contact No 2: ' || report_record.CONTACT_NO2 || 
                             ', Total Orders: ' || report_record.TOTAL_ORDERS || 
                             ', Order Total: ' || report_record.ORDER_TOTAL_AMOUNT);
    END LOOP;
END;
/
