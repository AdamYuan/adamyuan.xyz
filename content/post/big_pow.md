---
title: "计算3的1000000次方"
date: 2018-12-02T11:39:34+08:00
lastmod: 2018-12-02T11:39:34+08:00
draft: false
tags: [ "NTT" ]
categories: [ "日常" ]
---

无意间看到 https://www.bilibili.com/video/av21610235 ，闲来无事，便自己实现了一个  
使用了快速幂和NTT，c++11，-O3优化，0.3秒内可得解

<!--more-->

# 结果

```sh
$ g++ big_pow.cpp -o big_pow -O3
$ time ./big_pow
1797710116675743838039851642017955175542668535689457592096701980448789887005555782  
5013639024539872345178584608400586756310173000789807647889087112071631584530925074  
20576700326354687989043195055426409953164756466539259367768040........  
9458386086558274361702868947585455272881631676228081179063417221095794868962238026  
6186186896939896900778464988674017800809943312017921778637005646990599302975876577  
7974690259456656823649987921344102043747756854291659736198742132526761094591717405  
35758464159433897468478655220000001
0.26user 0.00system 0:00.33elapsed 81%CPU (0avgtext+0avgdata 19452maxresident)k
0inputs+0outputs (0major+4219minor)pagefaults 0swaps
```

# 代码
```cpp
#include <iostream>

typedef long long i64;

constexpr i64 N = 1 << 19, K = 19, P = 998244353ll;

class NTT {
	private:
		static inline i64 qpow(i64 a, i64 x, i64 m) {
			i64 ret = 1;
			while(x) { if(x & 1) ret = (ret*a) % m; a = (a*a) % m; x >>= 1; }
			return ret;
		}
		static inline i64 to_pow2(i64 x) {
			i64 ret = 1; while(ret < x) ret <<= 1;
			return ret;
		}
		static inline i64 get_upper(i64 x) {
			i64 a = 1, ret = 0; while(a < x) { a <<= 1; ret ++; };
			return ret;
		}
		i64 m_wn[K+1], m_iwn[K+1], m_rev[N], m_inv, m_n = 0;
		inline void transform(i64 *a, const i64 *wn) const {
			for(i64 i = 0; i < m_n; ++i) if(i < m_rev[i]) std::swap(a[i], a[m_rev[i]]);

			for(i64 l = 1; (1 << l) <= m_n; l ++) {
				i64 m = 1 << (l-1);
				for(i64 *p = a; p != a + m_n; p += (1 << l)) {
					i64 w = 1;
					for(i64 i = 0; i < m; ++i) {
						i64 t = (w * p[m+i]) % P; p[m+i] = (p[i] - t + P) % P; p[i] = (p[i] + t) % P; w = (w * wn[l]) % P;
					}
				}
			}
		}

	public:
		inline void Init() {
			for(i64 l = 1; (1 << l) <= N; l ++) {
				m_wn[l] = qpow(3, (P - 1) / (1 << l), P);
				m_iwn[l] = qpow(3, P - 1 - (P - 1) / (1 << l), P);
			}
			m_rev[0] = 0; 
		}
		inline i64 SetN(i64 n) {
			n = to_pow2(n); if(n == m_n) return m_n;
			m_n = n;

			int k = get_upper(n);
			for(i64 i = 1; i < m_n; ++i) m_rev[i] = (m_rev[i>>1] >> 1) | ( (i&1) << (k - 1) );
			m_inv = qpow(m_n, P - 2, P);
			return m_n;
		}
		inline void Dft(i64 *a) const { transform(a, m_wn); }
		inline void Idft(i64 *a) const { transform(a, m_iwn); for(i64 i = 0; i < m_n; ++i) a[i] = (a[i] * m_inv) % P; }
} ntt;

i64 buffer[N];

class BigNum {
	private:
		i64 m_digits[N] = {}, m_up = 0;
	public:
		inline void Set(i64 val)
		{
			m_up = 0;
			while(val) {
				m_digits[m_up++] = val % 10;
				val /= 10;
			}
			std::fill(m_digits + m_up, m_digits + N, 0);
		}
		inline void Mul(const BigNum &bn) {
			std::copy(bn.m_digits, bn.m_digits + N, buffer);
			i64 kn = ntt.SetN(m_up + bn.m_up);
			ntt.Dft(m_digits); ntt.Dft(buffer);
			for(i64 i = 0; i < kn; ++i) m_digits[i] *= buffer[i];
			ntt.Idft(m_digits);
			for(i64 i = 0; i < kn - 1; ++i) { m_digits[i + 1] += m_digits[i] / 10; m_digits[i] %= 10; }
			for(m_up = kn; m_digits[m_up - 1] == 0; --m_up);
		}
		inline void Pow() {
			i64 kn = ntt.SetN(m_up * 2);
			ntt.Dft(m_digits);
			for(i64 i = 0; i < kn; ++i) m_digits[i] *= m_digits[i];
			ntt.Idft(m_digits);
			for(i64 i = 0; i < kn - 1; ++i) { m_digits[i + 1] += m_digits[i] / 10; m_digits[i] %= 10; }
			for(m_up = kn - 1; m_digits[m_up] == 0; --m_up);
			m_up ++;
		}
		inline void Print() const {
			for(i64 i = m_up - 1; i >= 0; --i)
				putchar(m_digits[i] + '0');
			putchar('\n');
		}
} base, ans;

int main() {
	ntt.Init();
	base.Set(3); ans.Set(1);
	i64 a = 1000000;
	while(a) {
		if(a & 1) ans.Mul(base);
		a >>= 1; base.Pow();
	}
	ans.Print();
	return 0;
}
```
