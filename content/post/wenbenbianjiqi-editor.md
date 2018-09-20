---
title: "文本编辑器editor(splay)"
date: 2018-09-20T21:26:53+08:00
draft: true
tags: [ "oi" ]
---

# 题目概述
实现一个文本编辑器，实现下列功能：
![img1](/img/wenbenbianjiqi-editor/1.gif)  
例子：  
![img1](/img/wenbenbianjiqi-editor/2.gif)  

# 基本思路
（pos代表光标位置）
这题的思路十分简单粗暴，其中基本的操作是通过伸展树的splay操作得到代表一个区间的子树，对于区间[l, r]，将第l-1号节点splay成为根节点，将第r+1号节点splay成为根节点的右儿子，则根节点右儿子的左子树便是所需的子树。  
对于插入操作，可以先处理出[pos+1, pos]这个空区间（l-1 = pos, r+1 = pos+1），根节点右儿子的左子树必然为空，将其初始化为新字符串即可。  
对于删除和旋转操作，都需处理出[pos+1, pos+n]。删除操作可直接删除相应子树，旋转操作打上延迟标记然后pushdown。  

# 实现思路
先建立两个节点，可以避免针对空节点的特判。  
在查找操作时注意pushdown旋转标记，区间操作完成后注意pushup节点的size值。  

# 代码
```cpp
#include <cstdio>
#include <iostream>
#include <cstdlib>

#define N 2097157 //2*1024*1024

struct Node
{
	Node *fa;
	union { struct { Node *lson, *rson; }; Node *son[2]; };
	char value; int size; bool rev;
} node_pool[N], *root = NULL;

char buffer[N], cmd[10];

inline Node *new_node() 
{ 
	static Node *p = node_pool; 
	p->value = p->rev = 0; p->size = 1;
	p->lson = p->rson = p->fa = NULL;
	return p++; 
}

inline bool which_son(Node *node)
{
	return node->fa->son[1] == node;
}

inline void pushup(Node *node)
{
	node->size = 1;
	if(node->lson) node->size += node->lson->size;
	if(node->rson) node->size += node->rson->size;
}
inline void pushdown(Node *node)
{
	if(node->rev)
	{
		node->rev = 0;
		if(node->lson) node->lson->rev ^= 1;
		if(node->rson) node->rson->rev ^= 1;
		std::swap(node->lson, node->rson);
	}
}

inline void rotate_up(Node *node)
{
	Node *fa = node->fa;
	bool a = which_son(node), b = !a;

	Node *mov = node->son[b];
	fa->son[a] = mov; if(mov) mov->fa = fa;

	Node *gfa = fa->fa;
	(gfa ? gfa->son[which_son(fa)] : root) = node; node->fa = gfa;

	node->son[b] = fa; fa->fa = node;
	
	pushup(fa); pushup(node);
}

inline void splay(Node *node, Node *target) //rotate node as a son of target
{
	while(node->fa != target)
	{
		Node *fa = node->fa, *gfa = fa->fa;
		if(gfa != target)
		{
			if(which_son(node) == which_son(fa))
				rotate_up(fa);
			else rotate_up(node);
		}
		rotate_up(node);
	}
}

inline Node *find(int x)
{
	Node *current = root;
	while(true)
	{
		pushdown(current);

		int left_size = (current->lson ? current->lson->size : 0);
		if(x == left_size) break;

		if(x < left_size) current = current->lson;
		else { current = current->rson; x -= left_size + 1; }
	}
	return current;
}

Node *build_str_tree(const char *str, Node *father, int l, int r) //l >= 1
{
	if(l > r) return NULL;
	int mid = (l + r) >> 1;
	Node *current = new_node();
	current->fa = father;
	current->value = str[mid];
	current->lson = build_str_tree(str, current, l, mid - 1);
	current->rson = build_str_tree(str, current, mid + 1, r);
	pushup(current);

	return current;
}

inline void prepare_range(int pos, int len) //root->rson->lson is target
{
	static Node *prev, *next;
	prev = find(pos); next = find(pos + len + 1);
	splay(prev, NULL); splay(next, root);
}

int main()
{
	int t; scanf("%d", &t);

	int pos = 0, len;

	//init splay with two node
	root = new_node(); root->value = '\0'; root->size = 2;
	root->rson = new_node(); root->rson->value = '\0'; root->rson->fa = root;

	while(t--)
	{
		scanf("%s", cmd);
		if(*cmd == 'I') //insert
		{
			scanf("%d", &len);
			for(int i = 0/*ignore \n */; i <= len; ++i) buffer[i] = getchar();

			prepare_range(pos, 0);
			root->rson->lson = build_str_tree(buffer, root->rson, 1, len);
			root->rson->size += len; root->size += len;
		}
		else if(*cmd == 'D') //delete
		{
			scanf("%d", &len);
			prepare_range(pos, len);
			root->rson->lson = NULL;
			root->rson->size -= len; root->size -= len;
		}
		else if(*cmd == 'R') //rotate
		{
			scanf("%d", &len);
			prepare_range(pos, len);
			root->rson->lson->rev ^= 1;
		}
		else if(*cmd == 'M') //move
			scanf("%d", &pos);
		else if(*cmd == 'N') //next
			pos ++;
		else if(*cmd == 'P') //prev
			pos --;
		else if(*cmd == 'G') //get
		{
			putchar(find(pos+1)->value);
			putchar('\n');
		}
	}
	return 0;
}
```
