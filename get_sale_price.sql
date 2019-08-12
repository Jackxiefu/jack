create or replace function get_sale_price(p_sale in varchar2,p_currency in varchar2) return number
--更改应收单对应销售出库单上的单位成本
 is 
 res_price number(12,6); 
 --biz_date date;
 begin
-- select last_day(end_date) into biz_date  from dual;
 with first_price as (
-- select a.fbizdate,
--        b.FMATERIALID,
--        b.FWarehouseID,
--        b.FUNITACTUALCOST,
--        row_number() over(partition by b.FMATERIALID,b.FWarehouseID order by a.fbizdate desc) rk
-- from T_IM_SaleIssueBill@to_kd_test a
-- inner join T_IM_SaleIssueEntry@to_kd_test b on b.fparentid = a.fid
-- where a.fbizdate <= biz_date
-- and b.FMATERIALID=material_id
-- and b.FWarehouseID =warehouse_id
-- and a.FBASESTATUS='4'
 select 
  ckdfl.FUNITACTUALCOST
  FROM t_ar_otherbillentry@to_kd_test ysdfl
        LEFT JOIN ct_ska_statementofaccountentry@to_kd_test dzdfl ON ysdfl.fsourcebillentryid = dzdfl.fid
        LEFT JOIN t_im_saleissueentry@to_kd_test ckdfl
       -- INNER JOIN t_im_saleissuebill@to_kd_test cdk ON cdk.fid = ckdfl.fparentid 
        ON nvl(dzdfl.cfsourceentryid,ysdfl.fsourcebillentryid) = ckdfl.fid
    WHERE
      ysdfl.fid=p_sale
)
 select nvl(FUNITACTUALCOST,0) into res_price from first_price ;
 IF p_currency='e0c5c474-00fd-1000-e000-3d59c0a8100dDEB58FDC' or p_currency='qkWZc7UgRyKjdFeU9r8gct61j9w=' THEN
  select exg_rate*res_price into res_price  from WFZ_EXG_RATE where source_currency=p_currency;
  END IF ;
 return res_price;
 EXCEPTION 
   when OTHERS THEN
   return 0;
 end;
