USE AdventureWorks2022;

/*
Create a procedure InsertOrderDetails that takes OrderID, ProductID, 
UnitPrice, Quantiy, Discount as input parameters and inserts that order 
information in the Order Details table. After each order inserted, check the 
@@rowcount value to make sure that order was inserted properly. If for any 
reason the order was not inserted, print the message: Failed to place the 
order. Please try again. Also your procedure should have these 
functionalities Make the UnitPrice and Discount parameters optional If no 
UnitPrice is given, then use the UnitPrice value from the product table. If 
no Discount is given, then use a discount of 0. Adjust the quantity in stock 
(UnitsInStock) for the product by subtracting the quantity sold from 
inventory. However, if there is not enough of a product in stock, then abort 
the stored procedure without making any changes to the database. Print a 
message if the quantity in stock of a product drops below its Reorder Level 
as a result of the update.
*/

CREATE PROCEDURE InsertOrderDetails
    @OrderID INT,
    @ProductID INT,
    @UnitPrice DECIMAL(10, 2) = NULL,
    @Quantity INT,
    @Discount DECIMAL(10, 2) = 0
AS
BEGIN
    DECLARE @ProductUnitPrice DECIMAL(10, 2);
    DECLARE @UnitsInStock INT;
    DECLARE @ReorderLevel INT;
    
    -- Get the product details
    SELECT 
        @ProductUnitPrice = ListPrice,
        @UnitsInStock = Quantity,
        @ReorderLevel = SafetyStockLevel
    FROM Production.ProductInventory
    JOIN Production.Product ON Production.Product.ProductID = Production.ProductInventory.ProductID
    WHERE Production.Product.ProductID = @ProductID;
    
    -- Use the product price if UnitPrice is not provided
    IF @UnitPrice IS NULL
    BEGIN
        SET @UnitPrice = @ProductUnitPrice;
    END
    
    -- Check if there is enough stock
    IF @UnitsInStock < @Quantity
    BEGIN
        PRINT 'Not enough stock available. Aborting the transaction.';
        RETURN;
    END
    
    BEGIN TRY
        -- Start a transaction
        BEGIN TRANSACTION;
        
        -- Insert the order details
        INSERT INTO Sales.SalesOrderDetail (SalesOrderID, ProductID, UnitPrice, OrderQty, UnitPriceDiscount)
        VALUES (@OrderID, @ProductID, @UnitPrice, @Quantity, @Discount);
        
        -- Check if the insertion was successful
        IF @@ROWCOUNT = 0
        BEGIN
            PRINT 'Failed to place the order. Please try again.';
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        -- Update the stock quantity
        UPDATE Production.ProductInventory
        SET Quantity = Quantity - @Quantity
        WHERE ProductID = @ProductID;
        
        -- Check if the stock drops below reorder level
        IF (SELECT Quantity FROM Production.ProductInventory WHERE ProductID = @ProductID) < @ReorderLevel
        BEGIN
            PRINT 'Warning: The quantity in stock of this product has dropped below its reorder level.';
        END
        
        -- Commit the transaction
        COMMIT TRANSACTION;
        
        PRINT 'Order placed successfully.';
        
    END TRY
    BEGIN CATCH
        -- Rollback the transaction in case of an error
        ROLLBACK TRANSACTION;
        PRINT 'An error occurred. The transaction has been rolled back.';
    END CATCH
END









/*
Create a procedure UpdateOrderDetails that takes OrderID, ProductID, 
UnitPrice, Quantity, and discount, and updates these values for that 
ProductID in that Order. All the parameters except the OrderID and ProductID 
should be optional so that if the user wants to only update Quantity s/he 
should be able to do so without providing the rest of the values. You need 
to also make sure that if any of the values are being passed in as NULL, 
then you want to retain the original value instead of overwriting it with 
NULL. To accomplish this, look for the ISNULL() function in google or sql 
server books online. Adjust the UnitsInStock value in products table 
accordingly.
*/

CREATE PROCEDURE UpdateOrderDetails2
    @OrderID INT,
    @ProductID INT,
    @UnitPrice DECIMAL(10, 2) = NULL,
    @Quantity INT = NULL,
    @Discount DECIMAL(10, 2) = NULL
