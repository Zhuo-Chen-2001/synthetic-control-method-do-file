//////******do-switches******//////
//////*（1表示开  0表示关）*//////
local A     0 //安装synth和mat2txt命令
local B     1 //前期检查
local C     1 //合成控制法主步骤
local D     1 //安慰剂检验1：保留所有州的安慰剂检验
local E     0 //安慰剂检验2：删除RMSPE两倍于Califonia的州的安慰剂检验
local F     1 //安慰剂检验3：画出直方图（39个州原始情况）

if `A' == 1 {
ssc install synth
ssc install mat2txt
}

if `B' == 1 {
//////******前期检查******//////
*California和美国其它地区的香烟销售情况对比描述图
use "C:\Users\17775\Desktop\合成控制法-原理\SCM的数据与软件实现\smoking.dta",clear //（打开smoking.dta所在位置）
collapse (mean) cigsale, by(year state)
gen str2 state_str = string(state)
gen is_california = (state_str == "California")
egen total_cigsale = total(cigsale) if !is_california, by(year)
egen mean_cigsale = mean(cigsale) if !is_california, by(year)
replace cigsale = mean_cigsale if state_str == "1"
xtset state year
// 绘制 California和rest of the U.S.的cigsale 随年份的 xtline图，并叠加显示
xtline cigsale if state_str == "3" | state_str == "1", overlay xtitle("year") ytitle("per-capita cigarette sales(in packs)") legend(label(1 "Rest of the U.S.") label(2 "California"))
graph save "C:\Users\17775\Desktop\合成控制法-原理\SCM的数据与软件实现\Trens in per-capita cigarette sales_California vs the rest of the United states.gph", replace //（打开Trens in per-capita cigarette sales_California vs the rest of the United states.gph所在位置）
}

if `C' == 1 {
//////******合成控制法******//////
*步骤一：合成California与真实California对比
use "C:\Users\17775\Desktop\合成控制法-原理\SCM的数据与软件实现\smoking.dta",clear //（打开smoking.dta所在位置）
xtset state year
synth cigsale ///
		retprice lnincome age15to24 beer ///
		cigsale(1975) cigsale(1980) cigsale(1988) ///
		, ///
		trunit(3) trperiod(1989) ///
		xperiod(1980(1)1988) mspeperiod(1980(1)1988) resultperoid(1980(1)2000) ///
		keep("C:\Users\17775\Desktop\合成控制法-原理\smoking_synth.dta")replace fig //（保存smoking_synth.dta所在位置）
mat list e(V_matrix)
graph save Graph "C:\Users\17775\Desktop\合成控制法-原理\Trends in cigsale_California vs. synthetic California.gph", replace  //（保存Trends in cigsale_California vs. synthetic California.gph所在位置）


*步骤二：计算真实值与合成值之差
use "C:\Users\17775\Desktop\合成控制法-原理\SCM的数据与软件实现\smoking_synth.dta", clear //（打开smoking_synth.dta所在位置）
gen effect= _Y_treated - _Y_synthetic
sort _time
label variable _time "year"
label variable effect "gap in per-capita cigarette sales (in packs)"
line effect _time, xline(1989,lp(dash)) yline(0,lp(dash))
save "C:\Users\17775\Desktop\合成控制法-原理\smoking_synth_California.dta", replace  //（保存smoking_synth_California.dta所在位置）
graph save Graph "C:\Users\17775\Desktop\合成控制法-原理\cigsale gap between California and synthetic California.gph", replace //（保存cigsale gap between California and synthetic California.gph所在位置）
}


if `D' == 1 {
*步骤三：安慰剂检验
********************************************************************************
**安慰剂检验1：保留所有州的安慰剂检验
use "C:\Users\17775\Desktop\合成控制法-原理\smoking.dta",clear //（打开smoking.dta所在位置）
xtset state year

