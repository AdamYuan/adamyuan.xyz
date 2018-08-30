---
title: "主席树求解静态区间第k大(poj2104)"
date: 2018-08-30T14:54:03+08:00
lastmod: 2018-08-30T14:54:03+08:00
draft: false
keywords: []
description: ""
tags: [ "oi" ]
categories: []
author: ""

# You can also close(false) or open(true) something for this content.
# P.S. comment can only be closed
comment: false
toc: false
autoCollapseToc: false
# You can also define another contentCopyright. e.g. contentCopyright: "This is another copyright."
contentCopyright: false
reward: false
mathjax: false
---

# 题目概述
给定一个数列(1 - 100000)，m次询问(1 - 5000)，每个询问包含l r k，输出区间[l...r]中第k大的数。

# 基本思路
首先我们将数列离散化。如果可以构造出任意区间的权值线段树(即线段树的下标代表区间中包含的数的值，例如数列1, 2, 2, 2, 3, 3, 4构成的权值线段树最下层为1, 3, 2, 1)，便能轻松二分出答案，同时区间[l...r]的权值线段树可以由区间[1...r]线段树中的直减去[1...l-1]得到，所以想到构造n颗前缀权值线段树。  
不过暴力建树空间复杂度太大，必然会mle，这时就需要用到主席树了。

# 主席树
主席树是一种可持久化数据结构(即可以获取所有历史版本)。由于线段树更新时只会使一条链上的值发生改变，于是可以直接新增一条链作为改动过后的版本，减小了空间开销，详细可见http://www.cnblogs.com/zyf0163/p/4749042.html1  
在这道题中，需要先建立一颗空的线段树(所有节点都为0)，然后将数列中的值一个接一个地添加到权值线段树中，理由主席树的特点便能轻松给出表示区间[1...i]的权值线段树。

# 代码
```cpp
#include <cstdio>
#include <algorithm>

#define N 100005

struct Node
{
	int value;
	Node *lson, *rson;
};

Node tree[N << 5];
Node *roots[N]; //所有前缀线段树的根节点

int arr[N], tmp[N];

inline Node *new_node() { static Node *t = tree; return t++; }

Node *build(int l, int r) //构建空树，返回根节点
{
	Node *current = new_node();
	current->value = 0;

	if(l != r)
	{
		int mid = (l + r) >> 1;
		current->lson = build(l, mid);
		current->rson = build(mid + 1, r);
	}

	return current;
}

Node *update(Node *node, int l, int r, int pos) //在pos处+1，返回更新后的根节点
{
	Node *current = new_node();
	current->value = node->value + 1;

	if(l != r)
	{
		int mid = (l + r) >> 1;
		if(pos <= mid)
		{
			current->lson = update(node->lson, l, mid, pos);
			current->rson = node->rson;
		}
		else
		{
			current->lson = node->lson;
			current->rson = update(node->rson, mid + 1, r, pos);
		}
	}

	return current;
}

int query(Node *l_node, Node *r_node, int l, int r, int k)
{
	if(l == r) return l;
	int mid = (l + r) >> 1, 
		l_sum = r_node->lson->value - l_node->lson->value; //把两颗前缀线段树的值相减得到区间线段树上的值

	if(k <= l_sum)
		return query(l_node->lson, r_node->lson, l, mid, k);
	return query(l_node->rson, r_node->rson, mid + 1, r, k - l_sum);
}

int main()
{
	int n, m;
	scanf("%d%d", &n, &m);
	for(int i = 1; i <= n; ++i)
		scanf("%d", arr + i);
	std::copy(arr + 1, arr + n + 1, tmp + 1);
	std::sort(tmp + 1, tmp + n + 1);

	int total = std::unique(tmp + 1, tmp + n + 1) - tmp - 1;
	roots[0] = build(1, total);

	for(int i = 1; i <= n; ++i)
	{
		arr[i] = std::lower_bound(tmp + 1, tmp + total + 1, arr[i]) - tmp; //离散化
		roots[i] = update(roots[i - 1], 1, total, arr[i]);
	}

	while(m --)
	{
		int l, r, k;
		scanf("%d%d%d", &l, &r, &k);
		printf("%d\n", tmp[query(roots[l - 1], roots[r], 1, total, k)]);
	}

	return 0;
}
```