AS
BEGIN
    DECLARE @CurrentUnitPrice DECIMAL(10, 2);
    DECLARE @CurrentQuantity INT;
    DECLARE @CurrentDiscount DECIMAL(10, 2);
    DECLARE @UnitsInStock INT;
    DECLARE @OriginalQuantity INT;
    
    -- Get current order details
    SELECT 
        @CurrentUnitPrice = UnitPrice,
        @CurrentQuantity = OrderQty,
        @CurrentDiscount = UnitPriceDiscount
    FROM Sales.SalesOrderDetail
    WHERE SalesOrderID = @OrderID AND ProductID = @ProductID;
    
    -- Get current product inventory
    SELECT @UnitsInStock = QuantityOnHand
    FROM Production.ProductInventory
    WHERE ProductID = @ProductID;

    -- Check if the original quantity is retrieved properly
    IF @CurrentQuantity IS NULL
    BEGIN
        PRINT 'Order details not found for the provided OrderID and ProductID.';
        RETURN;
    END

    -- Retain original values if parameters are not provided
    SET @UnitPrice = ISNULL(@UnitPrice, @CurrentUnitPrice);
    SET @Quantity = ISNULL(@Quantity, @CurrentQuantity);
    SET @Discount = ISNULL(@Discount, @CurrentDiscount);

    -- Adjust the quantity in stock
    SET @OriginalQuantity = @CurrentQuantity;
    SET @UnitsInStock = @UnitsInStock + @OriginalQuantity - @Quantity;

    -- Check if there is enough stock available for the update
    IF @UnitsInStock < 0
    BEGIN
        PRINT 'Not enough stock available. Aborting the transaction.';
        RETURN;
    END

    BEGIN TRY
        -- Start a transaction
        BEGIN TRANSACTION;

        -- Update the order details
        UPDATE Sales.SalesOrderDetail
        SET UnitPrice = @UnitPrice,
            OrderQty = @Quantity,
            UnitPriceDiscount = @Discount
        WHERE SalesOrderID = @OrderID AND ProductID = @ProductID;

        -- Check if the update was successful
        IF @@ROWCOUNT = 0
        BEGIN
            PRINT 'Failed to update the order. Please try again.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Update the stock quantity
        UPDATE Production.ProductInventory
        SET QuantityOnHand = @UnitsInStock
        WHERE ProductID = @ProductID;

        -- Check if the stock drops below reorder level
        IF (SELECT QuantityOnHand FROM Production.ProductInventory WHERE ProductID = @ProductID) < (SELECT SafetyStockLevel FROM Production.Product WHERE ProductID = @ProductID)
        BEGIN
            PRINT 'Warning: The quantity in stock of this product has dropped below its reorder level.';
        END

        -- Commit the transaction
        COMMIT TRANSACTION;

        PRINT 'Order updated successfully.';

    END TRY
    BEGIN CATCH
        -- Rollback the transaction in case of an error
        ROLLBACK TRANSACTION;
        PRINT 'An error occurred. The transaction has been rolled back.';
    END CATCH
END









/*
Create a procedure GetOrderDetails that takes OrderID as input parameter and 
returns all the records for that OrderID. If no records are found in Order 
Details table, then it should print the line: "The OrderID XXXX does not 
exits", where XXX should be the OrderID entered by user and the procedure 
should RETURN the value 1.
*/

CREATE PROCEDURE GetOrderDetails
    @OrderID INT
AS
BEGIN
    -- Declare a variable to check if any rows are returned
    DECLARE @RowCount INT;

    -- Select the order details for the given OrderID
    SELECT 
        SalesOrderID,
        ProductID,
        UnitPrice,
        OrderQty,
        UnitPriceDiscount
    FROM Sales.SalesOrderDetail
    WHERE SalesOrderID = @OrderID;

    -- Check if any rows were returned
    SET @RowCount = @@ROWCOUNT;

    -- If no rows were found, print the message and return 1
    IF @RowCount = 0
    BEGIN
        PRINT 'The OrderID ' + CAST(@OrderID AS VARCHAR(10)) + ' does not exist';
        RETURN 1;
    END
END









/*
Create a procedure DeleteOrderDetails that takes OrderID and ProductID and 
deletes that from Order Details table. Your procedure should validate 
parameters. It should return an error code (-1) and print a message if the 
parameters are invalid. Parameters are valid if the given order ID appears 
in the table and if the given product ID appears in that order.
*/

