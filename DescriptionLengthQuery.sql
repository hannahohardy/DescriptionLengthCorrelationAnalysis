WITH DescriptionLengthQuery
AS
(
	SELECT DISTINCT DescriptionLengthMissing = isnull(len(p.description),0), kr.imt_id as ID
	FROM keboola_replacement.[out].[c_bwd_reports.gap3_views_leads_connections_impstotal] AS kr
	INNER JOIN extracts.imt.products AS p
	ON kr.imt_id = p.id and kr.source_actual_date = p.source_actual_date
	
),
AnalysisVarsQuery
AS
(
	SELECT kr.imt_id as ID ,p.description as description , kr.DescriptionLength as DescriptionLength , SUM(leads_email) as emailLeads, [condition], portal , kr.source_actual_date as theDate , p.owner_id as owner_id , SUM(leads_email + leads_phone + leads_morefromoem + leads_websitereferral + leads_saveboat + leads_viewallinventory + leads_mapview + leads_printlisting+ leads_emailfriend + leads_locatedealer + leads_socialshare + leads_phoneclick ) as total_leads, p.is_model as isModel, parties.fsbo as isfsbo
	FROM keboola_replacement.[out].[c_bwd_reports.gap3_views_leads_connections_impstotal] AS kr
	INNER JOIN extracts.imt.products AS p
	ON kr.imt_id = p.id and kr.source_actual_date = p.source_actual_date
	INNER JOIN keboola_replacement.[in].[c_main_rs.parties] as parties
	ON p.owner_id = parties .id
	where kr.imt_id = 394964
	GROUP BY kr.imt_id , p.description , kr.DescriptionLength, [condition] , portal , kr.source_actual_date , p.owner_id, p.is_model, parties.fsbo
)
SELECT
a.ID,b.ID, a.description, ISNULL(a.DescriptionLength,b.DescriptionLengthMissing) as DescriptionLengthFull, a.emailLeads, [condition], portal, a.theDate, a.owner_id, a.total_leads, a.isModel, a.isfsbo
--a.ID ,bunchofothercolumns,ISNULL(a.DescriptionLength,b.DescriptionLength) as DescriptionLength
FROM AnalysisVarsQuery as a
LEFT JOIN DescriptionLengthQuery as b
ON a.ID = b.ID
--description length is NULL
