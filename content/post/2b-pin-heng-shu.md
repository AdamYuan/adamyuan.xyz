---
title: "二逼平衡树(splay / vector + 线段树)"
date: 2018-09-27T21:21:54+08:00
draft: false
tags: [ "树套树", "splay", "线段树" , "vector"]
categories: [ "OI" ]
---

# 题目概述
您需要写一种数据结构（可参考题目标题），来维护一个有序数列，其中需要提供以下操作：  
1. 查询k在区间内的排名  
2. 查询区间内排名为k的值  
3. 修改某一位值上的数值  
4. 查询k在区间内的前驱（前驱定义为严格小于x，且最大的数，若不存在输出-2147483647）  
5. 查询k在区间内的后继（后继定义为严格大于x，且最小的数，若不存在输出2147483647）  
<!--more-->

# 基本思路

这是一道树套树（线段树套平衡树）的模板题，下面讲解一下5个操作的写法：  
1. 分别查询区间对应的每个平衡树中k元素的排名，再相加  
2. 这个是最难想的，其实就是二分答案。。。可以线段树里再维护最大最小值加速二分  
3. 就是插入+删除  
4. 分别查询每颗平衡树中k的前驱，取最大  
5. 分别查询每颗平衡树中k的后继，取最小  

操作3的复杂度为 $$\log^3(n)$$，其它为 $$\log^2(n)$$

# 吐槽

这题竟然可以线段树套std::vector水过，然而splay却会TLE 3个点。。。

# 代码
## std::vector版（AC）

