---
title: "模拟退火求解3-SAT的C++程序实现"
date: 2019-06-15T16:04:16+08:00
draft: false
tags: [ "NP完全问题" ]
categories: [ "算法" ]
---

# 1. 问题概要与求解思路

## 1.1 3-SAT问题

对于一个形如$$(\overline{x_1} \lor x_2 \lor x_3) \land(x_3 \lor \overline{x_2} \lor \overline{x_4}) \land (x_1 \lor x_2 \lor x_5) \land ... \land (x_{10} \lor \overline{x_{12}} \lor x_{23})$$的布尔表达式。

<!--more-->

将布尔条件中一个形如$$(x_1 \lor \overline{x_2} \lor x_4)$$的表达式称为一个括号。对于3-SAT问题，每个括号中只能有3个元素。

定义布尔变量数量为$$N_{var}$$，括号数量为$$N_{clause}$$，3-SAT问题的一个解$$s = (x_1, x_2, ..., x_{N_{var}}), x_k\in\{0, 1\}$$ 

3-SAT问题即求解一个$$s$$使布尔表达式为真。这是一个NP完全问题，作为Schaefer's dichotomy定理的一个特例被Thomas Jerome Schaefer证明。

## 1.2 模拟退火

模拟退火是一个用于求解函数全局最大值的随机算法。与寻常的爬山法不同，模拟退火算法会在邻域内选取一个随机解，是否跳往随机解取决于温度和相对原解的函数值增加量。温度高时，跳转的随机程度大，温度降低后则大概率会跳向邻域内的最优，从而趋向局部最优。这种随机性使算法能够跳出局部最优，更可能寻找到全局最优。

```c++
Solution SimulatedAnnealing(Solution s0)
{
	Solution s = s0; //s表示当前解，s0为其初始值
	double T = MAX_TEMP; //T为温度
	while (T > MIN_TEMP)
	{
		T = UpdateTemp(T); //更新(减小)温度
		Solution s_new = s.RandomNeighbour(); //从当前解邻域随机选取一个解
		if ( P( Func(s), Func(s_new), T ) > Random(0, 1)) //P()计算接受随机解的概率
			s = s_new;
	}
	return s;
}
```

## 1.3 SASAT算法

本文使用了**SASAT**算法(**William M. Spears, Simulated Annealing for Hard Satisfiability Problems**)。

定义一个3-SAT解的价值$$SAT(s)$$为其能够满足的括号数量，显然若$$SAT(s) = N_{clause}$$，$$s$$则满足了布尔表达式。

对于一个解$$s$$，定义$$Flip(s, n) = (x_1, x_2, ...,\overline{x_n},...,x_{N_{var}})$$，变换得到的新解构成$$s$$的邻域。

SASAT算法会进行多次模拟退火的尝试，若一次失败，下一次尝试温度下降速率将会变慢，这会降低程序的运行速度，但会增大寻找到满足布尔表达式的解的概率。

```c++
Solution Try(int try_id)
{
	Solution s = RandomSolution(); //随机初始化解
	double T = MAX_TEMP;
	double D = N_VAR * try_id; //D决定了温度的下降速率
	int step = 0;
	while(T > MIN_TEMP)
	{
		if(SAT(s) == N_CLAUSE) break;
		step ++;
		T = UpdateTemp(step, D);
		
		for(int i = 1; i <= N_VAR; ++i)
		{
			if ( P(s, Flip(s, n), T) > Random(0, 1)) //P()计算接受随机解的概率
				s = Flip(s, n);
		}
	}
	return s;
}
Solution SASAT()
{
	int try_id = 0;
	while(true)
	{
		try_id ++;
		Solution s = Try(try_id);
		if(SAT(s) == N_CLAUSE) return s;
	}
}
```

其中$$UpdateTemp(step, D) = {MAX\_TEMP}\cdot e^{{-step} \over D}$$，$$P(s, s_{flip}, T) = ({1 + e^{{SAT(s) - SAT(s_{flip})} \over T} })^{-1}$$

本文侧重于程序的实现，对SASAT算法不继续深究。

#  2. C++程序实现与优化

(正式进入c++模式)

## 2.1 优化SAT(s)

### 2.1.1 Naive

SASAT算法的高效执行主要取决于$$SAT(s)$$的运行效率，在$$N_{clause} = 1065$$时，若直接暴力枚举每个括号进行计算，无疑会使运行效率极为低下。$$Flip(s, n)$$在计算机中仅为简单的布尔运算，不会产生这个问题。

暴力枚举的$$SAT(s)$$如下

```c++
struct ElementPair { int var_index; bool nagative; };
struct Clause { int clause_index; ElementPair elements[3]; };

Clause clauses[MAX_CLAUSE_NUM];//所有的括号

class Solution
{
	bool var_value[MAX_VAR_NUM]; //解中每个变量的取值
	int satisfied_cnt; //即SAT(s)
	
	//以下的函数默认为Solution类的成员函数，即省去了s参数
	void Flip(int n)
	{
		var_value[n] = !var_value[n];
	}
	bool ClauseSAT(const Clause &c)
	{
		for(int i = 0; i < 3; ++i)
			if(c.element[i].nagative != var_value[ c.element[i].var_index ]) //nagative表示括号中元素对变量取反，var_value为解中各变量的值
				return true;
		return false;
	}
	int SAT()
	{
		satisfied_cnt = 0;
		for(const Clause &c : clauses)
			if(ClauseSAT(c)) ++satisfied_cnt;
		return satisfied_cnt;
	}
}
```

