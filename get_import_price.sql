create or replace function get_import_price(p_date in date,p_invid in varchar2,p_quantity in number,p_dated in date,p_deptid in varchar2) return number
is 
res_price number(12,6);
res_pri   number(12,6);
res_qty   number(12,6);
res_amount number(12,6);
start_date date;
end_date date;
begin
IF p_date>=p_dated THEN 
select 
       trunc(p_date,'MM'),
       last_day(p_date) 
       into
       start_date,
       end_date
from dual;
ELSE
select last_day(p_dated) into end_date from dual;
select trunc(p_date,'MM') into start_date from dual;
end IF  ;

with set_production as 
(
select
       b.fmaterialid,
       sum(b.fqty) qty,
       sum(b.factualcost) amount            
from T_IM_ManufactureRecBill@to_kd_test a
inner join T_IM_ManufactureRecBillentry@to_kd_test b on b.fparentid = a.fid
where a.fbizdate <=end_date
and extract( year from a.fbizdate) =extract(year from p_date)
and b.fmaterialid=p_invid
and  a.FSTORAGEORGUNITID in ('KFoTAZLDQmiTr5wWTB2IWcznrtQ=','oeXsfEJrQzGHCrkt+Vc2vMznrtQ=','l8eCbH5rQsCzCHOr7zPjJMznrtQ=') 
group by  b.fmaterialid),
--四大的采购入库 剔除内部供应商部分
--考虑暂估问题更改成提取应付单的逻辑
--set_purchase as
--( select b.fmaterialid,
--      sum(b.fqty) qty,
--      sum(b.FACTUALCOST) amount
--from  T_IM_PurInWarehsBill@to_kd_test a
--inner join T_IM_PurInWarehsEntry@to_kd_test b on b.fparentid = a.fid
--inner join T_BD_Supplier@to_kd_test c on c.fid=a.fsupplierid
--where 
--    a.fbizdate <=end_date
--   and a.fyear = extract(year from end_date)
--  -- and a.fbizdate>= start_date
--   and b.fmaterialid=p_invid
--   and nvl(c.fisinternalcompany,0)=0
--   and a.FSTORAGEORGUNITID in ('KFoTAZLDQmiTr5wWTB2IWcznrtQ=','oeXsfEJrQzGHCrkt+Vc2vMznrtQ=','l8eCbH5rQsCzCHOr7zPjJMznrtQ=','h104ztQXQCC/Gi2CUziK8cznrtQ=')
--   group by  b.fmaterialid
--),
set_ap as (
select  b.fmaterialid,
        sum(b.fquantity) qty,
        sum(b.famount) amount
from T_AP_OtherBill @to_kd_test a
inner join T_AP_OtherBillentry@to_kd_test b on b.fparentid=a.fid
inner join T_BD_Supplier@to_kd_test c on c.fid = a.FASSTACTID
where extract( year from a.fbizdate) =extract(year from p_date)
and a.fcompanyid in ('KFoTAZLDQmiTr5wWTB2IWcznrtQ=','oeXsfEJrQzGHCrkt+Vc2vMznrtQ=','l8eCbH5rQsCzCHOr7zPjJMznrtQ=','h104ztQXQCC/Gi2CUziK8cznrtQ=')
and b.fmaterialid=p_invid
and a.fbizdate <=end_date
and a.FBILLSTATUS='3'
group by b.fmaterialid
),
set_final as 
( select fmaterialid, qty,amount from set_production
 union all
 select   fmaterialid,qty,amount from set_ap
)
select sum(amount)/sum(qty) into res_pri from set_final;
--统计销售明细总共出库量截止到上个月份
with set_sale_detail as (
select sum(quantity) quantity,sum(cost_price*quantity) amount from wfz_sale_detail 
                where deptid = p_deptid
--                    in (select orgid from wfz_orgs 
--                    start with org_code = '1_92_801' 
--                    connect by prior orgid = orgparent)
                   and invid=p_invid
--                   and saleout_date <start_date
                   and bill_date < start_date
                   and bill_year = extract(year from end_date)
                  )
select nvl(quantity,0),nvl(amount,0) into res_qty,res_amount from set_sale_detail; 
select (res_pri*(res_qty+p_quantity)-res_amount)/p_quantity into res_price from dual;
return res_price;
exception 
    when others then
    return NULL;
end;