***（1）对每一个州进行合成控制估计
forval i=1/39{
qui synth cigsale retprice lnincome age15to24 beer cigsale(1975) cigsale(1980) cigsale(1988),trunit(`i') trperiod(1989) xperiod(1980(1) 1988) keep("C:\Users\17775\Desktop\合成控制法-原理\smoking_synth_`i'",replace) //（保存smoking_synth_`i'.dta所在位置）
}

forval i=1/39{
use "C:\Users\17775\Desktop\合成控制法-原理\smoking_synth_`i'", clear //（打开smoking_synth_`i'.dta所在位置）
rename _time years
gen tr_effect_`i' = _Y_treated - _Y_synthetic
keep years tr_effect_`i'
drop if missing(years)
save "C:\Users\17775\Desktop\合成控制法-原理\smoking_synth_`i'", replace //（保存smoking_synth_`i'.dta所在位置）
}

***（2）匹配到一张表
use "C:\Users\17775\Desktop\合成控制法-原理\smoking_synth_1", clear //（打开smoking_synth_1.dta所在位置）
forval i=2/39{
qui merge 1:1 years using "C:\Users\17775\Desktop\合成控制法-原理\smoking_synth_`i'", nogenerate //（打开smoking_synth_`i'.dta所在位置）
}

***（3）处理效应图
local lp1
forval i=1/2 {
   local lp1 `lp1' line tr_effect_`i' years, lpattern(dash) lcolor(gs12) ||
}
local lp2
forval i=4/39 {
   local lp2 `lp2' line tr_effect_`i' years, lpattern(dash) lcolor(gs12) ||
}
twoway `lp1' `lp2' || line tr_effect_3 years, ///
lcolor(black) legend(off) xline(1989, lpattern(dash)) yline(0,lp(dash))
graph save Graph "C:\Users\17775\Desktop\合成控制法-原理\cigsale gaps in California and placebos in 38 control states.gph" , replace //（保存cigsale gaps in California and placebos in 38 control states.gph所在位置）
}

if `E' == 1 {
********************************************************************************
**安慰剂检验2：删除RMSPE两倍于Califonia的州的安慰剂检验
use "C:\Users\17775\Desktop\合成控制法-原理\smoking.dta",clear //（打开smoking.dta所在位置）
xtset state year

***（1）对每一个州进行合成控制估计
tempname resmat
  forval i=1/39{
  qui synth cigsale retprice lnincome age15to24 beer cigsale(1975) cigsale(1980) cigsale(1988),trunit(`i') trperiod(1989) xperiod(1980(1) 1988) keep("C:\Users\17775\Desktop\合成控制法-原理\smoking_synth_`i'",replace)  //（保存smoking_synth_`i'.dta所在位置）
  matrix `resmat' = nullmat(`resmat') \ e(RMSPE) //矩阵用来存放每个州进行合成控制的RMSPE值
  local names `"`names' `"`i'"'"'
  }
  mat colnames `resmat' = "RMSPE" //矩阵的列名为RMSPE
  mat rownames `resmat' = `names' //矩阵的行名为names
  matlist `resmat' , row("Treated Unit")

forval i=1/39{
use "C:\Users\17775\Desktop\合成控制法-原理\smoking_synth_`i'", clear //（打开smoking_synth_`i'.dta所在位置）
rename _time years
gen tr_effect_`i' = _Y_treated - _Y_synthetic
keep years tr_effect_`i'
drop if missing(years)
save "C:\Users\17775\Desktop\合成控制法-原理\smoking_synth_`i'", replace //（保存smoking_synth_`i'.dta所在位置）
}

***（2）匹配到一张表
use "C:\Users\17775\Desktop\合成控制法-原理\smoking_synth_1", clear //（打开smoking_synth_1.dta所在位置）
forval i=2/39{
qui merge 1:1 years using "C:\Users\17775\Desktop\合成控制法-原理\smoking_synth_`i'", nogenerate //（打开smoking_synth_`i'.dta所在位置）
}

***（3）删除拟合不好的州
drop tr_effect_6  //删除Delaware
drop tr_effect_13 //删除Kentucky
drop tr_effect_22 //删除New Hampshire
drop tr_effect_24 //删除North Carolina
drop tr_effect_29 //删除Rhode Island
drop tr_effect_34 //删除Utah
drop tr_effect_35 //删除Vermont
drop tr_effect_39 //删除Wyoming

