---
layout: post
title: "趣味习题：获取最近一百年内的所有黑色星期五的日期"
description: "趣味习题：获取最近一百年内的所有黑色星期五的日期"
category: BashShell
tags: [date]
---
{% include JB/setup %}

今天是2012-07-13 星期五，所以刚好有了这么个想法，获取最近100年的所有黑色星期五的日子。
丢个砖：

	personball@vostro:SHELL$cat GetBlackFri.sh
	#!/bin/bash
	first="2012-07-13 00:00:00"
	tst=`date -d "$first" "+%s"`
	for i in {1..5200}
	do
	    let "tst=tst-86400*7"
	    str=` date -d "@$tst" `
	    if [[ "$str" =~ " 13 " ]]
	    then
	        echo $str
	    fi
	done
	personball@vostro:SHELL$./GetBlackFri.sh
	Fri Apr 13 00:00:00 CST 2012
	Fri Jan 13 00:00:00 CST 2012
	Fri May 13 00:00:00 CST 2011
	Fri Aug 13 00:00:00 CST 2010
	Fri Nov 13 00:00:00 CST 2009
	Fri Mar 13 00:00:00 CST 2009
	Fri Feb 13 00:00:00 CST 2009
	Fri Jun 13 00:00:00 CST 2008
	Fri Jul 13 00:00:00 CST 2007
	Fri Apr 13 00:00:00 CST 2007
	Fri Oct 13 00:00:00 CST 2006
	Fri Jan 13 00:00:00 CST 2006
	Fri May 13 00:00:00 CST 2005
	Fri Aug 13 00:00:00 CST 2004
	Fri Feb 13 00:00:00 CST 2004
	Fri Jun 13 00:00:00 CST 2003
	Fri Dec 13 00:00:00 CST 2002
	Fri Sep 13 00:00:00 CST 2002
	Fri Jul 13 00:00:00 CST 2001
	Fri Apr 13 00:00:00 CST 2001
	Fri Oct 13 00:00:00 CST 2000
	Fri Aug 13 00:00:00 CST 1999
	Fri Nov 13 00:00:00 CST 1998
	Fri Mar 13 00:00:00 CST 1998
	Fri Feb 13 00:00:00 CST 1998
	Fri Jun 13 00:00:00 CST 1997
	Fri Dec 13 00:00:00 CST 1996
	Fri Sep 13 00:00:00 CST 1996
	Fri Oct 13 00:00:00 CST 1995
	Fri Jan 13 00:00:00 CST 1995
	Fri May 13 00:00:00 CST 1994
	Fri Aug 13 00:00:00 CST 1993
	Fri Nov 13 00:00:00 CST 1992
	Fri Mar 13 00:00:00 CST 1992
	Fri Dec 13 00:00:00 CST 1991
	Fri Sep 13 01:00:00 CDT 1991
	Fri Jul 13 01:00:00 CDT 1990
	Fri Apr 13 00:00:00 CST 1990
	Fri Oct 13 00:00:00 CST 1989
	Fri Jan 13 00:00:00 CST 1989
	Fri May 13 01:00:00 CDT 1988
	Fri Nov 13 00:00:00 CST 1987
	Fri Mar 13 00:00:00 CST 1987
	Fri Feb 13 00:00:00 CST 1987
	Fri Jun 13 01:00:00 CDT 1986
	Fri Dec 13 00:00:00 CST 1985
	Fri Sep 13 00:00:00 CST 1985
	Fri Jul 13 00:00:00 CST 1984
	Fri Apr 13 00:00:00 CST 1984
	Fri Jan 13 00:00:00 CST 1984
	Fri May 13 00:00:00 CST 1983
	Fri Aug 13 00:00:00 CST 1982
	Fri Nov 13 00:00:00 CST 1981
	Fri Mar 13 00:00:00 CST 1981
	Fri Feb 13 00:00:00 CST 1981
	Fri Jun 13 00:00:00 CST 1980
	Fri Jul 13 00:00:00 CST 1979
	Fri Apr 13 00:00:00 CST 1979
	Fri Oct 13 00:00:00 CST 1978
	Fri Jan 13 00:00:00 CST 1978
	Fri May 13 00:00:00 CST 1977
	Fri Aug 13 00:00:00 CST 1976
	Fri Feb 13 00:00:00 CST 1976
	Fri Jun 13 00:00:00 CST 1975
	Fri Dec 13 00:00:00 CST 1974
	Fri Sep 13 00:00:00 CST 1974
	Fri Jul 13 00:00:00 CST 1973
	Fri Apr 13 00:00:00 CST 1973
	Fri Oct 13 00:00:00 CST 1972
	Fri Aug 13 00:00:00 CST 1971
	Fri Nov 13 00:00:00 CST 1970
	Fri Mar 13 00:00:00 CST 1970
	Fri Feb 13 00:00:00 CST 1970
	Fri Jun 13 00:00:00 CST 1969
	Fri Dec 13 00:00:00 CST 1968
	Fri Sep 13 00:00:00 CST 1968
	Fri Oct 13 00:00:00 CST 1967
	Fri Jan 13 00:00:00 CST 1967
	Fri May 13 00:00:00 CST 1966
	Fri Aug 13 00:00:00 CST 1965
	Fri Nov 13 00:00:00 CST 1964
	Fri Mar 13 00:00:00 CST 1964
	Fri Dec 13 00:00:00 CST 1963
	Fri Sep 13 00:00:00 CST 1963
	Fri Jul 13 00:00:00 CST 1962
	Fri Apr 13 00:00:00 CST 1962
	Fri Oct 13 00:00:00 CST 1961
	Fri Jan 13 00:00:00 CST 1961
	Fri May 13 00:00:00 CST 1960
	Fri Nov 13 00:00:00 CST 1959
	Fri Mar 13 00:00:00 CST 1959
	Fri Feb 13 00:00:00 CST 1959
	Fri Jun 13 00:00:00 CST 1958
	Fri Dec 13 00:00:00 CST 1957
	Fri Sep 13 00:00:00 CST 1957
	Fri Jul 13 00:00:00 CST 1956
	Fri Apr 13 00:00:00 CST 1956
	Fri Jan 13 00:00:00 CST 1956
	Fri May 13 00:00:00 CST 1955
	Fri Aug 13 00:00:00 CST 1954
	Fri Nov 13 00:00:00 CST 1953
	Fri Mar 13 00:00:00 CST 1953
	Fri Feb 13 00:00:00 CST 1953
	Fri Jun 13 00:00:00 CST 1952
	Fri Jul 13 00:00:00 CST 1951
	Fri Apr 13 00:00:00 CST 1951
	Fri Oct 13 00:00:00 CST 1950
	Fri Jan 13 00:00:00 CST 1950
	Fri May 13 00:00:00 CST 1949
	Fri Aug 13 00:00:00 CST 1948
	Fri Feb 13 00:00:00 CST 1948
	Fri Jun 13 00:00:00 CST 1947
	Fri Dec 13 00:00:00 CST 1946
	Fri Sep 13 00:00:00 CST 1946
	Fri Jul 13 00:00:00 CST 1945
	Fri Apr 13 00:00:00 CST 1945
	Fri Oct 13 00:00:00 CST 1944
	Fri Aug 13 00:00:00 CST 1943
	Fri Nov 13 00:00:00 CST 1942
	Fri Mar 13 00:00:00 CST 1942
	Fri Feb 13 00:00:00 CST 1942
	Fri Jun 13 01:00:00 CDT 1941
	Fri Dec 13 00:00:00 CST 1940
	Fri Sep 13 01:00:00 CDT 1940
	Fri Oct 13 00:00:00 CST 1939
	Fri Jan 13 00:00:00 CST 1939
	Fri May 13 00:00:00 CST 1938
	Fri Aug 13 00:00:00 CST 1937
	Fri Nov 13 00:00:00 CST 1936
	Fri Mar 13 00:00:00 CST 1936
	Fri Dec 13 00:00:00 CST 1935
	Fri Sep 13 00:00:00 CST 1935
	Fri Jul 13 00:00:00 CST 1934
	Fri Apr 13 00:00:00 CST 1934
	Fri Oct 13 00:00:00 CST 1933
	Fri Jan 13 00:00:00 CST 1933
	Fri May 13 00:00:00 CST 1932
	Fri Nov 13 00:00:00 CST 1931
	Fri Mar 13 00:00:00 CST 1931
	Fri Feb 13 00:00:00 CST 1931
	Fri Jun 13 00:00:00 CST 1930
	Fri Dec 13 00:00:00 CST 1929
	Fri Sep 13 00:00:00 CST 1929
	Fri Jul 13 00:00:00 CST 1928
	Fri Apr 13 00:00:00 CST 1928
	Fri Jan 13 00:00:00 CST 1928
	Fri May 13 00:05:52 LMT 1927
	Fri Aug 13 00:05:52 LMT 1926
	Fri Nov 13 00:05:52 LMT 1925
	Fri Mar 13 00:05:52 LMT 1925
	Fri Feb 13 00:05:52 LMT 1925
	Fri Jun 13 00:05:52 LMT 1924
	Fri Jul 13 00:05:52 LMT 1923
	Fri Apr 13 00:05:52 LMT 1923
	Fri Oct 13 00:05:52 LMT 1922
	Fri Jan 13 00:05:52 LMT 1922
	Fri May 13 00:05:52 LMT 1921
	Fri Aug 13 00:05:52 LMT 1920
	Fri Feb 13 00:05:52 LMT 1920
	Fri Jun 13 00:05:52 LMT 1919
	Fri Dec 13 00:05:52 LMT 1918
	Fri Sep 13 00:05:52 LMT 1918
	Fri Jul 13 00:05:52 LMT 1917
	Fri Apr 13 00:05:52 LMT 1917
	Fri Oct 13 00:05:52 LMT 1916
	Fri Aug 13 00:05:52 LMT 1915
	Fri Nov 13 00:05:52 LMT 1914
	Fri Mar 13 00:05:52 LMT 1914
	Fri Feb 13 00:05:52 LMT 1914
	Fri Jun 13 00:05:52 LMT 1913
	Fri Dec 13 00:05:52 LMT 1912

