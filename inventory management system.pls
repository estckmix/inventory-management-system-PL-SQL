-- Create the schema for managing inventory.
-- Products table will store product details and stock levels.
CREATE TABLE Products (
    ProductID NUMBER PRIMARY KEY,         -- Unique identifier for each product.
    ProductName VARCHAR2(100),            -- Name of the product.
    StockQuantity NUMBER,                 -- Current stock level.
    Price NUMBER                          -- Price of the product.
);

-- Table for tracking orders processed.
CREATE TABLE Orders (
    OrderID NUMBER PRIMARY KEY,           -- Unique identifier for each order.
    ProductID NUMBER REFERENCES Products(ProductID), -- Foreign key linking to Products table.
    Quantity NUMBER,                      -- Quantity of the product ordered.
    OrderDate DATE DEFAULT SYSDATE        -- Date of the order.
);

-- Package to encapsulate inventory management operations.
CREATE OR REPLACE PACKAGE InventoryManagement AS
    PROCEDURE AddProduct(p_ProductID NUMBER, p_ProductName VARCHAR2, p_StockQuantity NUMBER, p_Price NUMBER);
    PROCEDURE UpdateStock(p_ProductID NUMBER, p_Quantity NUMBER);
    PROCEDURE ProcessOrder(p_OrderID NUMBER, p_ProductID NUMBER, p_Quantity NUMBER);
    PROCEDURE GenerateInventoryReport;
END InventoryManagement;
/

-- Package body with the implementation of procedures.
CREATE OR REPLACE PACKAGE BODY InventoryManagement AS

    -- Procedure to add a new product to the inventory.
    PROCEDURE AddProduct(p_ProductID NUMBER, p_ProductName VARCHAR2, p_StockQuantity NUMBER, p_Price NUMBER) IS
    BEGIN
        INSERT INTO Products (ProductID, ProductName, StockQuantity, Price)
        VALUES (p_ProductID, p_ProductName, p_StockQuantity, p_Price);
        DBMS_OUTPUT.PUT_LINE('Product added successfully.');
    END AddProduct;

    -- Procedure to update stock quantities for an existing product.
    PROCEDURE UpdateStock(p_ProductID NUMBER, p_Quantity NUMBER) IS
    BEGIN
        UPDATE Products
        SET StockQuantity = StockQuantity + p_Quantity
        WHERE ProductID = p_ProductID;

        IF SQL%ROWCOUNT = 0 THEN
            DBMS_OUTPUT.PUT_LINE('Product not found.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Stock updated successfully.');
        END IF;
    END UpdateStock;

    -- Procedure to process an order by reducing stock and recording the order.
    PROCEDURE ProcessOrder(p_OrderID NUMBER, p_ProductID NUMBER, p_Quantity NUMBER) IS
        v_CurrentStock NUMBER;
    BEGIN
        -- Check the current stock level.
        SELECT StockQuantity INTO v_CurrentStock
        FROM Products
        WHERE ProductID = p_ProductID;

        IF v_CurrentStock >= p_Quantity THEN
            -- Deduct the ordered quantity from stock.
            UPDATE Products
            SET StockQuantity = StockQuantity - p_Quantity
            WHERE ProductID = p_ProductID;

            -- Record the order in the Orders table.
            INSERT INTO Orders (OrderID, ProductID, Quantity, OrderDate)
            VALUES (p_OrderID, p_ProductID, p_Quantity, SYSDATE);

            DBMS_OUTPUT.PUT_LINE('Order processed successfully.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Insufficient stock to process the order.');
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('Product not found.');
    END ProcessOrder;

    -- Procedure to generate a report of all products and their stock levels.
    PROCEDURE GenerateInventoryReport IS
        CURSOR inventory_cursor IS
            SELECT ProductID, ProductName, StockQuantity, Price
            FROM Products;

        v_ProductID Products.ProductID%TYPE;
        v_ProductName Products.ProductName%TYPE;
        v_StockQuantity Products.StockQuantity%TYPE;
        v_Price Products.Price%TYPE;
    BEGIN
        DBMS_OUTPUT.PUT_LINE('Inventory Report:');
        DBMS_OUTPUT.PUT_LINE('---------------------------');
        DBMS_OUTPUT.PUT_LINE('ID | Name | Stock | Price');
        
        OPEN inventory_cursor;
        LOOP
            FETCH inventory_cursor INTO v_ProductID, v_ProductName, v_StockQuantity, v_Price;
            EXIT WHEN inventory_cursor%NOTFOUND;

            -- Display product details in the report.
            DBMS_OUTPUT.PUT_LINE(v_ProductID || ' | ' || v_ProductName || ' | ' || v_StockQuantity || ' | ' || v_Price);
        END LOOP;
        CLOSE inventory_cursor;

        DBMS_OUTPUT.PUT_LINE('---------------------------');
    END GenerateInventoryReport;

END InventoryManagement;
/

-- Test the system by running the package's procedures.

-- Add a few products to the inventory.
BEGIN
    InventoryManagement.AddProduct(1, 'Product A', 100, 10.5);
    InventoryManagement.AddProduct(2, 'Product B', 50, 15.0);
    InventoryManagement.AddProduct(3, 'Product C', 200, 5.0);
END;
/

-- Update stock for a product.
BEGIN
    InventoryManagement.UpdateStock(1, 50); -- Add 50 units to Product A.
END;
/

-- Process an order for a product.
BEGIN
    InventoryManagement.ProcessOrder(101, 1, 30); -- Order 30 units of Product A.
END;
/

-- Generate an inventory report.
BEGIN
    InventoryManagement.GenerateInventoryReport;
END;
/
