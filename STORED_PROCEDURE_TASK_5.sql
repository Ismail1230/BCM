CREATE OR REPLACE PROCEDURE GET_REPORT_SECOND_HIGHEST
AS
    CURSOR report_cursor_highest IS
        SELECT 
            IQ.ORDER_REF_NUM AS ORDER_REFERENCE,
            IQ.ORDER_PERIOD AS ORDER_DATE,
            IQ.SUPPLIER_NAME,
            IQ.ORDER_TOTAL_AMOUNT,
            IQ.ORDER_STATUS,
            (SELECT LISTAGG(DISTINCT I.INVOICE_REF, '|') WITHIN GROUP (ORDER BY I.INVOICE_REF) 
             FROM INVOICES_NUMBER I 
             WHERE I.ORDER_ID IN (
                 SELECT OL.ORDER_ID 
                 FROM ORDER_LINE OL 
                 WHERE OL.ORDER_PARENT_REF = IQ.ORDER_REF
             )
            ) AS INVOICE_REFERENCES
        FROM (
            SELECT 
                TO_NUMBER(SUBSTR(OM.ORDER_REF, 3)) AS ORDER_REF_NUM,
                OM.ORDER_REF,  
                TO_CHAR(TO_DATE(OM.ORDER_DATE, 'DD-MM-YYYY'), 'FMMonth DD, YYYY') AS ORDER_PERIOD,
                UPPER(S.SUPPLIER_NAME) AS SUPPLIER_NAME,
                TO_CHAR(SUM(OM.ORDER_TOTAL_AMOUNT), '999,999,999.00') AS ORDER_TOTAL_AMOUNT,
                OM.ORDER_STATUS,
                I.INVOICE_REF, 
                TO_CHAR(SUM(I.INVOICE_AMOUNT), '999,999,999.00') AS TOTAL_INVOICE_AMOUNT,
                RANK() OVER (ORDER BY SUM(OM.ORDER_TOTAL_AMOUNT) DESC) AS rank
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
                OM.ORDER_REF,  
                OM.ORDER_DATE,
                S.SUPPLIER_NAME,
                OM.ORDER_STATUS,
                I.INVOICE_REF 
        ) IQ
        WHERE IQ.rank = 2
        GROUP BY IQ.ORDER_REF_NUM, IQ.ORDER_PERIOD, IQ.SUPPLIER_NAME, IQ.ORDER_TOTAL_AMOUNT, IQ.ORDER_STATUS, IQ.ORDER_REF;

BEGIN
    FOR report_record IN report_cursor_highest LOOP
        
        DBMS_OUTPUT.PUT_LINE('Order Ref: ' || report_record.ORDER_REFERENCE);
        DBMS_OUTPUT.PUT_LINE('Order Date: ' || report_record.ORDER_DATE);
        DBMS_OUTPUT.PUT_LINE('Supplier: ' || report_record.SUPPLIER_NAME);
        DBMS_OUTPUT.PUT_LINE('Order Total: ' || report_record.ORDER_TOTAL_AMOUNT);
        DBMS_OUTPUT.PUT_LINE('Order Status: ' || report_record.ORDER_STATUS);
        DBMS_OUTPUT.PUT_LINE('Invoice References: ' || report_record.INVOICE_REFERENCES);
    END LOOP;
END;
/