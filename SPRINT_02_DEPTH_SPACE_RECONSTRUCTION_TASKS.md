# Sprint 02: 坐标空间与变换 + 深度重建语义

## 这轮属于 Standard 的哪一块

这轮严格对应:

1. `坐标空间与变换`
2. `摄像机 / 深度 / 反投影`
3. `world-space / view-space / clip-space` 的正确分工

如果这一轮做完，你还说不清 `depth -> view position -> world position` 是怎么恢复出来的，那就没有过。

## 本轮唯一项目

### 项目名

`Depth Semantics and Position Reconstruction`

### 项目定义

做一个真正可见的深度重建检查路径，让错误的深度方向、错误的线性化、错误的空间恢复会直接在屏幕上暴露出来。

推荐交付形式三选一:

1. world-space 高度可视化
2. view-space `z` 可视化
3. depth 重建误差热力图

这轮不是继续“把 depth 显示出来”，而是要把 `depth 的空间语义` 讲清楚。

## 这轮对应的真实议题

1. [#90148 Depth texture returned by RenderSceneBuffersRD is upside down and in sRGB colorspace](https://github.com/godotengine/godot/issues/90148)
2. [#85107 Getting depth texture from viewport loses precision](https://github.com/godotengine/godot/issues/85107)
3. [#798 Access different viewport buffers through ViewportTextures ("G-buffer")](https://github.com/godotengine/godot-proposals/issues/798)
4. [#10396 Access more common buffers in RenderSceneBuffersRD](https://github.com/godotengine/godot-proposals/issues/10396)

## 为什么第二轮先做这个

因为很多人会“看到 depth”，但并没有真的理解:

1. 这个值在哪个空间
2. 这个值是不是已经 resolve / copy 过
3. 这个值能不能直接拿来重建 view-space / world-space
4. Y 翻转、颜色空间、精度错误为什么会立刻污染后续 screen-space 效果

这一轮是后面 fog、SSR、CompositorEffect、buffer access 的前置门槛。

## 这轮不允许退化成什么

下面这些都不算完成:

1. 只是把 `DEPTH_TEXTURE` 接出来看一眼
2. 只会背一个线性化公式，但说不出公式里的矩阵和约定来自哪里
3. 只在一个固定场景看起来“像是对的”
4. 不区分 resolved depth、raw depth、linear depth

## 本轮必须补到位的硬知识

### 1. 空间约定

你必须明确区分:

1. clip space
2. NDC
3. device depth
4. view-space position
5. world-space position

### 2. 反投影

你必须能解释:

1. 为什么需要 `inv_projection_matrix`
2. 什么时候还需要 `inv_view_matrix`
3. 重建 view-space 和 world-space 的区别

### 3. 深度语义

你必须搞清:

1. depth 为什么通常是非线性的
2. 为什么有时能直接线性化，有时更稳的是直接做完整反投影
3. 为什么深度方向、坐标翻转和精度都会影响重建

## 必读源码顺序

### A. 先看 scene data 里矩阵是怎么准备的

1. [render_scene_data_rd.cpp](servers/rendering/renderer_rd/storage_rd/render_scene_data_rd.cpp)
2. [render_scene_data_rd.h](servers/rendering/renderer_rd/storage_rd/render_scene_data_rd.h)
3. [scene_data_inc.glsl](servers/rendering/renderer_rd/shaders/scene_data_inc.glsl)

你要确认:

1. `inv_projection_matrix` 从哪来
2. multiview 时为什么还有 `inv_projection_matrix_view`
3. 当前帧和前一帧矩阵分别怎么准备

### B. 再看真正消费深度重建的 shader

1. [screen_space_reflection.glsl](servers/rendering/renderer_rd/shaders/effects/screen_space_reflection.glsl)
2. [ss_effects_downsample.glsl](servers/rendering/renderer_rd/shaders/effects/ss_effects_downsample.glsl)
3. [gi.glsl](servers/rendering/renderer_rd/shaders/environment/gi.glsl)

你要确认:

1. Godot 里已经有哪些地方在做重建
2. 它们是用线性化还是完整反投影
3. 不同效果对重建精度的敏感度为什么不一样

### C. 再看 depth buffer 是怎么暴露和消费的

1. [render_scene_buffers_rd.h](servers/rendering/renderer_rd/storage_rd/render_scene_buffers_rd.h)
2. [render_scene_buffers_rd.cpp](servers/rendering/renderer_rd/storage_rd/render_scene_buffers_rd.cpp)
3. [renderer_scene_render_rd.cpp](servers/rendering/renderer_rd/renderer_scene_render_rd.cpp)
4. [compositor.cpp](scene/resources/compositor.cpp)
5. [compositor_storage.cpp](servers/rendering/storage/compositor_storage.cpp)

你要确认:

1. depth buffer 通过哪条路径给 debug / compositor 使用
2. 哪些 flag 会改变需要准备哪些 buffer
3. resolved depth 和普通 attachment 的角色差别

### D. 最后回到主渲染路径确认空间约定

1. [scene_forward_clustered.glsl](servers/rendering/renderer_rd/shaders/forward_clustered/scene_forward_clustered.glsl)
2. [scene_forward_mobile.glsl](servers/rendering/renderer_rd/shaders/forward_mobile/scene_forward_mobile.glsl)

你要确认:

1. Forward+ 和 Mobile 在空间量上的主要共性
2. 哪些地方最容易把 view-space / world-space 混掉

## 本轮必须画出的 3 张图

### 图 1: depth 重建图

只画这一条:

`depth texture -> NDC -> inv_projection -> view-space -> inv_view -> world-space`

### 图 2: scene data 矩阵来源图

只画:

`CameraData / projection -> render_scene_data_rd -> scene_data_inc.glsl -> screen-space shader`

### 图 3: buffer ownership 图

只画:

`RenderSceneBuffersRD -> debug/compositor consumer -> final visualization`

## 代码实现任务

### 任务 1: 先选可见结果

只能选一个主结果，不要三头开工:

1. world-space 高度带
2. view-space 深度条带
3. 重建误差热力图

### 任务 2: 明确 depth contract

你必须在设计笔记里写清楚:

1. 输入 depth 的来源
2. 它是不是 resolved depth
3. 它在当前路径里是否需要 Y 翻转
4. 它是否允许直接作为 screen read 输入

### 任务 3: 让错误能被看见

你的实现必须满足:

1. 一旦方向错了，画面会明显上下或前后不对
2. 一旦精度错了，梯度会出现断层或噪声
3. 一旦空间错了，world-space 可视化会和真实场景几何不匹配

## 本轮官方文档要求

至少查下面 2 篇:

1. [Screen-reading shaders](https://docs.godotengine.org/en/stable/tutorials/shaders/screen-reading_shaders.html)
2. [Advanced post-processing](https://docs.godotengine.org/en/stable/tutorials/shaders/advanced_postprocessing.html)

查阅要求:

1. 记录官方怎么解释 depth texture 的非线性和 `INV_PROJECTION_MATRIX`
2. 记录官方描述和 `render_scene_data_rd.cpp`、`scene_data_inc.glsl`、实际深度重建 shader 之间的对应关系

## 本轮 GPU Frame Capture 操作

至少做下面 3 件事:

1. 抓一帧包含明显前后景深度差的场景
2. 在 capture 里确认 depth 输入纹理和你的重建可视化 pass
3. 对比一次“正确重建”和一次“故意制造方向/空间错误”的结果差异

记录要求:

1. 至少记录 1 个 depth attachment
2. 至少记录 1 个消费该 attachment 的 draw / dispatch
3. 至少写清 GPU frame capture 证据如何帮助你判断方向、精度或空间语义问题

## 本轮验证矩阵

至少覆盖下面 4 组:

1. 不同 near/far 设置
2. 有明显高度差的场景
3. 倾斜相机与正视相机
4. 至少一种 CompositorEffect 或 debug view 消费路径

## 本轮面试通过线

你必须能讲清楚:

1. 为什么“能看到 depth”不等于“能正确重建位置”
2. `inv_projection_matrix` 和 `inv_view_matrix` 分别解决什么问题
3. `#90148` 和 `#85107` 为什么会直接影响 fog / SSR / compositor 这类系统
4. 你的实现为什么是空间语义检查，不只是调试花活
