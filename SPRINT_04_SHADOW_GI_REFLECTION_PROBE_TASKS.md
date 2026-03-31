# Sprint 04: 阴影 / GI / Reflection Probe

## 这轮属于 Standard 的哪一块

这轮严格对应:

1. `阴影 / GI / Reflection Probe`
2. `shadow atlas / reflection atlas / probe update`
3. `SSR / IBL / ReflectionProbe / SDFGI / VoxelGI` 的职责边界

## 本轮唯一项目

### 项目名

`Shadow Render Pass Audit for Non-Emitting GPUParticles3D`

### 项目定义

围绕 `Shadow Render` pass 里出现“不该存在的 draw call”这个真实问题，做一次真正系统级的定位，并完成以下两类结果之一:

1. 真正修复
2. 最小但可回归的诊断工具或 instrumentation

这轮默认主问题已经固定，不再三选一。

## 这轮对应的真实议题

1. 主项目:
   [#116682 Vulkan: Non-emitting GPUParticles3D cause draw call in "Shadow Render" pass](https://github.com/godotengine/godot/issues/116682)
2. 后续深化备选:
   [#106892 Shadow map not updated for billboard sprites when the camera moves](https://github.com/godotengine/godot/issues/106892)
3. 后续 probe 方向备选:
   [#113676 Stretch marks and artifacts on environment octmaps](https://github.com/godotengine/godot/issues/113676)

## 为什么第四轮做它

因为这块在 Godot 里不是一个“小 feature”，而是几套真正的 renderer 系统:

1. 阴影有自己的 pass、atlas、缓存与更新策略
2. ReflectionProbe 有自己的 capture、atlas、update mode 与 shading 入口
3. VoxelGI / SDFGI / 环境反射和 probe 会在画面上相互补位

如果不把这块单独拎出来，后面很容易出现:

1. 只会修局部画面，不知道系统边界
2. 说不清性能成本来自哪里
3. 说不清为什么某个问题属于 shadow、probe 还是 GI

## 这轮不允许退化成什么

下面这些都不算完成:

1. 只调某个 shadow 参数，不解释为什么对象会进入 shadow pass
2. 只看一张 probe 结果图，不看 capture / atlas / pass
3. 只说“GI 看起来不对”，不区分 SDFGI、VoxelGI、ReflectionProbe、SSR
4. 不说明缓存、更新频率和性能代价

## 本轮必须补到位的硬知识

### 1. 阴影系统

你必须能解释:

1. directional / omni / spot shadow 的主要区别
2. shadow atlas 为什么存在
3. shadow render pass 为什么常常和主颜色 pass 分离

### 2. 反射与 GI 系统

你必须搞清:

1. ReflectionProbe 和 SSR 的边界
2. ReflectionProbe 和环境反射 / IBL 的关系
3. VoxelGI 和 SDFGI 的主要差别
4. 哪些系统只在特定 renderer path 下可用

## 必读源码顺序

### A. 先看粒子和场景入口

1. [particles_storage.cpp](servers/rendering/renderer_rd/storage_rd/particles_storage.cpp)
2. [renderer_scene_cull.cpp](servers/rendering/renderer_scene_cull.cpp)
3. [render_forward_clustered.cpp](servers/rendering/renderer_rd/forward_clustered/render_forward_clustered.cpp)

你要确认:

1. 粒子实例在 renderer 侧如何进入几何列表
2. non-emitting 状态理论上应该影响哪一层
3. Shadow Render pass 在主渲染链中的位置

### B. 再看阴影与 light culling 组织

1. [rendering_light_culler.cpp](servers/rendering/rendering_light_culler.cpp)
2. [renderer_scene_render.h](servers/rendering/renderer_scene_render.h)
3. [render_forward_clustered.cpp](servers/rendering/renderer_rd/forward_clustered/render_forward_clustered.cpp)

你要确认:

1. shadow render 需要哪些实例输入
2. light / shadow culling 与主颜色 pass 的边界
3. 为什么一个对象可能只出现在 shadow pass，而不出现在 opaque / depth prepass

### C. 最后看同主题的系统边界文件

1. [reflection_probe.cpp](scene/3d/reflection_probe.cpp)
2. [gi.cpp](servers/rendering/renderer_rd/environment/gi.cpp)
3. [environment.h](scene/resources/environment.h)

你要确认:

1. 为什么这轮主项目虽然是 shadow pass 问题，但仍然属于 shadow / GI / probe 主题
2. 这一轮先不直接做 probe / GI 主项目的理由是什么

## 本轮必须画出的 3 张图

### 图 1: shadow pass 输入图

只画:

`GPUParticles3D state -> renderer-side particle data -> scene instances / draw path -> Shadow Render pass`

### 图 2: pass 对照图

只画:

1. Shadow Render
2. Render Depth Prepass
3. Render Opaque

重点说明:

同一对象为什么可能只在其中一个 pass 出现

### 图 3: 系统边界图

只画:

1. shadow
2. ReflectionProbe
3. VoxelGI / SDFGI
4. 为什么本轮先锁 shadow pass

## 代码实现任务

### 任务 1: 先复现 issue 行为

你必须复现出 issue 里最关键的现象:

1. `GPUParticles3D` 的 `Emitting = false`
2. `Shadow Render` pass 里仍有 draw call
3. 同时它不应在 `Render Depth Prepass` 或 `Render Opaque` 中出现对应 draw

### 任务 2: 缩小问题层级

你必须在 `design_note.md` 里写清:

1. 这是粒子可见性问题、shadow pass 收集问题，还是 shadow draw 提交问题
2. non-emitting 状态理论上应该在哪一层被拦住
3. 为什么这个 bug 不等于“粒子系统整体错误渲染”

### 任务 3: 给出最小但可回归的产物

产物可以是:

1. 一个真正的修复
2. 一个可视化诊断工具
3. 一个缩小问题范围的系统级 instrumentation

但必须能回归验证，不是临时观察脚本。

## 本轮官方文档要求

至少查下面 4 篇:

1. [Lights and shadows](https://docs.godotengine.org/en/stable/tutorials/3d/lights_and_shadows.html)
2. [GPUParticles3D](https://docs.godotengine.org/en/stable/classes/class_gpuparticles3d.html)
3. [Internal rendering architecture](https://docs.godotengine.org/en/latest/contributing/development/core_and_modules/internal_rendering_architecture.html)
4. [ReflectionProbe](https://docs.godotengine.org/en/stable/classes/class_reflectionprobe.html)

查阅要求:

1. 记录官方如何描述 shadow、粒子、renderer path 的高层行为
2. 记录这些高层描述和 Godot 当前 shadow pass / particles / render organization 之间的对应关系
3. 说明为什么本轮虽然查了 ReflectionProbe 文档，但主问题仍然锁定 shadow pass

## 本轮 GPU Frame Capture 操作

至少做下面 4 件事:

1. 抓一帧 `GPUParticles3D` 且 `Emitting = false` 的场景
2. 至少定位 1 个 `Shadow Render` pass
3. 在同一 capture 中定位 `Render Depth Prepass` 或 `Render Opaque`
4. 找到粒子对应的 draw call
5. 对比它在不同 pass 中是否存在

记录要求:

1. 至少写清 1 个 shadow pass 的 draw 证据
2. 至少写清同一对象在非 shadow pass 中缺失的证据
3. 至少写清 draw call 对应的是哪类粒子 / 几何输入
4. 至少说明 GPU frame capture 在这轮能证明哪些 pass-level 事实，哪些生命周期事实仍要靠代码验证

## 本轮验证矩阵

至少覆盖:

1. `Emitting = false`
2. `Emitting = true`
3. 开关阴影
4. 至少一组修复前 / 修复后或加 instrumentation 前 / 后的可比结果

## 本轮面试通过线

你必须能讲清楚:

1. 为什么 `#116682` 是 shadow pass 组织问题，不是“粒子渲染整体坏了”
2. 为什么 GPU frame capture 在这轮是核心证据，而不只是辅助截图
3. non-emitting 状态最合理应该在哪一层阻止对象进入 shadow pass
4. 你如何把这个 shadow pass 问题和更大的 shadow / GI / probe 系统边界联系起来
