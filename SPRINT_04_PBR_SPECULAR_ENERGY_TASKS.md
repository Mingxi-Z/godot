# Sprint 05: PBR 与材质 + 光照/BRDF 行为

## 这轮属于 Standard 的哪一块

这轮严格对应:

1. `PBR 与材质`
2. `BRDF / Fresnel / roughness / light size`
3. `材质属性如何变成 shader 行为`

## 本轮唯一项目

### 项目名

`Specular Energy Conservation for Large Lights`

### 项目定义

围绕真实 bug [#111853](https://github.com/godotengine/godot/issues/111853)，做一次 PBR 级的行为分析和最小修复或最小约束设计:

低 roughness 表面在大光源下的 specular highlights 过亮，破坏能量守恒。

## 这轮对应的真实议题

1. [#111853 specular highlights of low roughness surfaces break conservation of energy for big light sources](https://github.com/godotengine/godot/issues/111853)

## 为什么第五轮做它

前面你已经在练:

1. 主链
2. 空间
3. 可见性

这轮开始正面进入渲染面试里最值钱的一块:

1. 你能不能把材质参数、BRDF 数学、light 数据、renderer 路径讲成一件事
2. 你能不能区分“画面怪”到底是数学模型问题、参数约定问题，还是 shader 实现问题

## 这轮不允许退化成什么

下面这些都不算完成:

1. 只改一个 magic number，让画面主观上没那么亮
2. 只看一张截图，不做 roughness / light size 参数矩阵
3. 不区分 direct light specular 和 IBL / clearcoat 的贡献
4. 不说明 Forward+ 和 Mobile 是否都受影响

## 本轮必须补到位的硬知识

### 1. PBR 核心

你必须能解释:

1. `f0`
2. roughness
3. Fresnel
4. microfacet `D / G / F`
5. dielectric 和 metallic 的差别

### 2. 大光源与能量问题

你必须搞清:

1. light size 为什么会改变 specular 形状和强度
2. 为什么低 roughness 下最容易露出问题
3. clearcoat 和主 specular 层会不会相互放大问题

## 必读源码顺序

### A. 先看材质参数怎么定义

1. [material.cpp](scene/resources/material.cpp)

重点盯这几条:

1. `specular`
2. `roughness`
3. `clearcoat`
4. `clearcoat_roughness`

### B. 再看 light / BRDF 的核心实现

1. [scene_forward_lights_inc.glsl](servers/rendering/renderer_rd/shaders/scene_forward_lights_inc.glsl)
2. [light_data_inc.glsl](servers/rendering/renderer_rd/shaders/light_data_inc.glsl)

你要确认:

1. `D_GGX`
2. `V_GGX`
3. `light_compute()`
4. `specular_amount`
5. `f0_Clear_Coat_To_Surface()`

### C. 再看主路径如何组织这些量

1. [scene_forward_clustered.glsl](servers/rendering/renderer_rd/shaders/forward_clustered/scene_forward_clustered.glsl)
2. [scene_forward_mobile.glsl](servers/rendering/renderer_rd/shaders/forward_mobile/scene_forward_mobile.glsl)

你要确认:

1. roughness limiter 在哪里生效
2. clearcoat 和主 specular 如何叠加
3. direct lighting 和 IBL 的路径边界

## 本轮必须画出的 3 张图

### 图 1: 材质到 shader 图

只画:

`BaseMaterial3D property -> material parameter -> generated shader input -> BRDF evaluation`

### 图 2: specular 分项图

只画:

1. 主 specular
2. clearcoat specular
3. direct light 与环境反射

### 图 3: 参数矩阵图

固定三个轴:

1. roughness
2. light size
3. metallic / dielectric

## 代码实现任务

### 任务 1: 先复现实验矩阵

至少做出:

1. 多个 roughness 档位
2. 多个 light size 档位
3. 至少一种 metallic 和一种非 metallic

### 任务 2: 拆出最可能的问题层

你必须判断主要问题更像:

1. BRDF 近似本身
2. light size 的处理方式
3. clearcoat / roughness limiter 的副作用

### 任务 3: 只做一个高把握修改

只能选一个切口:

1. 调整 direct light specular 的能量处理
2. 给现有路径补一个兼容的限制策略
3. 把问题缩小成 clearcoat 或特定材质分支的行为修正

## 本轮官方文档要求

至少查下面 2 篇:

1. [BaseMaterial3D](https://docs.godotengine.org/en/stable/classes/class_basematerial3d.html)
2. [Spatial shaders](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/spatial_shader.html)

查阅要求:

1. 记录官方如何解释 roughness、metallic、clearcoat 这类材质语义
2. 记录官方材质语义和 `scene_forward_lights_inc.glsl` 里的 BRDF / clearcoat 实现是如何接上的

## 本轮 GPU Frame Capture 操作

至少做下面 3 件事:

1. 抓一帧小光源场景
2. 抓一帧大光源场景
3. 在 capture 中对比同一材质在两种情况下的光照相关 pass / draw 证据

记录要求:

1. 至少记录 1 组 roughness 对照
2. 至少记录 1 组 light size 对照
3. 至少写清 GPU frame capture 证据如何帮助你判断这是 direct light / BRDF 行为问题，而不只是材质参数问题

## 本轮验证矩阵

至少覆盖:

1. roughness `0.0` 到 `1.0`
2. 小光源到大光源
3. clearcoat 开关
4. Forward+ 与 Mobile 至少做行为对比

## 本轮面试通过线

你必须能讲清楚:

1. `#111853` 为什么是 PBR / BRDF 问题，而不是单纯的“美术参数不好看”
2. `light_compute()` 里哪一段最可能导致能量不守恒
3. 为什么不能只看一张 before / after 图就宣布修好了
4. 你做的修正为什么不会顺手破坏其它材质路径