```cpp
#include <cstdio>
#include <algorithm>
#include <vector>

#define N 50005
#define MINV -2147483647
#define MAXV 2147483647

int arr[N];

inline int vec_query_rank(const std::vector<int> &vec, int x) { return std::lower_bound(vec.begin(), vec.end(), x) - vec.begin(); }
inline int vec_query_prev(const std::vector<int> &vec, int x) 
{
	std::vector<int>::const_iterator i = std::lower_bound(vec.begin(), vec.end(), x);
	if(i == vec.begin()) return MINV;
	return *(i-1);
}
inline int vec_query_next(const std::vector<int> &vec, int x) 
{
	std::vector<int>::const_iterator i = std::upper_bound(vec.begin(), vec.end(), x);
	if(i == vec.end()) return MAXV;
	return *i;
}
inline void vec_modify(std::vector<int> *vec, int newval, int oldval)
{
	vec->erase(std::lower_bound(vec->begin(), vec->end(), oldval));
	vec->insert(std::lower_bound(vec->begin(), vec->end(), newval), newval);
}

namespace seg
{
	struct Node
	{
		std::vector<int> vec;
		Node *lson, *rson;
		int l, r, rmin, rmax;
	};

	Node node_pool[N << 2], *segroot;

	inline Node *new_node() { static Node *p = node_pool; p->lson = p->rson = NULL; return p++; }

	inline void pushup(Node *node)
	{
		node->rmax = std::max(node->lson ? node->lson->rmax : MINV, node->rson ? node->rson->rmax : MINV);
		node->rmin = std::min(node->lson ? node->lson->rmin : MAXV, node->rson ? node->rson->rmin : MAXV);
	}
	int sort_tmp[N];
	Node *build_tree(int l, int r)
	{
		Node *current; int mid, sz;

		current = new_node();
		current->l = l; 
		current->r = r;

		if(l != r)
		{
			mid = (l + r) >> 1;
			current->lson = build_tree(l, mid);
			current->rson = build_tree(mid + 1, r);
			pushup(current);

			sz = r-l+1;

			//merge sort
			current->vec.resize(sz);
			std::merge(sort_tmp + l, sort_tmp + mid + 1, sort_tmp + mid + 1, sort_tmp + r + 1, current->vec.begin());
			std::copy(current->vec.begin(), current->vec.end(), sort_tmp + l);
		}
		else
		{
			sort_tmp[l] = arr[l];
			current->rmin = current->rmax = arr[l];

			//create vector with 1 element
			current->vec.push_back(arr[l]);
		}

		return current;
	}

	void query_bound(Node *node, int l, int r, int *rmin, int *rmax) //should first initialize rmin and rmax with MAXV and MINV
	{
		if(node->r < l || node->l > r) return;
		else if(l <= node->l && node->r <= r)
		{
			*rmin = std::min(*rmin, node->rmin);
			*rmax = std::max(*rmax, node->rmax);
		}
		else
		{
			query_bound(node->lson, l, r, rmin, rmax);
			query_bound(node->rson, l, r, rmin, rmax);
		}
	}

	int query_rank(Node *node, int l, int r, int x) //return number of value smaller than x
	{
		if(node->r < l || node->l > r) return 0;
		else if(l <= node->l && node->r <= r)
			return vec_query_rank(node->vec, x);
		else
			return query_rank(node->lson, l, r, x) + query_rank(node->rson, l, r, x);
	}

	int query_kth(int l, int r, int k) //k >= 1
	{
		static int rmin, rmax, low, high, mid, midrk;

		rmin = MAXV, rmax = MINV;
		query_bound(segroot, l, r, &rmin, &rmax);

		//binary search
		low = rmin; high = rmax;
		while(low != high)
		{
			mid = (low + high + 1) >> 1; 
			midrk = query_rank(segroot, l, r, mid) + 1;
			if(midrk <= k) low = mid;
			else high = mid - 1;
		}
		return low;
	}

	int query_prev(Node *node, int l, int r, int x) 
	{
		if(node->r < l || node->l > r) return MINV;
		else if(l <= node->l && node->r <= r)
			return vec_query_prev(node->vec, x);
		else
			return std::max(query_prev(node->lson, l, r, x), query_prev(node->rson, l, r, x));
	}

	int query_next(Node *node, int l, int r, int x) 
	{
		if(node->r < l || node->l > r) return MAXV;
		else if(l <= node->l && node->r <= r)
			return vec_query_next(node->vec, x);
		else
			return std::min(query_next(node->lson, l, r, x), query_next(node->rson, l, r, x));
	}

	void modify(Node *node, int pos, int x, int old)
	{
		vec_modify(&node->vec, x, old);

		if(node->l != node->r)
		{
			if(pos <= ((node->l + node->r) >> 1))
				modify(node->lson, pos, x, old);
			else modify(node->rson, pos, x, old);

			pushup(node);
		}
		else
			node->rmax = node->rmin = x;
	}
}

int main()
{
	int n, m;
	scanf("%d", &n); scanf("%d", &m);
	for(int i = 1; i <= n; ++i) scanf("%d", arr + i);
	seg::segroot = seg::build_tree(1, n);

	int opt, l, r, k, pos;
	while(m --)
	{
		scanf("%d", &opt);
		if(opt == 1)
		{
			scanf("%d%d%d", &l, &r, &k);
			printf("%d\n", seg::query_rank(seg::segroot, l, r, k) + 1);
		}
		else if(opt == 2)
		{
			scanf("%d%d%d", &l, &r, &k);
			printf("%d\n", seg::query_kth(l, r, k));
		}
		else if(opt == 3)
		{
			scanf("%d%d", &pos, &k);
			seg::modify(seg::segroot, pos, k, arr[pos]);
			arr[pos] = k;
		}
		else if(opt == 4)
		{
			scanf("%d%d%d", &l, &r, &k);
			printf("%d\n", seg::query_prev(seg::segroot, l, r, k));
		}
		else
		{
			scanf("%d%d%d", &l, &r, &k);
			printf("%d\n", seg::query_next(seg::segroot, l, r, k));
		}
	}

	return 0;
}
```

## splay版（TLE 70%）

