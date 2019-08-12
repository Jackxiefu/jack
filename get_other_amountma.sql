create or replace Function get_other_amountma(p_date in date,dept_id in varchar2,p_warehouseid in varchar2,p_warehouse in varchar2) return number
--进出口99成本
is
res_amount number(16,6);
ma_amount number(16,6);
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
 b.fqty quantity
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
select materid,sum(quantity) quantity from final_detail group by materid),

final_amount as (
select materid,quantity,nvl(get_final_price(p_date,materid,p_warehouseid,p_warehouse),0) price from final_res
)
select sum(quantity*price) into res_amount from final_amount;
--澳门手工凭证金额
with ma_res as
(
select sum(c.FLOCALAMOUNT) amount
from T_GL_Voucher@to_kd_test a
inner join T_GL_Voucherentry@to_kd_test b on b.fbillid=a.fid
inner join T_GL_VoucherAssistRecord@to_kd_test c on c.FENTRYID=b.fid
inner join T_BD_AssistantHG@to_kd_test d on d.fid=c.FASSGRPID
inner join T_ORG_BaseUnit@to_kd_test e on e.fid=d.FCOSTORGID
inner join T_BD_AccountView@to_kd_test f on f.fid=c.FACCOUNTID and f.FCOMPANYID=c.FCOMPANYID
where a.FCOMPANYID='kMbG8YDHRi2qcpaVDvSgQsznrtQ='
     and a.fbizdate>=start_date
     and a.fbizdate<=end_date
    -- and a.fsourceSys='7'
    and (a.fsourceSys ='7' or (a.fsourceSys='6' and  a.fsourcetype='0')
      or (a.fsourceSys in ('13','20') and a.fsourcetype='3'))
     and instr(f.fnumber,'6401')>0
)
select nvl(amount,0) into ma_amount from ma_res;
select res_amount+ma_amount*(select exg_rate from wfz_exg_rate where source_currency='qkWZc7UgRyKjdFeU9r8gct61j9w=') into res_amount from dual;
return res_amount;

EXCEPTION 
   when OTHERS THEN
   return 0;
end;
