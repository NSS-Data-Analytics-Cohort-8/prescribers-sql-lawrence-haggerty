--Review of Tables

SELECT *
FROM cbsa;

SELECT *
FROM drug;

SELECT *
FROM fips_county;

SELECT *
FROM overdoses;

SELECT *
FROM population;

SELECT *
FROM prescriber;

SELECT *
FROM prescription;

SELECT *
FROM zip_fips;

-- 1. 
--     a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.

SELECT npi 
FROM prescriber;

SELECT SUM(total_claim_count) AS total_claims
FROM prescription;
--Thinking my way thru the question

SELECT prescriber.npi,
	SUM(total_claim_count) AS sum_total_claims
FROM prescriber
LEFT JOIN prescription
ON prescriber.npi=prescription.npi
GROUP by prescriber.npi
ORDER BY sum_total_claims DESC;
--LEFT JOIN Returns NULL in SUM Total Claims Column
--Move Over to Use a INNER JOIN to Remove NULL Values

SELECT prescriber.npi,
	SUM(total_claim_count) AS sum_total_claims
FROM prescriber
INNER JOIN prescription
ON prescriber.npi=prescription.npi
GROUP by prescriber.npi
ORDER BY sum_total_claims DESC;
--INNER JOIN Returned Results w/o NULL Values as Expected

--ANSWER: Highest Claims NPI 1881634483 / Total Claims 99707

--     b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.

SELECT nppes_provider_last_org_name AS last_name,
	nppes_provider_first_name AS first_name, 
	specialty_description AS specialty, 
	SUM(total_claim_count) AS sum_total_claims
FROM prescriber AS p1
INNER JOIN prescription AS p2
USING (npi)
GROUP BY last_name, first_name, specialty
ORDER BY sum_total_claims DESC
LIMIT 1;

--ANSWER: "PENDLEY"	"BRUCE" / "Family Practice"	/ Total CLaims "99707"

-- 2. 
--     a. Which specialty had the most total number of claims (totaled over all drugs)?

SELECT specialty_description AS specialty,
	SUM(total_claim_count) AS sum_total_claims
FROM prescriber
LEFT JOIN prescription
USING (npi)
GROUP BY specialty
ORDER BY sum_total_claims DESC;
--LEFT JOIN Returns NULLS as Expected...Left Join Matched Using NPI...LEFT JOIN will return all records in the left table, and those records in the right table that match on the joining field provided...Can Result in NULL values.   

SELECT specialty_description AS specialty,
	SUM(total_claim_count) AS sum_total_claims
FROM prescriber
INNER JOIN prescription
USING (npi)
GROUP BY specialty
ORDER BY sum_total_claims DESC
LIMIT 1;
--INNER JOIN looks for records in both tables which match on a given field.

--ANSWER: "Family Practice"	/ Total Claims "9752347"

--     b. Which specialty had the most total number of claims for opioids?
SELECT opioid_drug_flag
FROM drug;

SELECT specialty_description AS specialty,
	SUM(total_claim_count) AS sum_opioid_claims
FROM prescriber
INNER JOIN prescription
USING (npi)
INNER JOIN drug
USING (drug_name)
WHERE opioid_drug_flag='Y'
GROUP BY specialty
ORDER BY sum_opioid_claims DESC
LIMIT 5;
--Ran w/ INNER JOIN now compare w/ LEFT JOIN

SELECT specialty_description AS specialty,
	SUM(total_claim_count) AS sum_opioid_claims
FROM prescriber
LEFT JOIN prescription
USING (npi)
LEFT JOIN drug
USING (drug_name)
WHERE opioid_drug_flag='Y'
GROUP BY specialty
ORDER BY sum_opioid_claims DESC
LIMIT 5;
--INNER JOIN and LEFT JOIN return the Same Results...Prescriber/Prescription KEY=npi...Prescription/Drug Key=Drug Name...Chaining KEYs Required to Pull Info from Drug to Prescriber. 
--Used Limit of 5 for Comparison Purposes. 

--ANSWER: "Nurse Practitioner" Total "900845"

--     c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?

--     d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?

-- 3. 
--     a. Which drug (generic_name) had the highest total drug cost?

SELECT generic_name AS drug,
	total_drug_cost 
FROM drug
LEFT JOIN prescription
USING (drug_name)
GROUP BY drug, total_drug_cost
ORDER BY total_drug_cost DESC;
--Significant Amount (>1000) of NULL for total_drug_cost based off of LEFT JOIN of prescription to drug. LEFT JOIN will return all records in the left table, and those records in the right table that match on the joining field provided

SELECT generic_name AS drug,
	total_drug_cost 
FROM drug
INNER JOIN prescription
USING (drug_name)
GROUP BY drug, total_drug_cost
ORDER BY total_drug_cost DESC;
--INNER JOIN produced cleaner results. INNER JOIN: looks for records in both tables which match on a given field.

SELECT generic_name AS drug,
	total_drug_cost 
FROM prescription
LEFT JOIN drug
USING (drug_name)
GROUP BY drug, total_drug_cost
ORDER BY total_drug_cost DESC;
LIMIT 1;
--LEFT JOIN of drug to prescription returned the same as INNER JOIN above. 

--ANSWER: "PIRFENIDONE"	/ Total Drug Cost "2829174.3"

--     b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**

SELECT *
FROM prescription;
--Reviewing Prescription Columns

--Column Definitions:
--total_drug_cost – The aggregate drug cost paid for all associated claims.
--total_30_day_fill_count – The aggregate number of Medicare Part D standardized 30-day fills.
--total_day_supply – The aggregate number of day’s supply for which this drug was dispensed.

SELECT generic_name,
	ROUND(AVG(total_drug_cost/total_30_day_fill_count),2) AS daily_cost
FROM prescription
LEFT JOIN drug
USING (drug_name)
GROUP BY generic_name
ORDER BY daily_cost DESC;
---Continue to Review
---******************

-- 4. 
--     a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.

SELECT 
	drug_name,
	CASE WHEN opioid_drug_flag='Y' THEN 'opioid'
		 WHEN antibiotic_drug_flag='Y' THEN 'antibiotic'
		 ELSE 'neither' END AS drug_type
FROM drug;
--CASE STATEMENT...Results Returned as Expected 

SELECT 
	drug_name,
	CASE WHEN opioid_drug_flag='Y' THEN 'opioid'
		 WHEN antibiotic_drug_flag='Y' THEN 'antibiotic'
		 ELSE 'neither' END AS drug_type
FROM drug
WHERE opioid_drug_flag='Y' OR antibiotic_drug_flag='Y'
ORDER BY drug_type;
--SAME CASE STATEMENT Filtered to Show Opioids and Antibiotics Only

--     b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.

SELECT
	SUM(CASE WHEN opioid_drug_flag='Y' THEN total_drug_cost END) AS opioid_total_cost,
	SUM(CASE WHEN antibiotic_drug_flag='Y'THEN total_drug_cost END) AS antibiotic_total_cost
FROM drug
LEFT JOIN prescription
USING (drug_name);

--ANSWER: Opioids: 105,080,626.37 > Antibiotics: 38,435,121.26

-- 5. 
--     a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.

SELECT
--     b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.

--     c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.

-- 6. 
--     a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.

--     b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

--     c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.

-- 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.

--     a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Managment') in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.

--     b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).
    
--     c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.