CREATE PROCEDURE DeleteOrderDetails
    @OrderID INT,
    @ProductID INT
AS
BEGIN
    -- Declare a variable to check if any rows are returned
    DECLARE @RowCount INT;

    -- Check if the given OrderID and ProductID exist in the SalesOrderDetail table
    SELECT 
        @RowCount = COUNT(*)
    FROM Sales.SalesOrderDetail
    WHERE SalesOrderID = @OrderID AND ProductID = @ProductID;

    -- If no rows are found, print the message and return -1
    IF @RowCount = 0
    BEGIN
        PRINT 'Invalid parameters: The OrderID ' + CAST(@OrderID AS VARCHAR(10)) + ' and ProductID ' + CAST(@ProductID AS VARCHAR(10)) + ' combination does not exist';
        RETURN -1;
    END

    BEGIN TRY
        -- Start a transaction
        BEGIN TRANSACTION;

        -- Delete the order details
        DELETE FROM Sales.SalesOrderDetail
        WHERE SalesOrderID = @OrderID AND ProductID = @ProductID;

        -- Commit the transaction
        COMMIT TRANSACTION;

        PRINT 'Order details deleted successfully.';

    END TRY
    BEGIN CATCH
        -- Rollback the transaction in case of an error
        ROLLBACK TRANSACTION;
        PRINT 'An error occurred. The transaction has been rolled back.';
        RETURN -1;
    END CATCH
END









--		Functions




/*
Create a function that takes an input parameter type datetime and returns 
the date in the format MM/DD/YYYY. For example if I pass in '2006-11-21 
23:34:05.920', the output of the functions should be 11/21/2006
*/

CREATE FUNCTION dbo.FormatDate (@InputDate DATETIME)
RETURNS VARCHAR(10)
AS
BEGIN
    RETURN FORMAT(@InputDate, 'MM/dd/yyyy');
END


SELECT dbo.FormatDate('2006-11-21 23:34:05.920') AS FormattedDate;









/*
Create a function that takes an input parameter type datetime and returns 
the date in the format YYYYMMDD
*/

CREATE FUNCTION dbo.FormatDateYYYYMMDD (@InputDate DATETIME)
RETURNS CHAR(8)
AS
BEGIN
    RETURN CONVERT(CHAR(8), @InputDate, 112);
END


SELECT dbo.FormatDateYYYYMMDD('2006-11-21 23:34:05.920') AS FormattedDate;









--   	View




/*
Create a view vwCustomerOrders which returns CompanyName, OrderID. 
OrderDate, ProductID. Product Name Quantity UnitPrice. Quantity od. 
UnitPrice
*/

CREATE VIEW vwCustomerOrders AS
SELECT 
    --c.CompanyName,	-- CompanyName column is not present in the table
    c.AccountNumber,
    soh.SalesOrderID AS OrderID,
    soh.OrderDate,
    sod.ProductID,
    p.Name AS ProductName,
    sod.OrderQty AS Quantity,
    sod.UnitPrice,
    sod.OrderQty * sod.UnitPrice AS TotalPrice
FROM 
    Sales.Customer AS c
    INNER JOIN Sales.SalesOrderHeader AS soh ON c.CustomerID = soh.CustomerID
    INNER JOIN Sales.SalesOrderDetail AS sod ON soh.SalesOrderID = sod.SalesOrderID
    INNER JOIN Production.Product AS p ON sod.ProductID = p.ProductID
    
    
SELECT * FROM vwCustomerOrders;









/*
Create a copy of the above view and modify it so that it only returns the 
above information for orders that were placed yesterday
*/

CREATE VIEW vwCustomerOrdersYesterday AS
SELECT 
    --c.CompanyName,	-- CompanyName column is not present in the table
    c.AccountNumber,
    soh.SalesOrderID AS OrderID,
    soh.OrderDate,
    sod.ProductID,
    p.Name AS ProductName,
    sod.OrderQty AS Quantity,
    sod.UnitPrice,
    sod.OrderQty * sod.UnitPrice AS TotalPrice
