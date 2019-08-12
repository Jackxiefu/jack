create or replace function get_final_price(p_date in date,material_id in varchar2,warehouse_id in varchar2,p_currency in varchar2) return number
is 
  res_price number(12,6);
  yy int;
  mm int;
begin 
 select extract(year from p_date),
        extract(month from p_date) 
       into
       yy,
       mm
from dual;
   with first_price as (
   select
   sum(nvl(FPeriodIssueAmount,0)) amount,
   sum(FPeriodIssueQty) qty
  -- nvl(FPeriodEndBalance,0)/FPeriodEndQty price
   from T_IM_InventoryBalance@to_kd_test
   where fyear=yy
    and fperiod=mm
    and FPeriodIssueQty<>0
    and fmaterialid=material_id
    and fwarehouseid=warehouse_id
    )
  select amount/qty into res_price from first_price; 
  IF p_currency='e0c5c474-00fd-1000-e000-3d59c0a8100dDEB58FDC' or p_currency='qkWZc7UgRyKjdFeU9r8gct61j9w=' THEN
  select exg_rate*res_price into res_price  from WFZ_EXG_RATE where source_currency=p_currency;
  END IF ;
  return res_price;
  EXCEPTION 
   when OTHERS THEN
   return NULL;
 end;
