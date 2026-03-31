# Sprint 01: CPU/GPU 心智模型 + Godot 渲染主链

## 这轮冲刺要解决什么

这不是一轮"熟悉代码风格"的热身。

这轮冲刺的目标是:

1. 真正建立 CPU/GPU 分工模型
2. 真正读懂 Godot 一帧 3D 渲染的主链
3. 做出一个不是日志级别的真实项目

这轮结束时，你要能讲清楚:

`viewport debug draw -> RendererViewport -> RendererSceneRenderRD -> render buffers / attachments -> fullscreen debug effect`

如果讲不清这条链，这轮就不算过。

## 本轮唯一项目

### 项目名

`Render Buffer Inspection: Depth First`

### 项目定义

给 Godot 新增或增强一个 viewport / renderer debug draw 路径，把 3D 场景的深度纹理以"线性深度"形式可视化到最终 render target，并明确它和 `RenderSceneBuffersRD` / CompositorEffect 的真实需求关系。

### 为什么选这个项目

因为它刚好把第一轮最该学的 5 件事绑在一起:

1. 深度不是普通颜色贴图
2. 原始 depth 值通常不是线性的
3. debug draw 是 Godot 现成的用户可见入口
4. 你必须读懂 render buffers 和 attachment 的来路
5. 结果是屏幕可见的，不是日志

### 这轮对应的真实议题

这轮不是纯训练题，它要服务这些公开议题:

