/*
Sales Report
to return only dispenses
Last Modified on October 24 2014
by Adam Amodio
*/


declare @StartDate datetime, @EndDate DateTime
Set @StartDate = ''
Set @EndDate = ''


SELECT CONVERT(VARCHAR(10), disp.dispense_date, 101) AS transaction_date,
rx.script_no,
disp.rxdisp_id,
disp.fill_no,
rx.refills_left,
dispense_qty = dispense_qty,
drug_name = disp.disp_drug_name,
formula_id = ndc,
plan_name =
 CASE
   WHEN price.pay_type_cn = 7 THEN 'Workers Compensation'
   WHEN price.pay_type_cn = 8 THEN 'Accounts Receivable'
   WHEN price.pay_type_cn  in (2,3) THEN 'Cash'
   WHEN price.pay_type_cn > 999 THEN org.name
   ELSE 'Unspecified Payment Type'
 END,
[Priority] = c.name,
price.primary_amt_paid,
price.second_amt_paid,
 CASE
   WHEN rx.ndc IN ('4093','4970','7980','10629','12970','12999','13094','13095','13097','13102','13103','13138','13145','13148','13150','13158','13167','13172','13174','13175','13185','13195','13200','13214','13215','13226','13276','13283','13294','13305','13308','13320','13330','13342','13349','13375','13384','13399','13403','13405','13406','13417','13418','13431','13437','13441','13456','13466','13470','13479') THEN 0
   ELSE price.t_patient_pay_paid
 END as copay,
total_amount_submitted = price.t_price_sub,
CONVERT(VARCHAR(10), rx.orig_date, 101) AS orig_date,
patient_state = ad.state_cd,
[Patient FirstName] = p.fname,
[Patient LastName] = p.lname,
[Patient DOB] = p.birth_date, 
'' AS [Data],
'' AS [Classification],
'' AS [Stage],
rx.auth_by,
[MD Name] = md.fname + ' ' + md.lname,
'' AS [SFDC Contact ID],
ad.city,
ad.state_cd,
ad.zip,
[mdPhone]=isnull(mdPh.area_code,'')+mdPh.phone_no,
[MD NPI] = md.npi_id,
[Doctor State]=mAddress.state_cd,
[Patient State]=ad.state_cd,
[Notes] = REPLACE(REPLACE(convert(varchar(max),p.cmt), CHAR(13), ''), CHAR(10), '')

--%BEGIN_TRANSDATE%
--%END_TRANSDATE%

FROM cprx rx (NOLOCK) 
JOIN cprx_disp disp  (NOLOCK) ON rx.rx_id = disp.rx_id
LEFT OUTER JOIN cprxdisp_pricing price  (NOLOCK) ON disp.rxdisp_id = price.rxdisp_id
LEFT OUTER JOIN cprxdisp_ack ack  (NOLOCK) ON ack.rxdisp_id = disp.rxdisp_id
LEFT OUTER JOIN cppat_ins ins  (NOLOCK) ON price.pay_type_cn = ins.ptins_id
LEFT OUTER JOIN csorg org  (NOLOCK) ON ins.org_id = org.org_id
LEFT OUTER JOIN cpmd md (nolock) ON rx.md_id = md.md_id
JOIN cppat pat (NOLOCK)  ON rx.pat_id = pat.pat_id
LEFT OUTER JOIN CsOmLine oml  (NOLOCK) on disp.rxdisp_id = oml.rxdisp_id
LEFT OUTER JOIN CSOm om  (NOLOCK) on oml.order_id = om.order_id
left outer join cppat p (nolock) on rx.pat_id = p.pat_id
left outer join csct_code c (nolock) on rx.priority_cn = c.code_num and c.ct_id = 6400 
left outer join cpmd_addr a (nolock) on md.md_id = a.md_id and a.addr_type_cn = 1 --business address
left outer join csaddr ad (nolock) on a.addr_id = ad.addr_id 
left outer join cpmd_phone ph (nolock) on md.md_id = ph.md_id and ph.phone_type_cn = 2 --business phone
left outer join csphone mdPh (nolock) on ph.phone_id = mdPh.phone_id 
left outer join cpmd_addr ma on md.md_id = ma.md_id and ma.addr_type_cn=1--Business address(ct_id 37)
left outer join csaddr mAddress on ma.addr_id = mAddress.addr_id
Where
--%BEGIN_WHERE% 
disp.dispense_date >= @startdate  and disp.dispense_date <= @enddate and disp.store_id in (1)
--%END_WHERE%
AND IsNull(rx.script_status_cn, 0) <> 3
AND disp.status_cn in (0,1)  

ORDER BY plan_name,md.lname, md.fname, disp.dispense_date