```cpp
#include <cstdio>
#include <algorithm>

#define N 50005
#define MINV -2147483647
#define MAXV 2147483647

int arr[N];
namespace splay
{
	struct Node
	{
		Node *parent;
		union { struct {Node *lson, *rson; }; Node *son[2]; };
		int count, size, value;
	} node_pool[N << 7];

	inline Node *new_node() { static Node *p = node_pool; p->lson = p->rson = p->parent = NULL; return p++; }
	inline bool which_son(Node *node) { return node->parent->rson == node; }
	inline void pushup(Node *node)
	{
		node->size = node->count;
		if(node->lson) node->size += node->lson->size;
		if(node->rson) node->size += node->rson->size;
	}
	inline void rotate(Node **root, Node *node)
	{
		static bool a, b; static Node *mov, *fa, *gfa;
		fa = node->parent;
		a = which_son(node); b = !a;
		mov = node->son[b]; fa->son[a] = mov; if(mov) mov->parent = fa;

		gfa = fa->parent;
		(gfa ? gfa->son[which_son(fa)] : *root) = node; node->parent = gfa;

		node->son[b] = fa; fa->parent = node;

		pushup(fa); pushup(node);
	}
	inline void splay(Node **root, Node *node, Node *target)
	{
		static Node *fa, *gfa;
		while((fa = node->parent) != target)
		{
			gfa = fa->parent;
			if(gfa != target)
				rotate(root, which_son(node) == which_son(fa) ? fa : node);
			rotate(root, node);
		}
	}
	void print(Node *node)
	{
		if(!node) return;
		print(node->lson);
		printf("%d %d; ", node->value, node->count);
		print(node->rson);
	}
	inline Node *find(Node **root, int x)
	{
		static Node *current;
		current = *root;
		while(current && current->value != x)
			if(x < current->value) current = current->lson;
			else current = current->rson;
		if(current) splay(root, current, NULL);
		return current;
	}
	inline void find_target(Node **root, int x, Node ***target, Node **father) 
		//return pointer of node to be inserted and its parent
	{
		*target = root;
		while(**target)
		{
			*father = **target;
			if(x < (**target)->value) *target = &((**target)->lson);
			else *target = &((**target)->rson);
		}
	}
	inline Node *query_max(Node *root) //get max value in a tree
	{
		while(root->rson)
			root = root->rson;
		return root;
	}
	inline Node *query_min(Node *root) //get min value in a tree
	{
		while(root->lson)
			root = root->lson;
		return root;
	}
	inline Node *insert(Node **root, int x)
	{
		static Node *f;
		f = find(root, x);
		if(f) { f->count ++; f->size ++; }
		else
		{
			Node **target, *father;
			find_target(root, x, &target, &father);
			(*target) = new_node(); (*target)->value = x; 
			(*target)->count = (*target)->size = 1; (*target)->parent = father;
			splay(root, *target, NULL);
		}
		return *root;
	}
	inline void erase(Node **root, int x)
	{
		static Node *f, *m;
		f = find(root, x);
		if(!f) return;
		if(--f->count && --f->size) return;
		//f is the root now
		if(f->lson)
		{
			m = query_max(f->lson);
			splay(root, m, f);
			m->parent = NULL; 
			m->rson = f->rson; if(f->rson) { m->rson->size += f->rson->size; f->rson->parent = m; }
			*root = m;
		}
		else //left son is empty, let rson be the root
		{
			*root = (*root)->rson;
			(*root)->parent = NULL;
		}
	}
	inline int query_rank(Node **root, int x) //return number of value smaller than x
	{
		static bool exist;
		exist = find(root, x);
		if(!exist) insert(root, x);
		int val = (*root)->lson ? (*root)->lson->size : 0;
		if(!exist) erase(root, x);
		return val;
	}
	inline int query_prev(Node **root, int x) //return the biggest value smaller than x
	{
		static bool exist;
		exist = find(root, x);
		if(!exist) insert(root, x); //the new node is the root
		int val = (*root)->lson ? query_max((*root)->lson)->value : MINV;
		if(!exist) erase(root, x); //the new node is the root
		return val;
	}
	inline int query_next(Node **root, int x)
	{
		static bool exist;
		exist = find(root, x);
		if(!exist) insert(root, x);
		int val = (*root)->rson ? query_min((*root)->rson)->value : MAXV;
		if(!exist) erase(root, x);
		return val;
	}
	Node *build_tree(int *value_arr, int *cnt_arr, Node *father, int l, int r)
	{
		if(l > r) return NULL;

		int mid = (l + r) >> 1;
		Node *current = new_node(); 
		current->parent = father;
		current->value = value_arr[mid];
		current->count = cnt_arr[mid];
		current->lson = build_tree(value_arr, cnt_arr, current, l, mid - 1);
		current->rson = build_tree(value_arr, cnt_arr, current, mid + 1, r);

		pushup(current);

		return current;
	}
}

namespace seg
{
	struct Node
	{
		splay::Node *root;
		Node *lson, *rson;
		int l, r, rmin, rmax;
	};

	Node node_pool[N << 2], *segroot;

	inline Node *new_node() { static Node *p = node_pool; p->lson = p->rson = NULL; return p++; }

	inline void pushup(Node *node)
	{
		node->rmax = std::max(node->lson ? node->lson->rmax : MINV, node->rson ? node->rson->rmax : MINV);
		node->rmin = std::min(node->lson ? node->lson->rmin : MAXV, node->rson ? node->rson->rmin : MAXV);
	}
	int sort_tmp[N], merge_tmp[N], cnt_tmp[N];
	Node *build_tree(int l, int r)
	{
		Node *current; int mid, sz, total;

		current = new_node();
		current->l = l; 
		current->r = r;

		if(l != r)
		{
			mid = (l + r) >> 1;
			current->lson = build_tree(l, mid);
			current->rson = build_tree(mid + 1, r);
			pushup(current);

			sz = r-l+1;

			//merge sort
			std::merge(sort_tmp + l, sort_tmp + mid + 1, sort_tmp + mid + 1, sort_tmp + r + 1, merge_tmp + 1);
			std::copy(merge_tmp + 1, merge_tmp + sz+1, sort_tmp + l);

			total = 0;
			for(int i = 1; i <= sz; ++i) //make the array(for building tree) unique and get the count
				if(i == 1 || merge_tmp[i] != merge_tmp[i-1])
				{
					++total;
					merge_tmp[total] = merge_tmp[i];
					cnt_tmp[total] = 1;
				}
				else cnt_tmp[total] ++;

			//build balanced tree
			current->root = splay::build_tree(merge_tmp, cnt_tmp, NULL, 1, total);
		}
		else
		{
			sort_tmp[l] = arr[l];
			current->rmin = current->rmax = arr[l];

			//create tree with 1 element
			current->root = splay::new_node();
			current->root->value = arr[l];
			current->root->size = current->root->count = 1;
		}

		return current;
	}

	void query_bound(Node *node, int l, int r, int *rmin, int *rmax) //should first initialize rmin and rmax with MAXV and MINV
	{
		if(node->r < l || node->l > r) return;
		else if(l <= node->l && node->r <= r)
		{
			*rmin = std::min(*rmin, node->rmin);
			*rmax = std::max(*rmax, node->rmax);
		}
		else
		{
			query_bound(node->lson, l, r, rmin, rmax);
			query_bound(node->rson, l, r, rmin, rmax);
		}
	}

	int query_rank(Node *node, int l, int r, int x) //return number of value smaller than x
	{
		if(node->r < l || node->l > r) return 0;
		else if(l <= node->l && node->r <= r)
			return splay::query_rank(&node->root, x);
		else
			return query_rank(node->lson, l, r, x) + query_rank(node->rson, l, r, x);
	}

	int query_kth(int l, int r, int k) //k >= 1
	{
		static int rmin, rmax, low, high, mid, midrk;

		rmin = MAXV, rmax = MINV;
		query_bound(segroot, l, r, &rmin, &rmax);

		//binary search
		low = rmin; high = rmax;
		while(low != high)
		{
			mid = (low + high + 1) >> 1; 
			midrk = query_rank(segroot, l, r, mid) + 1;
			if(midrk <= k) low = mid;
			else high = mid - 1;
		}
		return low;
	}

	int query_prev(Node *node, int l, int r, int x) 
	{
		if(node->r < l || node->l > r) return MINV;
		else if(l <= node->l && node->r <= r)
			return splay::query_prev(&node->root, x);
		else
			return std::max(query_prev(node->lson, l, r, x), query_prev(node->rson, l, r, x));
	}

	int query_next(Node *node, int l, int r, int x) 
	{
		if(node->r < l || node->l > r) return MAXV;
		else if(l <= node->l && node->r <= r)
			return splay::query_next(&node->root, x);
		else
			return std::min(query_next(node->lson, l, r, x), query_next(node->rson, l, r, x));
	}

	void modify(Node *node, int pos, int x, int old)
	{
		splay::insert(&node->root, x);
		splay::erase(&node->root, old);

		if(node->l != node->r)
		{
			if(pos <= ((node->l + node->r) >> 1))
				modify(node->lson, pos, x, old);
			else modify(node->rson, pos, x, old);

			pushup(node);
		}
		else
			node->rmax = node->rmin = x;
	}
}

int main()
{
	int n, m;
	scanf("%d", &n); scanf("%d", &m);
	for(int i = 1; i <= n; ++i) scanf("%d", arr + i);
	seg::segroot = seg::build_tree(1, n);

	int opt, l, r, k, pos;
	while(m --)
	{
		scanf("%d", &opt);
		if(opt == 1)
		{
			scanf("%d%d%d", &l, &r, &k);
			printf("%d\n", seg::query_rank(seg::segroot, l, r, k) + 1);
		}
		else if(opt == 2)
		{
			scanf("%d%d%d", &l, &r, &k);
			printf("%d\n", seg::query_kth(l, r, k));
		}
		else if(opt == 3)
		{
			scanf("%d%d", &pos, &k);
			seg::modify(seg::segroot, pos, k, arr[pos]);
			arr[pos] = k;
		}
		else if(opt == 4)
		{
			scanf("%d%d%d", &l, &r, &k);
			printf("%d\n", seg::query_prev(seg::segroot, l, r, k));
		}
		else
		{
			scanf("%d%d%d", &l, &r, &k);
			printf("%d\n", seg::query_next(seg::segroot, l, r, k));
		}
	}

	return 0;
}
```

