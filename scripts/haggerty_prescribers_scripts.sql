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

SELECT specialty_description AS specialty,
	SUM(total_claim_count) AS sum_opioid_claims
FROM prescriber
LEFT JOIN prescription
USING (npi)
LEFT JOIN drug
USING (drug_name)
WHERE opioid_drug_flag='Y' AND total_claim_count IS NULL
GROUP BY specialty
ORDER BY sum_opioid_claims DESC;
--Returns 0 Results when filtering on the opioid flag

SELECT specialty_description AS specialty,
	SUM(total_claim_count) AS sum_total_claims
FROM prescriber
LEFT JOIN prescription
USING (npi)
LEFT JOIN drug
USING (drug_name)
WHERE total_claim_count IS NULL
GROUP BY specialty
ORDER BY sum_total_claims DESC;
--Returns 92 rows of specialties w/ no claims when not filtering on the opioid flag

--     d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?

WITH oc1 AS (SELECT
			 specialty_description AS specialty,
	SUM(CASE WHEN opioid_drug_flag='Y' THEN total_claim_count END) AS total_opioid_claim 
FROM drug
LEFT JOIN prescription
ON drug.drug_name=prescription.drug_name
LEFT JOIN prescriber
ON prescription.npi=prescriber.npi
GROUP BY specialty),

sc1 AS (SELECT
	specialty_description AS specialty,
	SUM(total_claim_count)AS total_spec_opioid_claims
FROM prescriber
LEFT JOIN prescription
USING (npi)
LEFT JOIN drug
USING (drug_name)
WHERE opioid_drug_flag='Y'
GROUP BY specialty)

SELECT
	specialty_description AS specialty,
	oc1.total_opioid_claim,
	sc1.total_spec_opioid_claims
FROM prescriber
INNER JOIN oc1
ON prescriber.specialty=oc1.specialty
INNER JOIN sc1
ON prescriber.specialty=sc1.specialty
GROUP BY specialty;




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
FROM prescription
INNER JOIN drug
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
ORDER BY total_drug_cost DESC
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
	ROUND(total_drug_cost/total_30_day_fill_count,2) AS daily_cost
FROM prescription
LEFT JOIN drug
USING (drug_name)
GROUP BY generic_name, total_drug_cost, total_30_day_fill_count
ORDER BY daily_cost DESC;
---not sure this is right using 30 day fill count??? try another column...
---follow-up: above returns 30 day cost not daily.

SELECT generic_name,
	ROUND(total_drug_cost/total_day_supply,2) AS daily_cost
FROM prescription
LEFT JOIN drug
USING (drug_name)
GROUP BY generic_name, total_drug_cost, total_day_supply
ORDER BY daily_cost DESC;
--ANSWER: "IMMUN GLOB G(IGG)/GLY/IGA OV50" / 7141.11

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

SELECT *
FROM cbsa;
--Review of CBSA Table

SELECT 
	cbsaname
FROM cbsa
WHERE cbsaname LIKE '%TN%'
GROUP BY cbsaname;
--Reminder can also use ILIKE if case sensitivity is a concern

--ANSWER: 10 CBSAs in TN

--     b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.

SELECT *
FROM population;
--Review population table

SELECT 
	DISTINCT cbsa,
	SUM(population) as cbsa_combined_pop
FROM cbsa
INNER JOIN population
USING (fipscounty)
WHERE cbsaname LIKE '%TN%'
GROUP BY cbsaname, population
ORDER by cbsa;
--Round 1...Multiple Returns for Each CBSA

SELECT 
	cbsaname,
	SUM(population) as cbsa_combined_pop
FROM cbsa
INNER JOIN population
USING (fipscounty)
WHERE cbsaname LIKE '%TN%'
GROUP BY cbsaname
ORDER BY cbsa_combined_pop DESC;
--Got it!

--ANSWER: largest CBS combined population: "Nashville-Davidson--Murfreesboro--Franklin, TN" / 1830410

--     c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.

SELECT 
	cbsa,
	county,
	SUM(population) as cbsa_combined_pop
FROM fips_county
LEFT JOIN population
USING (fipscounty)
LEFT JOIN cbsa
USING (fipscounty)
WHERE state LIKE 'TN' 
	AND cbsa IS NULL 
	AND population IS NOT NULL
GROUP BY cbsa, county
ORDER BY cbsa_combined_pop DESC
LIMIT 1;

--ANSWER: largest county population (not included in a cbsa): "SEVIER"	/ pop: 95,523

-- 6. 
--     a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.

SELECT drug_name, total_claim_count
FROM prescription
ORDER BY total_claim_count DESC;
--looking at the full list

SELECT 
	drug_name,
	total_claim_count
FROM prescription
WHERE total_claim_count >='3000'
GROUP BY drug_name, total_claim_count
ORDER BY total_claim_count DESC;
--Answer: query above returns the requested info
--9 rows of info OXYCODONE / 4538 top result, LEVOTHYROXINE SODIUM / 3023 bottom result


--     b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

SELECT 
	drug_name,
	total_claim_count,
	CASE WHEN opioid_drug_flag='Y' THEN 'Y'
		 ELSE 'N' END AS opioid
