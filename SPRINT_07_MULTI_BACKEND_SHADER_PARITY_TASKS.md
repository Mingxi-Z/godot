# Sprint 08: 多后端与精度问题

## 这轮属于 Standard 的哪一块

这轮严格对应:

1. `多后端与精度问题`
2. `shader 生成链与平台差异`
3. `为什么 Vulkan 上看着过了，不代表引擎层面真的过了`

## 本轮唯一项目

### 项目名

`Unshaded Shader Bloat and Backend Parity`

### 项目定义

围绕真实问题 [#112283](https://github.com/godotengine/godot/issues/112283)，做一次真正的 shader 生成链和平台差异分析:

`unshaded` 路径为什么还能生成明显膨胀的代码，尤其是在 Metal 上。

## 这轮对应的真实议题

1. [#112283 Heavy bloat in generated unlit "unshaded" shader (Metal)](https://github.com/godotengine/godot/issues/112283)

## 为什么第八轮做它

这是收尾阶段最好的题之一，因为它逼你同时看:

1. 材质前端标志
2. shader variant 生成链
3. Forward+ / Mobile 路径差异
4. Metal 这种具体后端的约束

## 这轮不允许退化成什么

下面这些都不算完成:

1. 只说“生成的 shader 看起来很长”
2. 只看 GLSL，不看更后面的编译和后端约束
3. 只做文本 diff，不说明真正运行时是否有影响
4. 不区分 debug / reflection 信息和运行时真正必要的代码

## 本轮必须补到位的硬知识

### 1. shader 生成链

你必须能解释:

1. `render_mode unshaded` 在前端怎么表示
2. 它怎么进入 Forward+ / Mobile 的 shader data
3. variant 和 pipeline 创建是怎么关联的

### 2. 多后端与平台差异

你必须搞清:

1. Metal 和 Vulkan 看到的问题不一定一样
2. 生成代码膨胀不一定等于真正的 GPU 成本
3. 但它常常意味着更高的编译成本、更多分支、更多平台风险

## 必读源码顺序

### A. 先看材质前端如何声明 unshaded

1. [material.cpp](scene/resources/material.cpp)

重点盯:

1. `flags_unshaded`
2. `render_mode unshaded`

### B. 再看 Forward+ / Mobile 的 shader 生成链

1. [scene_shader_forward_clustered.cpp](servers/rendering/renderer_rd/forward_clustered/scene_shader_forward_clustered.cpp)
2. [scene_shader_forward_mobile.cpp](servers/rendering/renderer_rd/forward_mobile/scene_shader_forward_mobile.cpp)
3. [shader_rd.cpp](servers/rendering/renderer_rd/shader_rd.cpp)

你要确认:

1. `actions.render_mode_flags["unshaded"]`
2. `actions.render_mode_defines["unshaded"]`
3. `_create_pipeline()` 在哪里把 variant 真正变成 pipeline

### C. 最后看 Metal 后端的容器与限制

1. [rendering_shader_container_metal.h](drivers/metal/rendering_shader_container_metal.h)
2. [metal_objects_shared.cpp](drivers/metal/metal_objects_shared.cpp)
3. [metal_device_properties.h](drivers/metal/metal_device_properties.h)

你要确认:

1. Metal 路径对生成代码和绑定资源有什么特殊要求
2. 为什么某些看起来“无害”的膨胀在 Metal 上更敏感

## 本轮必须画出的 3 张图

### 图 1: unshaded 生成链图

只画:

`BaseMaterial3D / Shader front-end -> shader data -> variant -> pipeline -> backend shader`

### 图 2: 膨胀来源图

只画:

1. 前端保留下来的定义
2. 生成链引入的分支
3. 后端 / 平台需要保留的信息

### 图 3: 平台验证图

至少画:

1. Forward+
2. Mobile
3. Metal 或平台特定风险说明

## 代码实现任务

### 任务 1: 先拿最小 unshaded 样本

你必须收集:

1. 一个极简 unshaded 材质
2. 一个对应的非 unshaded 对照
3. 它们在生成链里的关键差异

### 任务 2: 把 bloated code 的来源缩到一层

你必须判断主要来源更像:

1. 前端 render_mode 映射
2. variant 保守保留
3. 后端 / 平台特殊要求

### 任务 3: 只优化一个最有把握的路径

只能选一个切口:

1. 删掉明显不需要的分支 / define 进入条件
2. 收窄 unshaded 路径进入某些 variant 的条件
3. 只做一处高把握的 pipeline / shader 生成整理

## 本轮官方文档要求

至少查下面 2 篇:

1. [Internal rendering architecture](https://docs.godotengine.org/en/latest/contributing/development/core_and_modules/internal_rendering_architecture.html)
2. [3D antialiasing](https://docs.godotengine.org/en/stable/tutorials/3d/3d_antialiasing.html)

查阅要求:

1. 记录官方对 renderers、renderer paths、temporal features 和后端差异的高层描述
2. 记录这些高层描述和 `scene_shader_forward_clustered.cpp`、`scene_shader_forward_mobile.cpp`、Metal 路径实现之间的关系

## 本轮 GPU Frame Capture 操作

至少做下面 3 件事:

1. 在可用平台上抓一帧最小 `unshaded` 样本
2. 对比 `unshaded` 和非 `unshaded` 的相关 draw / pipeline 证据
3. 用 capture 记录 shader / pipeline 膨胀对实际渲染路径的可见影响

记录要求:

1. macOS 默认用 `Xcode GPU Frame Capture`
2. 如果你同时看 Vulkan / D3D / OpenGL，额外说明哪些部分适合 `RenderDoc`
3. 至少写清 GPU frame capture 能证明的运行时事实，和它不能直接证明的后端生成细节

## 本轮验证矩阵

至少覆盖:

1. unshaded 与 lit 对照
2. Forward+ 与 Mobile 的生成差异
3. 至少一种平台 / 后端风险说明
4. 编译输出、pipeline 数量或 shader 文本规模中的至少一项客观证据

## 本轮面试通过线

你必须能讲清楚:

1. `#112283` 真正训练的不是“怎么删代码”，而是“怎么读 shader 生成链”
2. 为什么 `render_mode unshaded` 不一定自动意味着后端最简代码
3. 为什么平台差异题不能只在 Vulkan 上看起来没问题就算过
4. 你怎么区分“必要复杂度”和“可优化膨胀”
