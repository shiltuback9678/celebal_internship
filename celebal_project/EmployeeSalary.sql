-- Create the Employees table
CREATE TABLE Employees (
    EmployeeID INT,
    Name VARCHAR(50),
    DepartmentID INT,
    Salary DECIMAL(10, 2)
);


-- Create the Departments table
CREATE TABLE Departments (
    DepartmentID INT,
    Name VARCHAR(50)
);


-- Insert data into the Employees table
INSERT INTO Employees (EmployeeID, Name, DepartmentID, Salary) VALUES
(1, 'John Doe', 1, 60000.00),
(2, 'Jane Smith', 1, 70000.00),
(3, 'Alice Johnson', 1, 65000.00),
(4, 'Bob Brown', 1, 75000.00),
(5, 'Charlie Wilson', 1, 80000.00),
(6, 'Eva Lee', 2, 70000.00),
(7, 'Michael Clark', 2, 75000.00),
(8, 'Sarah Davis', 2, 80000.00),
(9, 'Ryan Harris', 2, 85000.00),
(10, 'Emily White', 2, 90000.00),
(11, 'David Martinez', 3, 95000.00),
(12, 'Jessica Taylor', 3, 100000.00),
(13, 'William Rodriguez', 3, 105000.00);

-- Insert data into the Departments table
INSERT INTO Departments (DepartmentID, Name) VALUES
(1, 'Marketing'),
(2, 'Research'),
(3, 'Development');

-- View all data from the Employees table
SELECT * FROM Employees;

-- View all data from the Departments table
SELECT * FROM Departments;

-- Query to find the average salary of employees in each department
-- including only those departments where the average salary is higher than the overall average salary across all departments
WITH DepartmentAvgSalaries AS (
    SELECT 
        e.DepartmentID,
        d.Name AS DepartmentName,
        AVG(e.Salary) AS AverageSalary,
        COUNT(e.EmployeeID) AS NumberOfEmployees
    FROM 
        Employees e
    JOIN 
        Departments d ON e.DepartmentID = d.DepartmentID
    GROUP BY 
        e.DepartmentID, d.Name
),
OverallAvgSalary AS (
    SELECT 
        AVG(AverageSalary) AS OverallAverage
    FROM 
        DepartmentAvgSalaries
)
SELECT 
    DepartmentName,
    AverageSalary,
    NumberOfEmployees
FROM 
    DepartmentAvgSalaries
WHERE 
    AverageSalary > (SELECT OverallAverage FROM OverallAvgSalary);