FROM 
    Sales.Customer AS c
    INNER JOIN Sales.SalesOrderHeader AS soh ON c.CustomerID = soh.CustomerID
    INNER JOIN Sales.SalesOrderDetail AS sod ON soh.SalesOrderID = sod.SalesOrderID
    INNER JOIN Production.Product AS p ON sod.ProductID = p.ProductID
WHERE 
    CAST(soh.OrderDate AS DATE) = CAST(GETDATE() - 1 AS DATE)
    
    
SELECT * FROM vwCustomerOrdersYesterday;









/*
Use a CREATE VIEW statement to create a view called MyProducts. Your view 
should contain the ProductID, ProductName, QuantityPerUnit and UnitPrice 
columns from the Products table. It should also contain the CompanyName 
column from the Suppliers table and the CategoryName column from the 
Categories table. Your view should only contain products that are not 
discontinued.
*/

-- Note: These VIEW queries give some error because some column names do not exist in AdventureWorks2022 database table.

CREATE VIEW MyProducts AS
SELECT 
    p.ProductID,
    p.ProductName,
    p.QuantityPerUnit,
    p.UnitPrice,
    s.CompanyName,
    c.CategoryName
FROM 
    Production.Product AS p
    INNER JOIN Purchasing.Supplier AS s ON p.SupplierID = s.BusinessEntityID
    INNER JOIN Production.ProductCategory AS c ON p.ProductCategoryID = c.ProductCategoryID
WHERE 
    p.Discontinued = 0
    
    
SELECT * FROM MyProducts;









-- 		Triggers




/*
If someone cancels an order in northwind database, then you want to delete 
that order from the Orders table. But you will not be able to delete that 
Order before deleting the records from Order Details table for that 
particular order due to referential integrity constraints. Create an Instead 
of Delete trigger on Orders table so that if some one tries to delete an 
Order that trigger gets fired and that trigger should first delete 
everything in order details table and then delete that order from the Orders 
table
*/

USE Northwind;

CREATE TRIGGER DeleteOrderWithDetails
ON Orders
INSTEAD OF DELETE
AS
BEGIN
    -- Delete records from Order Details table first
    DELETE FROM [Order Details]
    WHERE OrderID IN (SELECT OrderID FROM deleted);

    -- Now delete the order from the Orders table
    DELETE FROM Orders
    WHERE OrderID IN (SELECT OrderID FROM deleted);
END;









/*
When an order is placed for X units of product Y, we must first check the 
Products table to ensure that there is sufficient stock to fill the order. 
This trigger will operate on the Order Details table. If sufficient stock 
exists, then fill the order and decrement X units from the UnitsInStock 
column in Products. If insufficient stock exists, then refuse the order (ie. 
do not insert it) and notify the user that the order could not be filled 
because of insufficient stock.
*/

CREATE TRIGGER CheckStockAndFillOrder
ON [Order Details]
INSTEAD OF INSERT
AS
BEGIN
    -- Check if there is sufficient stock for each order detail
    IF EXISTS (
        SELECT od.ProductID, p.UnitsInStock, SUM(od.Quantity) AS RequiredUnits
        FROM inserted od
        INNER JOIN Products p ON od.ProductID = p.ProductID
        GROUP BY od.ProductID, p.UnitsInStock
        HAVING SUM(od.Quantity) <= p.UnitsInStock
    )
    BEGIN
        -- Sufficient stock available, fill the order and decrement UnitsInStock
        DECLARE @ProductID INT;
        DECLARE @Quantity INT;

        DECLARE order_cursor CURSOR FOR
            SELECT ProductID, Quantity FROM inserted;

        OPEN order_cursor;
        FETCH NEXT FROM order_cursor INTO @ProductID, @Quantity;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            UPDATE Products
            SET UnitsInStock = UnitsInStock - @Quantity
            WHERE ProductID = @ProductID;

            FETCH NEXT FROM order_cursor INTO @ProductID, @Quantity;
        END;

        CLOSE order_cursor;
        DEALLOCATE order_cursor;

        -- Insert the order details into the table
        INSERT INTO [Order Details]
        SELECT * FROM inserted;
    END
    ELSE
    BEGIN
        -- Insufficient stock, refuse the order and notify the user
        RAISERROR ('Order could not be filled due to insufficient stock.', 16, 1);
    END
END;