## 无旋treap（TLE 70%）
```cpp
#include <cstdio>
#include <algorithm>
#include <random>

#define N 50005
#define MINV -2147483647
#define MAXV 2147483647

int arr[N];

namespace treap
{
	struct Node
	{
		union { struct {Node *lson, *rson; }; Node *son[2]; };
		int count, size, value, rndkey;
	} node_pool[N << 7];

	std::random_device rd{};
	std::mt19937 gen{rd()};
	inline Node *new_node() { static Node *p = node_pool; p->lson = p->rson = NULL; p->rndkey = gen(); return p++; }
	inline void maintain(Node *node)
	{
		node->size = node->count;
		if(node->lson) node->size += node->lson->size;
		if(node->rson) node->size += node->rson->size;
	}
	void print(Node *node)
	{
		if(!node) return;
		print(node->lson);
		printf("%d %d; ", node->value, node->count);
		print(node->rson);
	}
	Node *init()
	{
		Node *l = new_node(); l->size = l->count = 0; l->value = MINV;
		Node *r = new_node(); r->size = r->count = 0; r->value = MAXV;
		if(l->rndkey < r->rndkey) { l->rson = r; return l; } //keep l as root
		r->lson = l; return r;
	}
	Node *merge(Node *l, Node *r)
	{
		if(l == NULL) return r;
		if(r == NULL) return l;
		if(l->rndkey < r->rndkey) //keep l as root
		{
			l->rson = merge(l->rson, r);
			maintain(l); return l;
		}
		r->lson = merge(l, r->lson);
		maintain(r); return r;
	}
	void split(Node *root, int x, Node **l, Node **r)
	{
		if(root == NULL) { *l = *r = nullptr; return; }
		if(root->value < x)
		{
			*l = root;
			split(root->rson, x, &(root->rson), r);
		}
		else
		{
			*r = root;
			split(root->lson, x, l, &(root->lson));
		}
		maintain(root);
	}
	inline Node *find(Node *root, int x)
	{
		while(root && root->value != x)
			if(x < root->value) root = root->lson;
			else root = root->rson;
		return root;
	}
	void pushup_size(Node *root, int x, int plus) //ensure find(root, x)
	{
		root->size += plus;
		if(root->value != x)
		{
			if(x < root->value) pushup_size(root->lson, x, plus);
			else pushup_size(root->rson, x, plus);
		}
	}
	inline Node *query_max(Node *root) //get max value in a tree
	{
		while(root->rson)
			root = root->rson;
		return root;
	}
	inline Node *query_min(Node *root) //get min value in a tree
	{
		while(root->lson)
			root = root->lson;
		return root;
	}
	inline void insert(Node **root, int x) //return root
	{
		Node *f = find(*root, x);
		if(f)
		{
			f->count ++;
			pushup_size(*root, x, 1);
		}
		else
		{
			Node *l, *r;
			split(*root, x, &l, &r); //[MINV, x) and [x, MAXV]
			Node *ins = new_node();
			ins->count = ins->size = 1;
			ins->value = x;

			*root = merge(merge(l, ins), r);
		}
	}
	inline void erase(Node **root, int x)
	{
		Node *f = find(*root, x);
		f->count --;
		pushup_size(*root, x, -1);

		if(f->count) return;

		Node *l, *r, *rl, *rr;
		split(*root, x, &l, &r); //[MINV, x)
		split(r, x + 1, &rl, &rr);

		*root = merge(l, rr);
	}
	inline int query_rank(Node **root, int x) //return number of value smaller than x
	{
		static Node *l, *r;
		split(*root, x, &l, &r);
		int val = l->size;
		*root = merge(l, r);
		return val;
	}
	inline int query_prev(Node **root, int x) //return the biggest value smaller than x
	{
		static Node *l, *r;
		split(*root, x, &l, &r);
		int val = query_max(l)->value;
		*root = merge(l, r);
		return val;
	}
	inline int query_next(Node **root, int x)
	{
		static Node *l, *r;
		split(*root, x + 1, &l, &r);
		int val = query_min(r)->value;
		*root = merge(l, r);
		return val;
	}
}

namespace seg
{
	struct Node
	{
		treap::Node *root;
		Node *lson, *rson;
		int l, r, rmin, rmax;
	};

	Node node_pool[N << 2], *segroot;

	inline Node *new_node() { static Node *p = node_pool; p->lson = p->rson = NULL; return p++; }

	inline void pushup(Node *node)
	{
		node->rmax = std::max(node->lson ? node->lson->rmax : MINV, node->rson ? node->rson->rmax : MINV);
		node->rmin = std::min(node->lson ? node->lson->rmin : MAXV, node->rson ? node->rson->rmin : MAXV);
	}

	Node *build_empty_tree(int l, int r)
	{
		Node *current;

		current = new_node();
		current->l = l; 
		current->r = r;
		//create tree with 2 element (MAXV & MINV)
		current->root = treap::init();

		if(l != r)
		{
			int mid = (l + r) >> 1;
			current->lson = build_empty_tree(l, mid);
			current->rson = build_empty_tree(mid + 1, r);
			pushup(current);
		}
		else
			current->rmin = current->rmax = arr[l];

		return current;
	}

	inline void build_tree(int l, int r)
	{
		segroot = build_empty_tree(l, r);

		Node *current;
		for(int i = l; i <= r; ++i)
		{
			current = segroot;
			while(current)
			{
				treap::insert(&current->root, arr[i]);
				current = i <= ((current->l + current->r) >> 1) ? current->lson : current->rson;
			}
		}
	}

	void query_bound(Node *node, int l, int r, int *rmin, int *rmax) //should first initialize rmin and rmax with MAXV and MINV
	{
		if(node->r < l || node->l > r) return;
		else if(l <= node->l && node->r <= r)
		{
			*rmin = std::min(*rmin, node->rmin);
			*rmax = std::max(*rmax, node->rmax);
		}
		else
		{
			query_bound(node->lson, l, r, rmin, rmax);
			query_bound(node->rson, l, r, rmin, rmax);
		}
	}

	int query_rank(Node *node, int l, int r, int x) //return number of value smaller than x
	{
		if(node->r < l || node->l > r) return 0;
		else if(l <= node->l && node->r <= r)
			return treap::query_rank(&node->root, x);
		else
			return query_rank(node->lson, l, r, x) + query_rank(node->rson, l, r, x);
	}

	int query_kth(int l, int r, int k) //k >= 1
	{
		static int rmin, rmax, low, high, mid, midrk;

		rmin = MAXV, rmax = MINV;
		query_bound(segroot, l, r, &rmin, &rmax);

		//binary search
		low = rmin; high = rmax;
		while(low != high)
		{
			mid = (low + high + 1) >> 1; 
			midrk = query_rank(segroot, l, r, mid) + 1;
			if(midrk <= k) low = mid;
			else high = mid - 1;
		}
		return low;
	}

	int query_prev(Node *node, int l, int r, int x) 
	{
		if(node->r < l || node->l > r) return MINV;
		else if(l <= node->l && node->r <= r)
			return treap::query_prev(&node->root, x);
		else
			return std::max(query_prev(node->lson, l, r, x), query_prev(node->rson, l, r, x));
	}

	int query_next(Node *node, int l, int r, int x) 
	{
		if(node->r < l || node->l > r) return MAXV;
		else if(l <= node->l && node->r <= r)
			return treap::query_next(&node->root, x);
		else
			return std::min(query_next(node->lson, l, r, x), query_next(node->rson, l, r, x));
	}

	void modify(Node *node, int pos, int x, int old)
	{
		treap::insert(&node->root, x);
		treap::erase(&node->root, old);

		if(node->l != node->r)
		{
			if(pos <= ((node->l + node->r) >> 1))
				modify(node->lson, pos, x, old);
			else modify(node->rson, pos, x, old);

			pushup(node);
		}
		else
			node->rmax = node->rmin = x;
	}
}

int main()
{
	int n, m;
	scanf("%d", &n); scanf("%d", &m);
	for(int i = 1; i <= n; ++i) scanf("%d", arr + i);
	seg::build_tree(1, n);

	int opt, l, r, k, pos;
	while(m --)
	{
		scanf("%d", &opt);
		if(opt == 1)
		{
			scanf("%d%d%d", &l, &r, &k);
			printf("%d\n", seg::query_rank(seg::segroot, l, r, k) + 1);
		}
		else if(opt == 2)
		{
			scanf("%d%d%d", &l, &r, &k);
			printf("%d\n", seg::query_kth(l, r, k));
		}
		else if(opt == 3)
		{
			scanf("%d%d", &pos, &k);
			seg::modify(seg::segroot, pos, k, arr[pos]);
			arr[pos] = k;
		}
		else if(opt == 4)
		{
			scanf("%d%d%d", &l, &r, &k);
			printf("%d\n", seg::query_prev(seg::segroot, l, r, k));
		}
		else
		{
			scanf("%d%d%d", &l, &r, &k);
			printf("%d\n", seg::query_next(seg::segroot, l, r, k));
		}
	}

	return 0;
}
```