### 2.1.2 在Flip函数中计算SAT(s)增减

通过观察1.2中的伪代码，我们注意到Try函数中s的变换全部通过Flip完成，一个直观的优化是在Flip时统计SAT(s)的增减。

为此我们为每个变量建立一个名为**related_clauses_vec**的列表(std::vector)，记录包含这个变量的括号，当Flip一个变量时，只需要更新列表中的括号便能计算出**SAT(s)**。(需要事先记录每个括号是否满足才能如此更新，称每个括号的满足情况为**clause_value**)

但是直接在Flip中更新SAT(s)也有其问题，若是此变量最终没有被Flip，还得重新把这个变量Flip回来。因此，我们新增两个函数**TestFlip(s, n)**和**ApplyFlip(s)**。**TestFlip(s, n)**在单独的环境中执行修改，记录修改的信息，返回修改后的**SAT(s)**。**ApplyFlip(s)**则将**TestFlip(s, n)**所得的信息覆盖到原来s的信息(**clause_var**, SAT(s), etc..)

进一步优化，对于单个变量，其**related_clauses_vec**可以分为"在括号其中不取反的(**related_clauses_vec[0]**)"和"在括号其中取反的(**related_clauses_vec[1]**)"两个列表。假设变量从0 Flip成1，**related_clauses_vec[0]**中的括号的值可以直接设为1，而**related_clauses_vec[1]**中的括号则需要调用ClauseSAT进行更新。

```c++
struct ElementPair { int var_index; bool nagative; };
struct Clause { int clause_index; ElementPair elements[3]; };

Clause clauses[MAX_CLAUSE_NUM];//所有的括号

struct ModifyInfo { int clause_index; bool value; }; //新增，为了保存括号值的修改

class Solution
{
	bool var_value[MAX_VAR_NUM]; //解中每个变量的取值
	bool clause_value[MAX_CLAUSE_NUM]; //括号是否得到满足
	int satisfied_cnt; //即SAT(s)
	
	int satisfied_cnt_tmp; //备份的SAT(s)
	std::vector<ModifyInfo> clause_modifications;
	
	bool ClauseSAT(const Clause &c)
	{
		for(int i = 0; i < 3; ++i)
			if(c.element[i].nagative != var_value[ c.element[i].var_index ]) //nagative表示括号中元素对变量取反，var_value为解中各变量的值
				return true;
		return false;
	}
	
	int TestFlip(int n)
	{
		satisfied_cnt_tmp = satisfied_cnt;
		clause_modifications.clear();
		
		std::vector<Clause*> &related_clauses0 = GetRelatedClause(var_value[n], n);
		std::vector<Clause*> &related_clauses1 = GetRelatedClause(!var_value[n], n);
		//获取与变量相关的括号，Flip后related_clauses0中的括号可以直接设为1，而related_clauses1中的括号需要调用ClauseSAT更新

		for(const Clause* c : related_clauses0)
			if(clause_value[c->clause_index] == 0)//从0变1,才需要更新SAT(s)
			{
				clause_modifications.push_back({c->clause_index, true});
				//保存修改
				satisfied_cnt_tmp ++;
			}
		
		var_value[n] = !var_value[n];
		for(const Clause* c : related_clauses1)
		{
			int new_clause_value = ClauseSAT(*c); //Flip(n)后括号的值
			if(clause_value[c->clause_index] != new_clause_value)//括号值改变则执行修改
			{
				clause_modifications.push_back({c->clause_index, new_clause_value});
				satisfied_cnt_tmp --;
			}
		}
		var_value[n] = !var_value[n];
		return satisfied_cnt_tmp;
	}
	inline void ApplyFlip(int n) //应用TestFlip的修改
	{
		var_value[n] = !var_value[n];
		while(!clause_modifications.empty())
		{
			const ModifyInfo &m = clause_modifications.back();
			clause_value[ m.clause_index ] = m.value;
			clause_modifications.pop_back();
		}
		satisfied_cnt = satisfied_cnt_tmp;
	}

	int SAT()
	{
		return satisfied_cnt;
	}
}
```

### 2.1.3 统计括号中为1的元素个数

2.1.2的代码中，**clause_value**数组为布尔类型，仅仅储存括号是否满足，这使得**TestFlip**时能够用到的信息十分有限。为此，我们重新定义**clause_value**为**int**类型，储存括号中为1的元素个数。

假设括号$$c = (x_1 \lor x_2 \lor \overline{x_3})，x_1 = 0, x_2 = 1, x_3 = 0$$，则其**clause_value**为2($$x_2, x_3$$在c中为真)

这样以后，我们可以直接用加、减运算更新**clause_value**，避免了一切**ClauseSAT**调用

