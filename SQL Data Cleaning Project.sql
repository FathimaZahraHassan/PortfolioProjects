/* 
Cleaning Data in SQL Queries
*/

SELECT * 
FROM Public."UniEmployeeSalaries";

-- Standardizing earnings Format by type conversion

SELECT EarningsConverted, CAST(Earnings AS INT)
FROM Public."UniEmployeeSalaries";

Alter Table "UniEmployeeSalaries"
Add EarningsConverted INT;

UPDATE Public."UniEmployeeSalaries"
SET EarningsConverted = CAST(Earnings AS INT);

-- Finding Duplicates

WITH RowNumCTE AS(
SELECT *, 
	ROW_NUMBER () OVER (
	PARTITION BY EmployeeName,
	             School,
	             JobDescription,
	             Department,
	             Earnings,
	             Year
	             ORDER BY EmployeeName
	                    ) row_num
FROM Public."UniEmployeeSalaries"
)
DELETE
FROM RowNumCTE
WHERE row_num > 1
ORDER BY School

-- Delete Unused Columns

SELECT * 
FROM Public."UniEmployeeSalaries";

ALTER TABLE Public."UniEmployeeSalaries"
DROP COLUMN Earnings;