FROM prescription
LEFT JOIN drug
USING (drug_name)
WHERE total_claim_count >='3000'
GROUP BY drug_name, total_claim_count, opioid_drug_flag
ORDER BY total_claim_count DESC;
--Answer: query above returns the requested info
--9 rows (w/ opioid notation) of info OXYCODONE / 4538 top result, LEVOTHYROXINE SODIUM / 3023 bottom result


--     c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.

SELECT 
	drug_name,
	total_claim_count,
	CASE WHEN opioid_drug_flag='Y' THEN 'Y'
		 ELSE 'N' END AS opioid,
	CONCAT(nppes_provider_first_name,' ',nppes_provider_last_org_name) AS provider
FROM prescription
LEFT JOIN drug
USING (drug_name)
LEFT JOIN prescriber
USING (npi)
WHERE total_claim_count >='3000'
GROUP BY drug_name, total_claim_count, opioid_drug_flag, nppes_provider_first_name,nppes_provider_last_org_name
ORDER BY total_claim_count DESC;
--Answer: query above returns the requested info
--9 rows (w/ opioid notation) of info. top result: OXYCODONE / 4538 / DAVID COFFEY, bottom result: LEVOTHYROXINE SODIUM / 3023 bottom result / BRUCE PENDLEY


-- 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.

--     a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Managment') in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.

--FULL JOIN combines a LEFT JOIN and a RIGHT JOIN
--CROSS JOIN creates all possible combinations of two tables.
--UNION takes two tables as input, and returns all records from both tables (UNION ALL INCLUDES DUPLICATES)
--npi – National Provider Identifier

SELECT 
	prescriber.npi,
	drug.drug_name
FROM prescriber
CROSS JOIN drug
WHERE drug.drug_name IN
	(SELECT drug_name
	 FROM drug
	 WHERE opioid_drug_flag='Y') AND
	 prescriber.specialty_description='Pain Management' AND
	 prescriber.nppes_provider_city='NASHVILLE'
GROUP BY prescriber.npi, drug.drug_name;

--attempt query w/o subquery in WHERE

SELECT 
	DISTINCT prescriber.npi,
	drug.drug_name
FROM prescriber
CROSS JOIN drug
WHERE opioid_drug_flag='Y' AND
	 prescriber.specialty_description='Pain Management' AND
	 prescriber.nppes_provider_city='NASHVILLE'
GROUP BY prescriber.npi, drug.drug_name;
--cleaner / shorter query....use this one
--returns 637 rows

--     b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).

--CROSS JOIN creates all possible combinations of two tables.
--LEFT JOIN will return all records in the left table, and those records in the right table that match on the joining field provided
--FULL JOIN combines a LEFT JOIN and a RIGHT JOIN

SELECT 
	p1.npi,
	d.drug_name,
	SUM(p2.total_claim_count) AS total_count
FROM prescriber AS p1
CROSS JOIN drug AS d
LEFT JOIN prescription AS p2
USING (npi)
WHERE d.opioid_drug_flag='Y' AND
	 p1.nppes_provider_city='NASHVILLE'
GROUP BY p1.npi, d.drug_name 
ORDER BY total_count DESC;
--Removing Pain Management Shows NULLS in values...  

SELECT 
	p1.npi,
	d.drug_name,
	SUM(p2.total_claim_count) AS total_count 
FROM prescriber AS p1
CROSS JOIN drug AS d
LEFT JOIN prescription AS p2
USING (npi)
WHERE d.opioid_drug_flag='Y' AND
	 p1.specialty_description='Pain Management' AND
	 p1.nppes_provider_city='NASHVILLE'
GROUP BY p1.npi, d.drug_name
ORDER BY total_count ASC;
--Calculates same total cost per npi....continue to troubleshoot / look at JOINs

SELECT 
	p1.npi,
	d.drug_name,
	SUM(p2.total_claim_count) AS total_count 
FROM prescriber AS p1
CROSS JOIN drug AS d
LEFT JOIN prescription AS p2
ON d.drug_name=p2.drug_name
WHERE d.opioid_drug_flag='Y' AND
	 p1.specialty_description='Pain Management' AND
	 p1.nppes_provider_city='NASHVILLE'
GROUP BY p1.npi, d.drug_name
ORDER BY total_count DESC;
--BUENO!!!
--Returns requested npi, the drug name, and the number of claims (total_claim_count) w/ NULLs


    
--     c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.

SELECT 
	p1.npi,
	d.drug_name,
	COALESCE(SUM(p2.total_claim_count),0) AS total_count
FROM prescriber AS p1
CROSS JOIN drug AS d
LEFT JOIN prescription AS p2
ON d.drug_name=p2.drug_name
WHERE d.opioid_drug_flag='Y' AND
	 p1.specialty_description='Pain Management' AND
	 p1.nppes_provider_city='NASHVILLE'
GROUP BY p1.npi, d.drug_name 
ORDER BY total_count ASC;
---w/ COALESCE to fill in NULL w/ 0
--Returns requested npi, the drug name, and the number of claims (total_claim_count) w/ 0 replacing NULLs