有没注意到输出中有几个异常时间点？  
注意初始值是从今天0点0分0秒开始算的，每次循环减去7天的秒数。  
出现了以下几个时间点：

	Fri Sep 13 01:00:00 CDT 1991
	Fri Jul 13 01:00:00 CDT 1990
	Fri May 13 01:00:00 CDT 1988
	Fri Jun 13 01:00:00 CDT 1986
	Fri Jun 13 01:00:00 CDT 1941
	Fri Sep 13 01:00:00 CDT 1940
	Fri May 13 00:05:52 LMT 1927
	Fri Aug 13 00:05:52 LMT 1926
	Fri Nov 13 00:05:52 LMT 1925
	Fri Mar 13 00:05:52 LMT 1925
	Fri Feb 13 00:05:52 LMT 1925
	Fri Jun 13 00:05:52 LMT 1924
	Fri Jul 13 00:05:52 LMT 1923
	Fri Apr 13 00:05:52 LMT 1923
	Fri Oct 13 00:05:52 LMT 1922
	Fri Jan 13 00:05:52 LMT 1922
	Fri May 13 00:05:52 LMT 1921
	Fri Aug 13 00:05:52 LMT 1920
	Fri Feb 13 00:05:52 LMT 1920
	Fri Jun 13 00:05:52 LMT 1919
	Fri Dec 13 00:05:52 LMT 1918
	Fri Sep 13 00:05:52 LMT 1918
	Fri Jul 13 00:05:52 LMT 1917
	Fri Apr 13 00:05:52 LMT 1917
	Fri Oct 13 00:05:52 LMT 1916
	Fri Aug 13 00:05:52 LMT 1915
	Fri Nov 13 00:05:52 LMT 1914
	Fri Mar 13 00:05:52 LMT 1914
	Fri Feb 13 00:05:52 LMT 1914
	Fri Jun 13 00:05:52 LMT 1913
	Fri Dec 13 00:05:52 LMT 1912

>百度百科  
>CST  
>
>	CST同时代表了下面4个时区：
>	CST：Central Standard Time (USA) 中部标准时间(美国) UTC -6:00
>	CST：Central Standard Time (Australia) 中部标准时间(澳大利亚) UTC 9:30
>	CST：China Standard Time 中国标准时间(北京时间) UTC 8:00
>	CST： Cuba Standard Time 古巴标准时间 UTC -4:00
>
>**注：UTC：协调世界时，又称世界标准时间或世界协调时间，简称UTC，从英文“Coordinated Universal Time” 称为世界统一时间。**
>
>同时还有相关：
>
>	EDT - Eastern Daylight Time 东部夏令时间
>
>CDT
>
>	CDT - Central Daylight Time 中部夏令时间
>
>LMT
>
>	LMT（local mean time）地方平时
>	LMT又称地方时。平太阳中心经过测者子圈后所经历的时间。因地方平时是从平太阳中心经过测者子圈起算的，在同一时刻不同经线上的地方平时不相等。故地方平时在日常生活中使用不便，只适用于天文测量等方面。
>