```c++
struct ModifyInfo { int clause_index, value; }; //成员value改为int类型

class Solution
{
	bool var_value[MAX_VAR_NUM];
	int clause_value[MAX_CLAUSE_NUM]; //clause_val改为int类型
	int satisfied_cnt;
	
	int satisfied_cnt_tmp;
	std::vector<ModifyInfo> clause_modifications;
	
	int TestFlip(int n)
	{
		satisfied_cnt_tmp = satisfied_cnt;
		clause_modifications.clear();
		
		std::vector<Clause*> &related_clauses0 = GetRelatedClause(var_value[n], n);
		std::vector<Clause*> &related_clauses1 = GetRelatedClause(!var_value[n], n);
		//获取与变量相关的括号，Flip后related_clauses0中的括号可以直接设为1，而related_clauses1中的括号需要调用ClauseSAT更新

		for(const Clause* c : related_clauses0)
		{
			clause_modifications.push_back({c->clause_index, 1}); //给clause_value加1
			if(clause_value[c->clause_index] == 0)//从0变1,才需要更新SAT(s)
				satisfied_cnt_tmp ++;
		}
		
		for(const Clause* c : related_clauses1)
		{
			clause_modifications.push_back({c->clause_index, -1});
			if(clause_value[c->clause_index] == 1) //从1变0
				satisfied_cnt_tmp --;
		}
		return satisfied_cnt_tmp;
	}
	inline void ApplyFlip(int n) //应用TestFlip的修改
	{
		var_value[n] = !var_value[n];
		while(!clause_modifications.empty())
		{
			const ModifyInfo &m = clause_modifications.back();
			clause_value[ m.clause_index ] += m.value; //"="改为"+="
			clause_modifications.pop_back();
		}
		satisfied_cnt = satisfied_cnt_tmp;
	}
}
```

## 2.2 多线程

整个SASAT算法包括多次模拟退火的尝试(Try)，很自然的想到将这些尝试并行。可以发现每个Try之间不需要任何数据交换，因此并行十分容易实现。

这是原来的算法框架

```c++
std::mt19937 generator(seed); //这只是个随机数生成器
Solution solution(file);
for(int i = 1; i <= max_tries; ++i)
{
	if(Try(generator, solution, i))
		break;
}
```

我们使用了c++11中的**std::future**，**std::async**特性来实现并行

```c++
unsigned cores = std::thread::hardware_concurrency();
std::vector<std::future<void>> future_vector;
future_vector.reserve(cores);

std::atomic_int try_id(1);
std::mt19937 seed_generator(seed);

while(cores --) //为每个cpu核心创建线程
{
	future_vector.push_back(std::async(
				[&](unsigned long thread_seed) -> void
				{
					std::mt19937 generator(thread_seed);
					Solution solution(file);

					while(true)
					{
						int index = try_id ++; //领取一个Try任务
						if(index > max_tries)
							break;
	
						if(Try(generator, solution, index))
						{
							try_id = max_tries + 1; //找到满足的解便结束线程
							break;
						}
					}
				}, seed_generator() //为每个线程传入随机种子
	));
}
```

## 2.3 分析与比较

测试数据中$$N_{var} = 250, N_{clause} = 1065$$

测试环境为Manjaro 18.0.4 Illyria，x86_64 Linux 5.0.21-1-MANJARO，Intel Xeon E3-1505M v6 @ 8x 4GHz，gcc (GCC) 8.3.0

编译参数为-Ofast -funsafe-loop-optimizations -lpthread

| 3-SAT数据	| 随机种子   | Try次数 | 2.1.1 Naive  | 2.1.2 优化1 | 2.1.3 优化2 |
| ------------ | ---------- | ------- | ------------ | ----------- | ----------- |
| uf250-03.cnf | 1		  | 25	  | 460.137443秒 | 4.6562805秒 | 3.0755805秒 |
| uf250-07.cnf | 3643878294 | 8	   | 47.531635秒  | 0.509907秒  | 0.343409秒  |

多线程由于各线程的竞争关系，引入了更多的随机性，同一随机种子的运行时间可能大不相同，这里通过相同Try次数的运行时间进行比较。

| 3-SAT数据	| Try次数 | 2.1.2优化1  | 2.1.2优化1 + 8线程 | 2.1.3优化2  | 2.1.3优化2 + 8线程 |
| ------------ | ------- | ----------- | ------------------ | ----------- | ------------------ |
| uf250-03.cnf | 25	  | 4.6562805秒 | 0.690253秒(6.74倍) | 3.0755805秒 | 0.504293秒(6.1倍)  |
| uf250-02.cnf | 30	  | 6.579755秒  | 0.967821秒(6.8倍)  | 4.6801452秒 | 0.852714秒(5.49倍) |

可见多线程对于运行效率的提升是显著的，对于**2.1.2优化1**的提升会更大一些。由于SASAT算法本身的优良特性，大多数情况下Try次数都在30以内，此程序多能在1秒内求解。



# 附录

测试样例详见<https://github.com/AdamYuan/SATv2/tree/master/problems>

**2.1.3优化2 + 多线程** 程序<https://github.com/AdamYuan/SATv2>
