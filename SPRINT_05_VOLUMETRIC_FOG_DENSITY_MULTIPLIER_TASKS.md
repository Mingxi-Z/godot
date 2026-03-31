# Sprint 06: Shader 数据通道 + 资源/状态管理

## 这轮属于 Standard 的哪一块

这轮严格对应:

1. `Shader 数据通道`
2. `资源与状态管理`
3. `从 scene 资源层打通到 GPU 的完整功能闭环`

## 本轮唯一项目

### 项目名

`Volumetric Fog Density Multiplier Texture`

### 项目定义

围绕真实 proposal [#11324](https://github.com/godotengine/godot-proposals/issues/11324)，做一个跨资源层、storage 层、scene data / fog 处理层的真正 feature。

最小目标不是“随便加个参数”，而是:

1. 给 `Environment` 增加真正可用的输入
2. 把它正确地传到渲染系统
3. 让 volumetric fog 对高频细节有可见改善

## 这轮对应的真实议题

1. [#11324 Add a volumetric fog density multiplier texture to better represent high-frequency detail](https://github.com/godotengine/godot-proposals/issues/11324)

## 为什么第六轮做它

这是整条学习链里第一个真正像“我给引擎加了一个 renderer feature”的题。

它强制你同时面对:

1. 资源层 API 设计
2. storage 持有和脏更新
3. CPU -> GPU 参数传递
4. shader / fog 计算
5. 默认值与兼容性

## 这轮不允许退化成什么

下面这些都不算完成:

1. 只在 shader 里硬编码一张 3D 纹理
2. 只在 `Environment` 上加属性，但没有真正进入 fog 路径
3. 默认行为被改坏
4. 不说明采样频率、坐标约定和性能风险

## 本轮必须补到位的硬知识

### 1. 数据通道

你必须能解释:

1. uniform 和 texture/sampler 的区别
2. 为什么这题更像 texture 参数，而不是单个 float
3. 资源什么时候更新，什么时候真正被 GPU 读到

### 2. 资源与所有权

你必须搞清:

1. `Environment` 持有的是什么
2. `environment_storage` 存什么
3. fog 处理阶段从哪里拿数据

## 必读源码顺序

### A. 先看资源层入口

1. [environment.h](scene/resources/environment.h)
2. [world_environment.cpp](scene/3d/world_environment.cpp)

你要确认:

1. 参数应该定义在 `Environment` 的哪一组
2. 默认值和 inspector 表达如何设计

### B. 再看 storage 和 renderer API

1. [renderer_scene_render.cpp](servers/rendering/renderer_scene_render.cpp)
2. [environment_storage.h](servers/rendering/storage/environment_storage.h)
3. [environment_storage.cpp](servers/rendering/storage/environment_storage.cpp)

你要确认:

1. `environment_set_fog()` 这类 API 是怎么进入 storage 的
2. 新 feature 应该落在环境数据的哪一层

### C. 最后看 volumetric fog 消费路径

1. [fog.cpp](servers/rendering/renderer_rd/environment/fog.cpp)
2. [volumetric_fog_process.glsl](servers/rendering/renderer_rd/shaders/environment/volumetric_fog_process.glsl)
3. [renderer_scene_render_rd.h](servers/rendering/renderer_rd/renderer_scene_render_rd.h)

你要确认:

1. volumetric fog 的关键输入从哪里来
2. 3D texture 最适合在什么阶段采样
3. 这条 feature 对性能的主要风险是什么

## 本轮必须画出的 3 张图

### 图 1: 资源到 fog 图

只画:

`Environment -> RendererSceneRender / storage -> fog path -> volumetric fog shader`

### 图 2: 数据通道图

只画:

1. 标量参数
2. `Texture3D`
3. sampler / uniform set

### 图 3: 默认值与兼容图

只画:

1. feature 关闭时
2. feature 开启时
3. 为什么旧场景不变

## 代码实现任务

### 任务 1: 先收最小功能集

默认只做这几项:

1. `Texture3D` 输入
2. 一个强度参数
3. 一个基础坐标或缩放控制

### 任务 2: 打通 CPU -> GPU

你必须确保:

1. `Environment` 能保存和序列化这个状态
2. storage 真正持有这个数据
3. fog 处理路径能稳定拿到纹理和参数

### 任务 3: 保持默认关闭

你必须保证:

1. 旧场景不变
2. feature 没开时没有额外视觉副作用
3. 如果性能成本明显，默认不强制开启

## 本轮官方文档要求

至少查下面 2 篇:

1. [Environment](https://docs.godotengine.org/en/stable/classes/class_environment.html)
2. [Environment and post-processing](https://docs.godotengine.org/en/stable/tutorials/3d/environment_and_post_processing.html)

查阅要求:

1. 记录官方对 fog / volumetric fog / environment 参数分层的说明
2. 记录官方用户层语义如何映射到 `environment_storage` 和 volumetric fog 的实际实现

## 本轮 GPU Frame Capture 操作

至少做下面 3 件事:

1. 抓一帧 feature 关闭
2. 抓一帧 feature 开启
3. 在 capture 中定位 volumetric fog 相关 pass，并确认新纹理或参数确实被消费

记录要求:

1. 至少记录 1 个 volumetric fog 相关 pass
2. 至少记录 1 个新输入纹理或 uniform 证据
3. 至少写清 GPU frame capture 如何帮助你证明“参数真的进了 GPU 路径”

## 本轮验证矩阵

至少覆盖:

1. feature 关闭 vs 开启
2. 不同纹理频率
3. 不同雾密度
4. 至少一个高频细节明显的体积场景

## 本轮面试通过线

你必须能讲清楚:

1. 为什么这个参数必须放在 `Environment`，而不是只写进 shader
2. texture 类型 feature 和纯 float feature 在资源管理上有什么不同
3. 你的实现为什么是“真正功能项目”，不是一段临时实验代码
4. 默认值、性能、兼容性分别怎么保证
