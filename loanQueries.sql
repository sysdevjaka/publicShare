USE ProjectMarch_Center;
DECLARE @startDate datetime, @endDate datetime;

SET @startDate = '2020-12-01 00:00:00';
SET @endDate = '2020-12-30 23:59:59';
SELECT
	REPLACE(jl.Code, 'LVL', '') AS 'Employee Level',
	e.EmployeeCode AS 'Employee ID',
	e.LastName AS 'Last Name',
	e.FirstName AS 'First Name',
	e.MiddleName AS 'Middle Name',
	'' AS 'Suffix',
	'' AS 'Type',		
	s3.[Starting Date],	
	s3.[Loan Name],
	'' AS 'HR Loan Type',
	s3.[Amount (Remaining Balance)],
	s3.[Interest Amount],
	s3.[Remaining Period (# of Payments)],
	'' AS 'Deduction Schedule',
	s3.[Loan Amortization],
	--s3.paydate AS 'Payment Due Date (Loan End Date)',
	'' AS 'Notes',
	'' AS 'Employee Government Number'
FROM
(
	SELECT
		PayslipId,
		SalaryId,
		PayrollId,
		[Starting Date],
		[Loan Name],
		[Amount (Remaining Balance)],
		[Interest Amount],
		[Remaining Period (# of Payments)],
		[Loan Amortization]
		--[paydate]
	FROM
	(
		SELECT			
			c.Id AS ComponentId,
			s.Id AS PayslipId,
			s.SalaryId AS SalaryId,
			s.PayrollId AS PayrollId,
			ld.StartingDate AS 'Starting Date',
			l.Name AS 'Loan Name',
			CASE 
				WHEN ld.RemainingBalance < 0 THEN ld.TotalAmount - ld.PaidAmount
				ELSE 0
			END AS 'Amount (Remaining Balance)',				
			ld.Interest AS 'Interest Amount',
			ld.NumberOfUnpaid AS 'Remaining Period (# of Payments)',
			ld.Amortization AS 'Loan Amortization',
			CASE 
				WHEN ld.NumberOfPayment > ld.NumberOfUnpaid THEN lb.PayDate
				ELSE 0
			END AS 'Payment Due Date (Loan End Date)'
			
		FROM PayslipComponents AS c
		INNER JOIN Payslips AS s ON s.Id = c.PayslipId
		LEFT OUTER JOIN PayslipComponentCategoryMap AS m ON m.ComponentId = c.Id
		INNER JOIN Salaries AS sl ON sl.Id = s.SalaryId
		LEFT OUTER JOIN PayslipComponentLoanBreakdownMap AS lm ON lm.PayslipComponentId = c.Id
		LEFT OUTER JOIN LoanBreakdown AS lb ON lb.Id = lm.LoanBreakdownId
		INNER JOIN LoanDetails AS ld ON ld.Id = lb.LoanDetailId
		INNER JOIN LoanTypes AS l ON l.Id = ld.LoanTypeId
		LEFT OUTER JOIN ReferenceSss AS rs ON rs.Er = c.Amount AND c.RateType = 8
		LEFT OUTER JOIN Payrolls AS r ON r.Id = s.PayrollId
		WHERE sl.EligibleForPayroll = 1
	) AS s2
	GROUP BY 
		s2.PayslipId, 
		s2.SalaryId, 
		s2.PayrollId, 
		s2.[Starting Date], 
		s2.[Loan Name], 
		s2.[Amount (Remaining Balance)], 
		s2.[Interest Amount], 
		s2.[Remaining Period (# of Payments)], 
		s2.[Loan Amortization]
		--s2.paydate
) AS s3
INNER JOIN Payslips AS ps ON ps.Id = s3.PayslipId
INNER JOIN Salaries AS s ON s.Id = s3.SalaryId
INNER JOIN Employee AS e ON e.Id = s.EmployeeId
INNER JOIN Payrolls AS r ON r.Id = s3.PayrollId
INNER JOIN Periods AS p ON p.Id = r.PeriodId
INNER JOIN Department AS d ON d.Id = e.DepartmentId
INNER JOIN JobDetail AS jd ON jd.EmployeeId = e.Id
INNER JOIN JobLevel AS jl ON jl.id = jd.JobCategory
WHERE NOT (p.StartDate > @endDate OR p.EndDate < @startDate)