***（4）处理效应图
local lp1
forval i=1/2 {
   local lp1 `lp1' line tr_effect_`i' years, lpattern(dash) lcolor(gs12) ||
}
local lp2
forval i=4/5 {
   local lp2 `lp2' line tr_effect_`i' years, lpattern(dash) lcolor(gs12) ||
}
local lp3
forval i=7/12 {
   local lp2 `lp2' line tr_effect_`i' years, lpattern(dash) lcolor(gs12) ||
}
local lp4
forval i=23/23 {
   local lp2 `lp2' line tr_effect_`i' years, lpattern(dash) lcolor(gs12) ||
}
local lp5
forval i=25/28 {
   local lp2 `lp2' line tr_effect_`i' years, lpattern(dash) lcolor(gs12) ||
}
local lp6
forval i=30/33 {
   local lp2 `lp2' line tr_effect_`i' years, lpattern(dash) lcolor(gs12) ||
}
local lp7
forval i=36/38 {
   local lp2 `lp2' line tr_effect_`i' years, lpattern(dash) lcolor(gs12) ||
}
twoway `lp1' `lp2' `lp3' `lp4' `lp5' `lp6' `lp7'|| line tr_effect_3 years, ///
lcolor(black) legend(off) xline(1989, lpattern(dash)) yline(0,lp(dash)) 
graph save "C:\Users\17775\Desktop\合成控制法-原理\cigsale gaps in California and placebos in 29 control states.gph",replace //（保存cigsale gaps in California and placebos in 29 control states.gph所在位置）
}

if `F' == 1 {
********************************************************************************
**安慰剂检验3：画出直方图（39个州原始情况）
use "C:\Users\17775\Desktop\合成控制法-原理\smoking.dta",clear //（打开smoking.dta所在位置）
xtset state year

***（1）对每一个州进行合成控制估计
tempname resmat
  forval i=1/39{
  qui synth cigsale retprice lnincome age15to24 beer cigsale(1975) cigsale(1980) cigsale(1988),trunit(`i') trperiod(1989) xperiod(1980(1) 1988) keep("C:\Users\17775\Desktop\合成控制法-原理\smoking_synth_`i'",replace)  //（保存smoking_synth_`i'.dta所在位置）
  matrix `resmat' = nullmat(`resmat') \ e(RMSPE) //（矩阵用来存放每个州进行合成控制的RMSPE值）
  local names `"`names' `"`i'"'"'
  }
  mat colnames `resmat' = "RMSPE" //矩阵的列名为RMSPE
  mat rownames `resmat' = `names' //矩阵的行名为names
  matlist `resmat' , row("Treated Unit")

forval i=1/39{
use "C:\Users\17775\Desktop\合成控制法-原理\smoking_synth_`i'", clear //（打开smoking_synth_`i'.dta所在位置）
rename _time years
gen tr_effect_`i' = _Y_treated - _Y_synthetic
keep years tr_effect_`i'
drop if missing(years)
save "C:\Users\17775\Desktop\合成控制法-原理\smoking_synth_`i'", replace //（保存smoking_synth_`i'.dta所在位置）
}

***（2）匹配到一张表
use "C:\Users\17775\Desktop\合成控制法-原理\smoking_synth_1", clear //（打开smoking_synth_1.dta所在位置）
forval i=2/39{
qui merge 1:1 years using "C:\Users\17775\Desktop\合成控制法-原理\smoking_synth_`i'", nogenerate //（打开smoking_synth_`i'.dta所在位置）
}

//*如需使用删除后的数据，只要需要将（1）（2）更换为安慰剂检验2：（1）（2）（3）*//

***（3）画出直方图
reshape long tr_effect_, i(year) j(state)
gen te2=tr_effect^2
bys state:egen ex_mspe=mean(te2) if year<1989
bys state:egen post_mspe=mean(te2) if year>=1989
bys state:egen a=min(ex_mspe)
bys state:egen b=min(post_mspe)
gen ratio=b/a
duplicates drop state,force
histogram ratio, bin(20) frequency fcolor(gs13) lcolor(black) ylabel(0(2)20) xtitle("post/pre-Proposition 99 MSPE") xlabel(0(20)120) ytitle("frequency")
graph save Graph "C:\Users\17775\Desktop\合成控制法-原理\post_pre-Proposition 99 MSPE.gph" , replace //（保存post_pre-Proposition 99 MSPE.gph所在位置）

//////******参考******//////
*Scott Cunningham_Casual Inference: mixtape中合成控制部分的编码
*知乎回答：合成控制法:Synthetic control.https://zhuanlan.zhihu.com/p/594463125.
*知乎回答：合成控制法（SCM）安慰剂检验怎么玩？.https://zhuanlan.zhihu.com/p/133744885.
*微信推文：从加州控烟案例学会合成控制法的Stata操作.https://mp.weixin.qq.com/s?__biz=MzU4ODU3NjM2MA==&mid=2247483729&idx=1&sn=eff312d71154eba415668da1823c4f27&chksm=fddbe256caac6b40be67cf610d86a56466004dca889304bf414f905f369816ae9cc6114c0eb6&scene=21#wechat_redirect.

**如果对此份do文档有任何建议，请赐教，电子邮箱是zhuoc1025@gmail.com。
}