1. [#10396 Access more common buffers in RenderSceneBuffersRD](https://github.com/godotengine/godot-proposals/issues/10396)
2. [#798 Access different viewport buffers through ViewportTextures ("G-buffer")](https://github.com/godotengine/godot-proposals/issues/798)
3. [#90148 Depth texture returned by RenderSceneBuffersRD is upside down and in sRGB colorspace](https://github.com/godotengine/godot/issues/90148)
4. [#85107 Getting depth texture from viewport loses precision](https://github.com/godotengine/godot/issues/85107)

### 为什么第一轮先做这个

因为你如果一上来就直接修 `#90148` 或直接做 `#10396`，很容易犯两个错:

1. 只会改一处 shader 或 sampler 行为，但说不出 buffer 是怎么来的
2. 只会在某个案例里把结果改对，但说不出 debug draw、render target、internal buffer、CompositorEffect 之间的关系

所以这一轮是桥接项目，但不是虚空桥接，而是明确为上面 4 个真实议题铺路。

### 这项目不允许退化成什么

下面这些都不算完成:

1. 直接把 depth 贴图 copy 出来，不做线性化
2. 只在 CPU 上打印 depth texture 是否存在
3. 只新增 enum，不真正显示结果
4. 只能在一个特定场景看起来"差不多"

## 本轮必须补到位的硬知识

### 1. CPU/GPU 分工

你必须能明确说出:

1. CPU 创建和更新资源
2. CPU 组织命令和渲染数据
3. GPU 读取 buffer/texture 并执行 draw/dispatch
4. 一帧内 CPU 与 GPU 不是强同步串行
5. staging/update/sync/stall 分别意味着什么

### 2. attachment / framebuffer / render target

你必须分清:

1. render target 是最终显示目标
2. internal buffer 是中间颜色结果
3. depth texture 是单独 attachment
4. debug draw 经常不是重新渲染，而是"读取已有 attachment 并显示"

### 3. 深度的数学意义

你必须补到能自己推导或解释:

1. 深度值为什么通常是非线性的
2. clip / NDC / device depth 之间是什么关系
3. 线性深度和 raw depth 的差别
4. 当前渲染路径的投影和深度约定需要通过源码确认，不能拍脑袋假设

### 4. 最小渲染管线意识

你至少要知道:

1. 一个 fullscreen debug pass 也是渲染 pass
2. 它需要 shader、pipeline、framebuffer、输入纹理
3. 它属于"读已有结果并可视化"而不是重新跑场景几何

## 必读源码顺序

不要乱看，按下面顺序走。

### A. 先看对外入口

1. [rendering_server.cpp](servers/rendering/rendering_server.cpp#L2888)
2. [rendering_server_enums.h](servers/rendering/rendering_server_enums.h#L546)

你要确认:

1. `viewport_set_debug_draw()` 是怎么暴露出去的
2. 现有 debug draw 枚举有哪些
3. 新模式将来应该挂在哪一层

### B. 再看 viewport 如何把 debug draw 传下去

1. [renderer_viewport.cpp](servers/rendering/renderer_viewport.cpp#L883)
2. [renderer_viewport.cpp](servers/rendering/renderer_viewport.cpp#L910)
3. [renderer_viewport.cpp](servers/rendering/renderer_viewport.cpp#L1542)

你要确认:

1. viewport 的 `debug_draw` 最终如何设置到 scene renderer
2. 为什么 `motion vectors` 这种 debug draw 会影响额外数据需求

### C. 再看 scene renderer 里已有 debug draw 怎么做

1. [renderer_scene_render_rd.cpp](servers/rendering/renderer_rd/renderer_scene_render_rd.cpp#L1101)
2. [renderer_scene_render_rd.cpp](servers/rendering/renderer_rd/renderer_scene_render_rd.cpp#L1110)
3. [renderer_scene_render_rd.cpp](servers/rendering/renderer_rd/renderer_scene_render_rd.cpp#L1115)
4. [renderer_scene_render_rd.cpp](servers/rendering/renderer_rd/renderer_scene_render_rd.cpp#L1127)
5. [renderer_scene_render_rd.cpp](servers/rendering/renderer_rd/renderer_scene_render_rd.cpp#L1535)

你要确认:

1. 哪些 debug draw 只是 copy attachment
2. 哪些 debug draw 需要专门的 debug effect
3. `NORMAL_BUFFER` 和 `MOTION_VECTORS` 走法为什么不一样

### D. 再看 render buffers 到底存了什么

1. [render_scene_buffers_rd.h](servers/rendering/renderer_rd/storage_rd/render_scene_buffers_rd.h#L44)
2. [render_scene_buffers_rd.h](servers/rendering/renderer_rd/storage_rd/render_scene_buffers_rd.h#L62)
3. [render_scene_buffers_rd.h](servers/rendering/renderer_rd/storage_rd/render_scene_buffers_rd.h#L209)

你要确认:

1. `RB_TEX_COLOR`、`RB_TEX_DEPTH`、`RB_TEX_VELOCITY` 分别是什么
2. internal size 和 target size 有什么区别
3. reflection 配置和普通 viewport 配置有什么不同

### E. 再看真实 3D 渲染主链

1. [renderer_scene_cull.cpp](servers/rendering/renderer_scene_cull.cpp#L3197)
2. [renderer_scene_cull.cpp](servers/rendering/renderer_scene_cull.cpp#L3583)
3. [renderer_scene_render.h](servers/rendering/renderer_scene_render.h#L326)
4. [renderer_scene_render_rd.h](servers/rendering/renderer_rd/renderer_scene_render_rd.h#L249)
5. [render_forward_clustered.cpp](servers/rendering/renderer_rd/forward_clustered/render_forward_clustered.cpp#L1686)

你要确认:

1. `scene_cull_result` 是怎么收集出来的
2. `render_scene()` 的输入到底有哪些
3. `RenderSceneBuffersRD` 为什么是这条主链里的关键对象

### F. 最后看现成 debug effect

1. [debug_effects.h](servers/rendering/renderer_rd/effects/debug_effects.h#L39)
2. [debug_effects.cpp](servers/rendering/renderer_rd/effects/debug_effects.cpp#L40)
3. [debug_effects.cpp](servers/rendering/renderer_rd/effects/debug_effects.cpp#L344)

你要确认:

1. debug effect 是如何创建 shader 和 pipeline 的
2. motion vectors 可视化为什么要额外吃 projection/transform 信息
3. 你的 linear depth 模式更像 `copy`，还是更像 `debug effect`

## 本轮必须画出的 3 张图

### 图 1: Godot 3D 主链图

只画这一条:

`RendererViewport -> RendererSceneCull::_render_scene() -> RendererSceneRender::render_scene() -> RendererSceneRenderRD::render_scene() -> RenderForwardClustered::_render_scene()`

### 图 2: Debug Draw 数据流图

只画这一条:

`viewport debug enum -> viewport_set_debug_draw() -> set_debug_draw_mode() -> _render_buffers_debug_draw() -> render target framebuffer`

### 图 3: 线性深度公式图

画出:

1. 你从哪拿到 depth texture
2. 这个值在哪个空间
3. 怎么线性化
4. 线性化后的范围如何映射到屏幕颜色

## 代码实现任务

### 任务 1: 选实现策略

你必须先做决策，再写代码:

1. 是扩展现有 debug effect
2. 还是新增一个更简单的 fullscreen depth-visualization pass

决策标准:

1. 如果只需要 depth 纹理和投影信息，倾向复用 debug effect 体系
2. 如果只是无脑 copy，就不够，因为 raw depth 不可读

### 任务 2: 打通枚举与入口

你需要定位并准备修改:

1. `rendering_server_enums.h`
2. `rendering_server.cpp`
3. `renderer_scene_render_rd.cpp`

### 任务 3: 完成线性深度可视化

目标:

1. 在普通 3D viewport 中可用
2. 能根据深近远变化看出层次
3. 不要求一开始就支持所有路径，但要明确写出哪些路径支持、哪些暂不支持

额外要求:

1. 你要明确记录这个实现距离 `#10396` 和 `#798` 还差什么
2. 你要明确记录如果以后切到 `#90148`，最可能排查的代码入口是什么

### 任务 4: 验证场景

必须做两个场景:

1. 近景物体 + 远景物体 + 大范围深度跨度
2. 有遮挡层次、能明显看到深度梯度变化的场景

## 本轮官方文档要求

至少查下面 2 篇:

1. [Internal rendering architecture](https://docs.godotengine.org/en/latest/contributing/development/core_and_modules/internal_rendering_architecture.html)
2. [Rendering](https://docs.godotengine.org/en/stable/tutorials/rendering/index.html)

查阅要求:

1. 记录 Godot 官方怎样描述 `RenderingDevice`、renderers、rendering pipeline 的分层
2. 记录官方高层描述和你在 `RenderingServer -> RendererViewport -> RendererSceneRenderRD` 里看到的实际链路如何对应

## 本轮 GPU Frame Capture 操作

至少做下面 3 件事:

1. 在 macOS 上用 `Xcode GPU Frame Capture` 抓一帧普通 3D viewport
2. 找到最终 fullscreen debug draw 对应的 pass 或 draw call
3. 确认这轮可视化读取的是哪个 depth attachment / texture，以及它最后写回哪个 render target

记录要求:

1. 至少截图或记录 1 个相关 pass
2. 至少记录 1 个相关 attachment
3. 至少写清你如何从 capture 里确认“这不是重新画几何，而是在消费已有 buffer”

## 产物要求

这轮必须至少交下面 8 个文件或等价内容:

1. `sprint01_chain_map.md`
2. `sprint01_official_docs_note.md`
3. `sprint01_debug_draw_flow.md`
4. `sprint01_depth_math_note.md`
5. `sprint01_gpu_capture.md`
6. `sprint01_validation.md`
7. `sprint01_risk_note.md`
8. `sprint01_interview_pitch.md`

## 验证标准

### 功能验证

1. 你能在 viewport 中切到新 debug draw 模式
2. 输出不是一片纯黑或纯白
3. 近物体和远物体有稳定、可解释的灰度或伪彩层次

### 代码链验证

1. 你能指出 depth texture 从哪来
2. 你能指出最终写回哪个 framebuffer
3. 你能指出这个模式依赖了哪些 camera/projection 信息

### 工程验证

1. 默认模式不受影响
2. 现有 debug draw 不回归
3. 没有把这个功能偷偷耦合成"只有某个特定场景才有效"

## 本轮最容易犯的错

1. 看到 depth texture 就以为可以直接显示
2. 不去确认当前路径的深度约定
3. 不去分清 internal buffer 和 render target
4. 以为 debug draw 只是工具代码，不算 renderer 学习
5. 以为做出画面就够了，不写设计和验证说明

## 面试通过线

这轮结束时，你必须能用 3 分钟讲清下面这段话:

"我第一轮没有从材质或 feature 开始，而是做了一个和真实社区需求直接相关的 buffer inspection 项目。它表面上是在 viewport 里把线性深度可视化，但本质上是在为 `RenderSceneBuffersRD` 的 buffer 暴露、CompositorEffect 的 depth 正确性，以及 depth buffer 精度/方向问题打基础。这个项目让我把 Godot 的 3D 主渲染链读通了: debug draw 从 `RenderingServer` 枚举暴露，经 `RendererViewport` 传到 `RendererSceneRenderRD`，再读取 `RenderSceneBuffersRD` 里的深度 attachment，通过一个 fullscreen debug pass 输出到最终 framebuffer。"

## 失败条件

出现下面任意一条，这轮就算没过:

1. 只做了阅读，没有真实项目
2. 项目结果不可见
3. 说不出 depth 为什么要线性化
4. 说不出 `RenderSceneBuffersRD` 在这轮项目里的作用
5. 说不出这条 debug draw 链是怎么从 viewport 走到 renderer 的
