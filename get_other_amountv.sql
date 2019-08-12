create or replace Function get_other_amountv(p_date in date,dept_id in varchar2,company_id in varchar2) return number
--增加库存组织维度
is
res_amount number(16,6);
start_date date;
end_date date;
begin 
select trunc(p_date,'MM'),
       last_day(p_date) 
       into
       start_date,
       end_date
from dual;
---盘点入库
with invent_set_in as
(
select
  b.fmaterialid materid,
  b.funitid     funitid,
  b.fqty quantity
from T_IM_OtherInWarehsBill@to_kd_test a
inner join T_IM_OtherInWarehsBillEntry@to_kd_test b on b.fparentid=a.fid
inner join T_BD_MaterialCompanyInfo@to_kd_test c on c.fmaterialid = b.fmaterialid and c.fcompanyid = a.FSTORAGEORGUNITID
--inner join T_BD_KAClassfication@to_kd_test d on d.fid = c.fkaclassid
inner join T_BD_KAClassfication@to_kd_test d on d.fid = c.fkaclassid and d.FCURRENCYCOMPANY=c.fcompanyid
inner join T_BD_KAClassificationDetail@to_kd_test e on e.FKACLASSFICLINK =d.fid
inner join T_BD_AccountView@to_kd_test f on f.fid= e.FACCOUNTLINKID and f.FCOMPANYID=a.FSTORAGEORGUNITID
where a.fbasestatus='4'
and a.fbizdate >= start_date
and a.fbizdate <= end_date
--and a.FSTORAGEORGUNITID in (select FSTORAGEORGID from T_DB_WAREHOUSE@to_kd_test where fid= storeorg_id)
and a.FCOSTCENTERORGUNITID = dept_id
and a.FBIZTYPEID='Nz878AEgEADgAABGwKg/GiQHQ1w='        --501
and e.FACCOUNTITEMLINKID = 'MfUAAACHAPn59CPA'            --9000
--and e.FACCOUNTLINKID = 'CVEKwEk1TdioXKkH03MEiJ2pmCY='),  --6401020102
and f.fnumber ='6401020102'),
--盘点出库
invent_set_out as
(
select 
  b.fmaterialid materid,
  b.funitid     funitid,
  b.fqty quantity
from T_IM_OtherIssueBill@to_kd_test a
inner join T_IM_OtherIssueBillEntry@to_kd_test b on b.fparentid=a.fid
inner join T_BD_MaterialCompanyInfo@to_kd_test c on c.fmaterialid = b.fmaterialid and c.fcompanyid = a.FSTORAGEORGUNITID
--inner join T_BD_KAClassfication@to_kd_test d on d.fid = c.fkaclassid
inner join T_BD_KAClassfication@to_kd_test d on d.fid = c.fkaclassid and d.FCURRENCYCOMPANY=c.fcompanyid
inner join T_BD_KAClassificationDetail@to_kd_test e on e.FKACLASSFICLINK =d.fid
inner join T_BD_AccountView@to_kd_test f on f.fid= e.FACCOUNTLINKID and f.FCOMPANYID=a.FSTORAGEORGUNITID
where a.fbasestatus='4'
and a.fbizdate >= start_date
and a.fbizdate <= end_date
and a.FCOSTCENTERORGUNITID=dept_id
--and a.FSTORAGEORGUNITID in (select FSTORAGEORGID from T_DB_WAREHOUSE@to_kd_test where fid= storeorg_id)
and a.FBIZTYPEID='N5d2igEgEADgAAB0wKg/GiQHQ1w='          --511
and e.FACCOUNTITEMLINKID = 'MfUAAACHAPn59CPA'            --9000   
--and e.FACCOUNTLINKID = 'CVEKwEk1TdioXKkH03MEiJ2pmCY='),  --6401020102
and f.fnumber='6401020102'),
--手工其他入库
other_set_in as 
(
select
   b.fmaterialid materid,
   b.funitid     funitid,
   b.fqty quantity
from T_IM_OtherInWarehsBill@to_kd_test a
inner join T_IM_OtherInWarehsBillEntry@to_kd_test b on b.fparentid=a.fid
where a.fbasestatus='4'
and a.fbizdate >= start_date
and a.fbizdate <= end_date
and a.FCOSTCENTERORGUNITID = dept_id 
--and a.FSTORAGEORGUNITID in (select FSTORAGEORGID from T_DB_WAREHOUSE@to_kd_test where fid= storeorg_id)
and a.FTRANSACTIONTYPEID ='MfUAAACYk1KwCNyn'),  --入库 01305
--手工其他出库
other_set_out as
(
select 
  b.fmaterialid materid,
  b.funitid     funitid,
  b.fqty quantity
from T_IM_OtherIssueBill@to_kd_test a
inner join T_IM_OtherIssueBillEntry@to_kd_test b on b.fparentid=a.fid
where a.fbasestatus='4'
and a.fbizdate >= start_date
and a.fbizdate <= end_date
and a.FCOSTCENTERORGUNITID = dept_id
--and a.FSTORAGEORGUNITID in (select FSTORAGEORGID from T_DB_WAREHOUSE@to_kd_test where fid= storeorg_id)
and a.FTRANSACTIONTYPEID ='MfUAAAAVp0mwCNyn'),  --出库 00401
--手工其他入库未走事务类型
other_noset_in as (
select
   b.fmaterialid materid,
   b.funitid     funitid,
   b.fqty quantity
from T_IM_OtherInWarehsBill@to_kd_test a
inner join T_IM_OtherInWarehsBillEntry@to_kd_test b on b.fparentid=a.fid
where a.fbasestatus='4'
and a.fbizdate >= start_date
and a.fbizdate <= end_date
and a.FCOSTCENTERORGUNITID = dept_id 
and b.cfaccountnote in ('6401020102','6401020199')
),
--手工其他出库未走事务类型
other_noset_out as (
select 
  b.fmaterialid materid,
  b.funitid     funitid,
  b.fqty quantity
from T_IM_OtherIssueBill@to_kd_test a
inner join T_IM_OtherIssueBillEntry@to_kd_test b on b.fparentid=a.fid
where a.fbasestatus='4'
and a.fbizdate >= start_date
and a.fbizdate <= end_date
and a.FCOSTCENTERORGUNITID = dept_id
and b.cfaccountnote in ('6401020102','6401020199')
),
---形态转换单
other_fchange_in as(
select 
 b.fmaterialid materid,
 b.funitid     funitid,
 b.fqty        quantity
from T_IM_MatAttrChangeBill@to_kd_test  a
inner join T_IM_MatAttrChangeBeforeEntry@to_kd_test  b on b.fparentid=a.fid
inner join T_BD_Material@to_kd_test c on c.fid=b.fmaterialid
inner join T_IM_MatAttrChangeAfterEntry@to_kd_test d on d.fparentid=b.fid
inner join T_BD_Material@to_kd_test e on e.fid =d.fmaterialid
inner join T_SCM_billtype@to_kd_test f on f.fid=a.fbilltypeid
where a.fbasestatus='4'
and f.fnumber='121'
and a.fbizdate>= start_date
and a.fbizdate<= end_date
and a.CFCFCOSTCENTERIDID= dept_id
and e.fnumber='99.90.101'
),
final_detail as 
(
select materid,funitid,quantity*-1 quantity from invent_set_in
union all
select materid,funitid,quantity from invent_set_out
union all
select materid,funitid,quantity*-1 quantity  from other_set_in
union all
select materid,funitid,quantity from other_set_out
union all
select materid,funitid,quantity*-1 quantity from other_noset_in
union all
select materid,funitid,quantity from other_noset_out
union all
select materid,funitid,quantity from other_fchange_in
),
final_res as (
select materid,funitid,sum(quantity) quantity from final_detail group by materid,funitid),
final_amount as (
select materid,funitid,quantity,wfz_evaluation_price.get_eval_price_on_someday(( SELECT cust.fid FROM eas85.t_org_baseunit@to_kd_test org
                                                                                   INNER JOIN eas85.t_bd_customer@to_kd_test cust ON org.fnumber = cust.fnumber
                                                                                   WHERE org.fid = dept_id),materid,funitid,p_date) price  from final_res),
final_total as(
select sum(price*quantity) total_res from final_amount
)
select total_res into res_amount from final_total;
return res_amount;
EXCEPTION 
   when OTHERS THEN
   return 0;
end;
