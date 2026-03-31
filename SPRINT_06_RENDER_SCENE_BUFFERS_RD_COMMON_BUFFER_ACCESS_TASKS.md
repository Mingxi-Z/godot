# Sprint 07: 屏幕后处理、Compositor 与 Temporal 系统

## 这轮属于 Standard 的哪一块

这轮严格对应:

1. `屏幕后处理、Compositor 与 Temporal 系统`
2. `buffer access / compositor / screen-space / motion vectors / TAA / FSR2`
3. `为什么看起来只是取一张纹理或一组 velocity，实际牵涉方向、格式、精度、prev-frame 数据和消费契约`

## 本轮唯一项目

### 项目名

`RenderSceneBuffersRD Common Buffer Access and Temporal Inputs`

### 项目定义

围绕真实 proposal / bug:

1. [#10396](https://github.com/godotengine/godot-proposals/issues/10396)
2. [#798](https://github.com/godotengine/godot-proposals/issues/798)
3. [#90148](https://github.com/godotengine/godot/issues/90148)
4. [#85107](https://github.com/godotengine/godot/issues/85107)
5. [#115210](https://github.com/godotengine/godot/issues/115210)

做一次正式的 buffer access 能力建设:

至少让一个真实 buffer 或 temporal 输入，以“可被稳定消费”的方式进入 inspection / compositor / screen-space / temporal 使用链。

## 为什么第七轮做它

因为现在你已经有:

1. 主链视角
2. 空间语义
3. 可见性经验
4. 一次完整 feature 经验

这时再做 buffer access，才不会退化成“把一个 RID 暴露出来”。

## 这轮不允许退化成什么

下面这些都不算完成:

1. 只暴露一个纹理句柄，不说明格式和语义
2. 只在某个 debug 模式能看，CompositorEffect 还是不能稳定用
3. 不处理 upside-down、colorspace、precision 这类契约问题
4. 不说明为什么某些 buffer 不能随意公开

## 本轮必须补到位的硬知识

### 1. screen-space 与 temporal 效果输入

你必须搞清:

1. resolved color
2. resolved depth
3. normal-roughness
4. motion vectors
5. depth pyramid
6. prev-frame scene data / previous depth / upscaling inputs

谁适合公开、谁适合内部使用。

### 2. 屏幕空间与 temporal 失效模式

你必须能解释:

1. 方向错
2. 颜色空间错
3. 精度不够
4. 分辨率不一致
5. prev-frame 数据脏
6. velocity buffer 语义错

为什么都会让 screen-space 或 temporal 效果看似“有图”，但实际不可用。

## 必读源码顺序

### A. 先看 buffer 持有和命名

1. [render_scene_buffers_rd.h](servers/rendering/renderer_rd/storage_rd/render_scene_buffers_rd.h)
2. [render_scene_buffers_rd.cpp](servers/rendering/renderer_rd/storage_rd/render_scene_buffers_rd.cpp)

你要确认:

1. 哪些 buffer 已经存在
2. 哪些 buffer 已经有命名访问
3. internal size / target size 的边界在哪里

### B. 再看 renderer 怎么决定要不要准备这些 buffer 与 temporal 输入

1. [renderer_scene_render_rd.cpp](servers/rendering/renderer_rd/renderer_scene_render_rd.cpp)
2. [render_forward_clustered.cpp](servers/rendering/renderer_rd/forward_clustered/render_forward_clustered.cpp)
3. [render_forward_mobile.cpp](servers/rendering/renderer_rd/forward_mobile/render_forward_mobile.cpp)
4. [render_scene_data_rd.cpp](servers/rendering/renderer_rd/storage_rd/render_scene_data_rd.cpp)

你要确认:

1. 哪些 flag 会触发 normal / motion / depth 的准备
2. `prev_ubo`、motion vectors、upscaling 输入是怎么准备的
3. debug draw 和真正 screen-space / temporal consumer 的共同点与差异

### C. 最后看真正的 consumer

1. [compositor.cpp](scene/resources/compositor.cpp)
2. [compositor_storage.cpp](servers/rendering/storage/compositor_storage.cpp)
3. [copy_effects.cpp](servers/rendering/renderer_rd/effects/copy_effects.cpp)
4. [debug_effects.cpp](servers/rendering/renderer_rd/effects/debug_effects.cpp)
5. [taa_resolve.glsl](servers/rendering/renderer_rd/shaders/effects/taa_resolve.glsl)
6. [fsr2.cpp](servers/rendering/renderer_rd/effects/fsr2.cpp)

你要确认:

1. CompositorEffect 是怎么声明自己要哪些 buffer 的
2. TAA / FSR2 为什么会额外依赖 velocity 和 prev-frame 数据
3. copy / debug 两种消费方式的边界
4. 为什么“能 debug 看见”不等于“API 公开后就能正确用”

## 本轮必须画出的 3 张图

### 图 1: buffer / temporal input 契约图

只画:

`producer pass -> RenderSceneBuffersRD / prev scene data -> consumer (debug/compositor/temporal) -> semantics / format contract`

### 图 2: buffer 分类图

把 buffer 分成三类:

1. 可直接公开
2. 需要包装或约束后公开
3. 暂时不应公开

### 图 3: 问题传播图

只画:

`orientation / colorspace / precision / dirty prev-frame data -> broken screen-space or temporal consumer`

## 代码实现任务

### 任务 1: 只选一个正式目标

推荐三选一:

1. 正式打通 normal-roughness 的 inspection / compositor 访问
2. 把 depth access 的方向 / 颜色空间 / 精度契约补清楚
3. 围绕 motion vectors / prev_ubo / TAA / FSR2 做一个最小但正式的 temporal input contract

### 任务 2: 至少做一个真实 consumer

你的实现必须被下面至少一类真正消费:

1. CompositorEffect
2. debug inspection path
3. 一个 screen-space 或 temporal effect 的辅助路径

### 任务 3: 说明“不公开”的边界

你必须在 `design_note.md` 里写清:

1. 哪些 buffer 不能现在就公开
2. 为什么不能
3. 后续需要什么前置条件

## 本轮官方文档要求

至少查下面 3 篇:

1. [The Compositor](https://docs.godotengine.org/en/stable/tutorials/rendering/compositor.html)
2. [Screen-reading shaders](https://docs.godotengine.org/en/stable/tutorials/shaders/screen-reading_shaders.html)
3. [Advanced post-processing](https://docs.godotengine.org/en/stable/tutorials/shaders/advanced_postprocessing.html)
4. [3D antialiasing](https://docs.godotengine.org/en/stable/tutorials/3d/3d_antialiasing.html)

查阅要求:

1. 记录官方如何描述 CompositorEffect、depth texture、motion vectors、TAA / FSR2 这类 temporal 输入
2. 记录官方说明和 `RenderSceneBuffersRD` / `CompositorEffect` / `prev_ubo` 实际代码契约之间的对应与缺口

## 本轮 GPU Frame Capture 操作

至少做下面 4 件事:

1. 抓一帧包含目标 buffer 的场景
2. 抓至少前 2 到 3 帧中的一帧，观察 temporal 输入或 velocity 行为
3. 在 capture 中定位 buffer producer pass
4. 在 capture 中定位 buffer consumer pass、compositor consumer 或 temporal consumer
5. 对比一次正确消费与一次错误语义消费或脏 prev-frame 数据的差异

记录要求:

1. 至少记录 1 个 producer
2. 至少记录 1 个 consumer
3. 至少记录 1 个 motion vector、prev-frame 或 TAA / FSR2 相关证据
4. 至少记录 1 个方向、精度或颜色空间相关证据
5. 至少写清 GPU frame capture 证据如何支撑你的 buffer / temporal contract 设计

## 本轮验证矩阵

至少覆盖:

1. depth / normal / motion 中至少一种真实 buffer
2. debug view 与 consumer 的一致性
3. 不同 viewport 尺寸
4. 一组方向 / 精度 / 颜色空间对照
5. 一组 temporal 首帧 / 次帧 / 稳定帧对照

## 本轮面试通过线

你必须能讲清楚:

1. `#10396` 和 `#798` 真正难的不是“多给一个纹理”，而是 buffer contract
2. `#90148`、`#85107`、`#115210` 为什么说明 screen-space 和 temporal 输入必须先讲清语义
3. 为什么 debug draw 能工作，不代表 API 设计已经对了
4. 为什么 TAA / FSR2 会把 motion vectors、prev_ubo、depth 这些输入绑在一起
5. 你这轮给出的最小 engine 方案是什么
