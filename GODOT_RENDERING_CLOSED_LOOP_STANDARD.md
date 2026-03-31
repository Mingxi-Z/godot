# Godot Rendering Closed-Loop Standard

## 目标

这份文档不是图形学课表，也不是 Godot 源码导览。

它的目标只有一个:

把下面三件事绑成一个闭环:

1. 渲染硬知识补课
2. Godot 渲染源码链路阅读
3. 能写进简历、能在面试里讲清楚的真实功能或 bugfix

闭环的标准不是"看懂了几份文档"，而是:

1. 你补完一个知识块后，能立刻在 Godot 中找到落点
2. 你能做一个不是打日志级别的小项目
3. 你能拿出画面、数据、对照实验证明改动有效
4. 你能解释设计、兼容性、性能和多路径差异

## 执行规则

### 永远按这个循环学

每个主题都按下面 8 步执行:

1. 学最小硬知识块
2. 查至少 2 篇官方文档，并记录哪些内容能直接指导代码阅读、哪些地方文档没有覆盖
3. 在 Godot 找资源层、渲染层、shader 层的落点
4. 画一张 1 页链路图
5. 做一个最小但真实的功能或 bugfix
6. 做至少一次 GPU frame capture，并把关键 pass / attachment / draw call 证据记录下来
7. 做 before/after 验证
8. 写 3 分钟面试口述稿

### 禁止的学习方式

下面这些做法全部禁止:

1. 连续两周只看图形学不碰 Godot
2. 连续两周只读 Godot 不补图形学
3. 把"加日志、判断变量、打印路径"当成主要产出
4. 改 shader 几行但说不出 CPU 到 GPU 数据怎么过去
5. 只在一条渲染路径跑通就宣布做完

### 最小项目的标准

一个合格的最小项目必须满足:

1. 用户可感知:
   画面、材质、debug view、资源行为或渲染结果真的变了
2. 跨至少两层:
   不能只改一个 `.glsl` 或只改一个 inspector 属性
3. 能验证:
   至少有截图、参数矩阵、GPU frame capture、性能计数或回归对照中的两项
4. 能回滚:
   默认值关闭或兼容旧行为

### 真实议题优先

默认优先级如下:

1. 真实 bug
2. 真实 proposal
3. 为真实 bug / proposal 铺路的桥接项目
4. 纯训练题

这意味着后面选题时默认遵守下面规则:

1. 如果存在合适的 Godot 公开 issue / proposal，优先围绕它推进
2. 如果暂时不直接做那个 issue / proposal，也要明确写出"我这个桥接项目将服务于哪个真实议题"
3. 只有在没有合适真实议题，或者当前能力差距过大时，才允许做纯训练题

### 每轮都要写清楚真实锚点

每一轮项目都必须写出下面三项:

1. 对应的 issue / proposal 链接
2. 当前这轮是直接解决问题，还是在做桥接能力建设
3. 为什么这轮先做它，而不是直接跳去修更深的问题

### 官方文档是硬标准

每一轮都必须查官方文档，不允许只看源码和 issue。

最少标准如下:

1. 至少查 2 篇官方文档
2. 至少 1 篇是 class / tutorial 文档
3. 如果该主题涉及 renderer internals、render pipeline、CompositorEffect、后端差异，至少再查 1 篇官方 architecture / contributing 文档
4. 必须明确写出:
   文档里哪些内容帮助你建立系统模型
5. 必须明确写出:
   文档里哪些内容和当前源码、当前 issue、当前行为之间存在差距

### GPU Frame Capture 是每轮必修，不是可选项

从 Sprint 01 开始，每一轮都必须有 GPU frame capture 相关操作。

最少标准如下:

1. 至少做 1 次 capture
2. 不能只截图工具界面，必须记录你验证了什么
3. 至少明确指出 1 个 pass、1 个 attachment 或 1 组 draw/dispatch 证据
4. 如果这轮主题本身更偏 shader 生成、资源链、screen-space、shadow、GI、motion vectors、temporal、buffer access，多半需要不止 1 次 capture
5. 如果某条路径无法直接靠当前工具覆盖，也要写清楚 capture 能证明哪部分，剩余哪部分需要其他工具或代码验证

工具选择默认如下:

1. macOS + Metal:
   默认用 `Xcode GPU Frame Capture`
2. Windows / Linux + Vulkan / D3D / OpenGL:
   优先用 `RenderDoc`
3. 如果某轮使用了别的等价 GPU 调试工具，也必须说明原因

## 总体顺序

按依赖顺序学，不要乱跳:

1. CPU/GPU 心智模型
2. 坐标空间与变换
3. 光栅化管线与可见性组织
4. 阴影 / GI / Reflection Probe
5. PBR 与材质
6. Shader 数据通道与资源/状态管理
7. 屏幕后处理、Compositor 与 Temporal 系统
8. 多后端与精度问题

但是不要"学完一门再碰下一门"。

正确做法是按下面 8 个冲刺推进，每个冲刺都把硬知识和 Godot 代码绑在一起。

## 冲刺 0: 基础环境与观察能力

### 目标

建立基本工作流，让后面每一次改动都能验证。

### 硬知识

1. Debug/Release 构建差异
2. GPU capture 是什么，为什么需要 Xcode GPU Frame Capture 或其它等价 GPU 调试工具
3. 什么叫 regression proof

### 必读 Godot 代码

1. [rendering_server.cpp](servers/rendering/rendering_server.cpp)
2. [rendering_device.h](servers/rendering/rendering_device.h)
3. [renderer_scene_render.h](servers/rendering/renderer_scene_render.h)
4. [renderer_scene_cull.cpp](servers/rendering/renderer_scene_cull.cpp)

### 必须完成的事情

1. 你能从 `WorldEnvironment` 或 `ReflectionProbe` 找到一条完整调用链到 `render_scene()`
2. 你能做一次 GPU capture
3. 你能解释一帧里 CPU 侧和 GPU 侧不是串行同步执行

### 通过线

你必须能口述下面这条链:

`scene node/resource -> RenderingServer -> scene cull -> scene render -> Forward+/Mobile -> shader -> driver`

如果这一轮没有直接挂到公开 issue / proposal，也必须在记录里说明它后面要服务哪个真实议题。

## 冲刺 1: CPU/GPU 心智模型 + 渲染主链入门

### 目标

搞清 Godot 不是"直接调用 Vulkan 画三角形"，而是先组织资源、状态、render data，再进入具体渲染路径。

### 硬知识

1. CPU 负责资源创建、状态更新、命令录制
2. GPU 负责执行 draw/dispatch 和读写 buffer/texture
3. frame in flight、staging buffer、同步与 stall
4. framebuffer、attachment、pipeline、descriptor/uniform set 的职责

### Godot 代码落点

1. [rendering_device.h](servers/rendering/rendering_device.h#L95)
2. [rendering_context_driver_vulkan.cpp](drivers/vulkan/rendering_context_driver_vulkan.cpp)
3. [rendering_device_driver_vulkan.cpp](drivers/vulkan/rendering_device_driver_vulkan.cpp)
4. [render_forward_clustered.cpp](servers/rendering/renderer_rd/forward_clustered/render_forward_clustered.cpp#L1680)

### 推荐最小项目

做一个新的 `Viewport Debug Draw` 或 compositor 级可视化模式，目标是把现有 attachment 之一真正显示出来:

1. 线性深度
2. normal-roughness
3. motion vectors

这个项目必须满足:

1. 不是打印 attachment 名字
2. 不是只在 CPU 上记一条日志
3. 必须真的把 GPU 里已有结果显示出来

默认应优先把这个项目挂到真实议题，例如:

1. [#10396 Access more common buffers in RenderSceneBuffersRD](https://github.com/godotengine/godot-proposals/issues/10396)
2. [#798 Access different viewport buffers through ViewportTextures ("G-buffer")](https://github.com/godotengine/godot-proposals/issues/798)
3. [#90148 Depth texture returned by RenderSceneBuffersRD is upside down and in sRGB colorspace](https://github.com/godotengine/godot/issues/90148)
4. [#85107 Getting depth texture from viewport loses precision](https://github.com/godotengine/godot/issues/85107)

### 你要学会回答的问题

1. 这个 attachment 是在哪个 pass 生成的
2. 生成之后存在哪个 render buffer 里
3. 为什么某些路径能拿到它，某些路径拿不到
4. 为什么 reflection probe 渲染时有些普通 viewport 数据不存在

### 通过线

你能解释 [render_forward_clustered.cpp](servers/rendering/renderer_rd/forward_clustered/render_forward_clustered.cpp#L1686) 到 [render_forward_clustered.cpp](servers/rendering/renderer_rd/forward_clustered/render_forward_clustered.cpp#L1755) 在准备什么数据，以及它为什么依赖 `RenderSceneBuffersRD`。

## 冲刺 2: 坐标空间与变换 + 摄像机/雾/深度重建

### 目标

彻底搞懂 view/world/clip 的流动，否则后面 fog、SSR、GI 都会学飘。

### 硬知识

1. local/world/view/clip/NDC/screen space
2. 投影矩阵、逆视图矩阵
3. normal matrix 为什么是 inverse-transpose
4. 世界空间量和视空间量混用会造成什么 bug

### Godot 代码落点

1. [world_environment.cpp](scene/3d/world_environment.cpp)
2. [environment.h](scene/resources/environment.h)
3. [render_scene_data_rd.cpp](servers/rendering/renderer_rd/storage_rd/render_scene_data_rd.cpp#L208)
4. [scene_data_inc.glsl](servers/rendering/renderer_rd/shaders/scene_data_inc.glsl#L64)
5. [scene_forward_mobile.glsl](servers/rendering/renderer_rd/shaders/forward_mobile/scene_forward_mobile.glsl#L1048)

### 推荐最小项目

做一个"空间可视化"功能，三选一:

1. 新增世界高度带可视化，用颜色编码当前片元相对 `fog_height` 的位置
2. 新增 view-space 深度与 world-space 高度的对照 debug mode
3. 给 fog 添加一个只用于 debug 的可视化分支，直接显示参与雾计算的关键中间量

要求:

1. 至少涉及 `Environment` 或 scene data 的一层数据传递
2. 结果必须是屏幕可见变化
3. 你必须写清楚你显示的是 world-space 量还是 view-space 量

如果没有直接对应的公开 issue，也要把它绑定到后续真实题上，例如 fog、probe、SSR、CompositorEffect 中的空间/深度问题。

### 通过线

你能独立解释:

1. 为什么 [scene_forward_mobile.glsl](servers/rendering/renderer_rd/shaders/forward_mobile/scene_forward_mobile.glsl#L1101) 要从 `inv_view_matrix` 还原世界空间 `y`
2. 为什么雾、SSR、GI 经常会因为空间混淆出错

## 冲刺 3: 光栅化管线 + 可见性与渲染组织

### 目标

理解"为什么没画出来"、"为什么被挡住了"、"为什么这个 pass 根本没执行"。

### 硬知识

1. vertex input 到 fragment output 的光栅化流程
2. depth/stencil、blend、cull、MSAA
3. frustum culling、light culling、LOD
4. pass、render list、render_scene 的职责分工

### Godot 代码落点

1. [renderer_scene_cull.cpp](servers/rendering/renderer_scene_cull.cpp#L3197)
2. [renderer_scene_cull.cpp](servers/rendering/renderer_scene_cull.cpp#L3583)
3. [renderer_scene_render.h](servers/rendering/renderer_scene_render.h#L326)
4. [renderer_viewport.h](servers/rendering/renderer_viewport.h)
5. [render_forward_clustered.cpp](servers/rendering/renderer_rd/forward_clustered/render_forward_clustered.cpp)

### 推荐最小项目

直接做一个真实的可见性 / culling 问题:

1. 复现并定位一次 occlusion culling 角度相关错误
2. 改一个与 `cull mask`、`mesh lod threshold`、阴影参与相关的真实问题
3. 或者给 scene cull 增加一个用户可见但默认关闭的调试特性

这类项目最好直接对齐真实 renderer bug，例如:

1. [#106184 Occlusion culling doesn't cull objects from all viewing angles](https://github.com/godotengine/godot/issues/106184)

### 不允许的伪项目

下面这些不算:

1. 只在 `render_probes()` 打印 probe 数量
2. 只记录某个 `RID` 是否有效
3. 只把 `RENDER_TIMESTAMP` 改个名字

### 通过线

你要能解释 [renderer_scene_cull.cpp](servers/rendering/renderer_scene_cull.cpp#L3197) 到 [renderer_scene_cull.cpp](servers/rendering/renderer_scene_cull.cpp#L3583) 之间:

1. 可见性准备做了什么
2. 哪些数据被收集进 `scene_cull_result`
3. 最终怎么送进 `render_scene()`

## 冲刺 4: 阴影 / GI / Reflection Probe

### 目标

把 Godot 里最容易被分散理解的几套全局光照和反射系统，学成一条真正的渲染系统链。

### 硬知识

1. directional / omni / spot shadows 的更新与分配
2. shadow atlas、reflection atlas 的资源组织
3. ReflectionProbe、SSR、IBL 的边界与互补关系
4. VoxelGI、SDFGI、环境光照之间的职责分工
5. 缓存、更新策略和性能成本为什么是这类系统的核心问题

### Godot 代码落点

1. [reflection_probe.cpp](scene/3d/reflection_probe.cpp)
2. [renderer_scene_cull.cpp](servers/rendering/renderer_scene_cull.cpp#L3735)
3. [renderer_scene_render.h](servers/rendering/renderer_scene_render.h#L326)
4. [rendering_light_culler.cpp](servers/rendering/rendering_light_culler.cpp)
5. [gi.cpp](servers/rendering/renderer_rd/environment/gi.cpp)
6. [environment.h](scene/resources/environment.h)

### 推荐最小项目

优先围绕下面这类真实系统题推进:

1. 影子更新策略相关 bug
2. ReflectionProbe 更新 / atlas / shading 相关 bug
3. SDFGI / VoxelGI / probe 之间的联动型诊断或修复

推荐真实议题包括:

1. [#106892 Shadow map not updated for billboard sprites when the camera moves](https://github.com/godotengine/godot/issues/106892)
2. [#116682 Vulkan: Non-emitting GPUParticles3D cause draw call in "Shadow Render" pass](https://github.com/godotengine/godot/issues/116682)
3. [#113676 Stretch marks and artifacts on environment octmaps](https://github.com/godotengine/godot/issues/113676)

### 通过线

你必须能讲清楚:

1. 为什么 ReflectionProbe、SSR 和环境反射不是同一回事
2. 为什么 shadow / probe / GI 这类系统常常会把“行为正确”和“性能正确”绑在一起
3. `render_probes()`、shadow render、SDFGI 更新分别在整个 renderer 里扮演什么角色

## 冲刺 5: PBR 与材质 + Shader 生成链

### 目标

学会从 `BaseMaterial3D` 一路追到 Godot 生成的 3D shader，再追到具体渲染路径里的 shader variant。

### 硬知识

1. albedo、metallic、roughness、normal、TBN
2. Fresnel、BRDF、IBL
3. 为什么 normal map 依赖 tangent basis
4. 材质参数如何影响 pipeline state 与 shader variant

### Godot 代码落点

1. [material.cpp](scene/resources/material.cpp#L1112)
2. [material.cpp](scene/resources/material.cpp#L2257)
3. [material.cpp](scene/resources/material.cpp#L3657)
4. [scene_shader_forward_clustered.cpp](servers/rendering/renderer_rd/forward_clustered/scene_shader_forward_clustered.cpp#L40)
5. [scene_shader_forward_clustered.cpp](servers/rendering/renderer_rd/forward_clustered/scene_shader_forward_clustered.cpp#L695)
6. [scene_shader_forward_clustered.cpp](servers/rendering/renderer_rd/forward_clustered/scene_shader_forward_clustered.cpp#L910)

### 推荐最小项目

不要发明一个完全拍脑袋的新材质参数。更好的做法是:

1. 选 `clearcoat`、`rim`、`anisotropy`、`normal` 其中一条现有链
2. 找一个真实缺陷或表现不足
3. 改到"用户可感知"的级别

推荐题型:

1. 修一个 clearcoat 相关行为问题
2. 给现有材质特性补一个兼容的限制或插值策略
3. 让一个现有特性在 Forward+ 和 Mobile 结果更一致

如果要做性能或 shader 复杂度方向，优先对齐真实议题，例如:

1. [#112283 Heavy bloat in generated unlit "unshaded" shader (Metal)](https://github.com/godotengine/godot/issues/112283)

### 通过线

你必须能讲清楚:

1. `BaseMaterial3D` 的 inspector 属性怎么变成 shader uniform
2. Godot 为什么不是一份固定 shader，而是走 shader compiler 和 variant 生成链
3. 某个材质特性为什么会影响深度、混合、cull 或 alpha 分支

## 冲刺 6: Shader 数据通道 + 资源/状态管理

### 目标

把"我改了一个参数"升级成"我真的会打通 CPU 到 GPU 的数据链"。

### 硬知识

1. uniform、UBO、std140、texture/sampler
2. shader variant、specialization、uniform set
3. 资源所有权、脏标记、生命周期
4. mesh/material/light/environment 分别由谁持有和更新

### Godot 代码落点

1. [environment_storage.cpp](servers/rendering/storage/environment_storage.cpp#L344)
2. [material_storage.cpp](servers/rendering/renderer_rd/storage_rd/material_storage.cpp#L31)
3. [mesh_storage.cpp](servers/rendering/renderer_rd/storage_rd/mesh_storage.cpp)
4. [light_storage.cpp](servers/rendering/renderer_rd/storage_rd/light_storage.cpp)
5. [render_scene_data_rd.cpp](servers/rendering/renderer_rd/storage_rd/render_scene_data_rd.cpp#L208)

### 推荐最小项目

这里直接做一个真正的渲染功能:

`Dual-Layer Height Fog`

最小实现范围:

1. 在 `Environment` 增加第二层高度雾参数
2. 贯通到 environment storage
3. 贯通到 `render_scene_data_rd`
4. 改 Forward+ shader 先跑通
5. 默认关闭，旧场景完全兼容

如果你想把功能项目也尽量贴近真实需求，优先考虑公开 proposal，例如:

1. [#11324 Add a volumetric fog density multiplier texture to better represent high-frequency detail](https://github.com/godotengine/godot-proposals/issues/11324)

### 为什么这个题非常适合

因为它强制你同时面对:

1. 资源层 API 设计
2. CPU 到 GPU 数据通道
3. shader 数学
4. 默认值与兼容性
5. 验证场景设计

### 通过线

你必须能讲出:

1. 参数为什么放在 `Environment` 而不是 shader 里写死
2. std140 布局为什么需要谨慎
3. 为什么这个改动不该只停留在 Forward+ 单一路径

## 冲刺 7: 屏幕后处理、Compositor 与 Temporal 系统

### 目标

开始真正理解最容易"看着懂，实际没懂链路"的系统，尤其是 motion vectors、TAA、FSR2 这类 temporal 路径。

### 硬知识

1. linear depth 与非线性深度
2. motion vectors 与 previous-frame 数据
3. depth pyramid / hiz
4. TAA、FSR2、SSAO、SSR、fog 这些效果依赖哪些输入
5. temporal 与 screen-space 效果的典型失效模式

### Godot 代码落点

1. [screen_space_reflection_hiz.glsl](servers/rendering/renderer_rd/shaders/effects/screen_space_reflection_hiz.glsl)
2. [taa_resolve.glsl](servers/rendering/renderer_rd/shaders/effects/taa_resolve.glsl)
3. [fsr2.cpp](servers/rendering/renderer_rd/effects/fsr2.cpp)
4. [render_scene_data_rd.cpp](servers/rendering/renderer_rd/storage_rd/render_scene_data_rd.cpp)
5. [compositor.cpp](scene/resources/compositor.cpp)
6. [render_forward_clustered.cpp](servers/rendering/renderer_rd/forward_clustered/render_forward_clustered.cpp)

### 推荐最小项目

做一个真正的 screen-space / temporal 问题修复或增强，推荐三类:

1. fog/SSR/SSAO 与现有参数或路径的联动问题
2. 一个可见的屏幕空间 debug/inspection 功能，帮助定位失效类型
3. motion vectors / TAA / FSR2 输入正确性问题

优先级更高的真实议题包括:

1. [#90148 Depth texture returned by RenderSceneBuffersRD is upside down and in sRGB colorspace](https://github.com/godotengine/godot/issues/90148)
2. [#85107 Getting depth texture from viewport loses precision](https://github.com/godotengine/godot/issues/85107)
3. [#10396 Access more common buffers in RenderSceneBuffersRD](https://github.com/godotengine/godot-proposals/issues/10396)
4. [#115210 Velocity buffer and scene buffer uniform not clean at the first and second frame](https://github.com/godotengine/godot/issues/115210)

### 通过线

你能解释:

1. 为什么某些效果必须要 motion vectors、prev_ubo 或 depth pyramid
2. 为什么 reflection probe、fog、SSR、TAA、FSR2 往往会互相牵扯
3. 为什么屏幕空间和 temporal 效果最容易在边界、遮挡、离屏区域和首帧状态出错

## 冲刺 8: 多后端与精度问题

### 目标

把你做出来的功能或 bugfix 从"主路径 demo"升级成"工程上站得住"。

### 硬知识

1. Forward+ 与 Forward Mobile 的差异
2. Vulkan/D3D12/Metal 的坐标与精度细节
3. half/float、深度范围、矩阵约定、sampler 差异
4. 为什么同一个 shader 逻辑在不同路径会有细微偏差

### Godot 代码落点

1. [scene_shader_forward_mobile.cpp](servers/rendering/renderer_rd/forward_mobile/scene_shader_forward_mobile.cpp)
2. [scene_forward_mobile.glsl](servers/rendering/renderer_rd/shaders/forward_mobile/scene_forward_mobile.glsl)
3. [drivers/vulkan](drivers/vulkan)
4. [drivers/d3d12](drivers/d3d12)
5. [drivers/metal](drivers/metal)

### 推荐最小项目

把冲刺 5 或冲刺 6 里做出的功能/修复继续推进:

1. 移植到 Forward Mobile
2. 对齐精度和默认值
3. 跑至少两种平台或后端验证

如果你有 Metal / Mobile / Vulkan 路径差异相关目标，优先围绕公开 issue 展开，而不是自己凭感觉造题。

### 通过线

你必须能说:

1. 为什么"Vulkan 上过了"不代表整个引擎层面过了
2. 你这次改动里最可能出现的精度风险是什么
3. 你是怎么设计验证矩阵的

## 每个冲刺必须交付的 8 个文件

不管做哪个题，每次都要有这 8 类产物:

1. `chain_map.md`
   只画一条链，不要画百科全书
2. `official_docs_note.md`
   记录本轮查了哪些官方文档、哪些地方有帮助、哪些地方和源码/现象存在差距
3. `design_note.md`
   说明为什么改这一层，不改别层
4. `patch.diff`
   真实改动
5. `gpu_capture.md`
   记录本轮 capture 的 pass、attachment、draw/dispatch 证据和结论，以及使用的工具
6. `validation.md`
   before/after、参数矩阵、性能或 capture 结论
7. `risk_note.md`
   兼容性、性能、精度、多路径风险
8. `interview_pitch.md`
   3 分钟讲清问题、方案、验证、取舍

## 面试标准

如果你学到后面想去找渲染相关工作，下面这组问题必须答得出来。

### 你必须能讲的技术问题

1. Godot 一帧 3D 渲染是怎么从 scene 数据走到 Forward+/Mobile 的
2. 一个环境参数是怎么从 `Environment` 走到最终 shader 的
3. 为什么 shader 改对了，结果仍然可能不对
4. 一个材质特性为什么会引入新的 shader variant
5. 一个 reflection probe 或屏幕空间问题为什么常常不是单一文件能修掉的
6. 多后端一致性为什么不能靠"肉眼看起来差不多"判断

### 你必须能讲的工程问题

1. 默认值为什么必须兼容旧场景
2. 为什么要优先做可回滚设计
3. 为什么验证不能只有截图
4. 为什么最好同时给出功能验证和性能验证

## 选题建议

如果你要从现在开始做真正的闭环训练，推荐顺序如下:

1. 先做一个 attachment/debug-view 类项目
2. 再做一个材质链或 shader variant 类项目
3. 再做一个环境参数链功能:
   推荐 `Dual-Layer Height Fog`
4. 最后做一个涉及 probe/SSR/fog 的联动型问题
5. 收尾阶段做 Mobile 或多后端对齐

## 最后一句话

真正会在 Godot 渲染里修 bug、加功能的人，不是:

1. 图形学词汇很多的人
2. 能背几个 Vulkan API 名字的人
3. 或者只会在源码里打日志的人

而是能把这 4 件事稳定连起来的人:

1. 看懂渲染现象
2. 映射到图形学原理
3. 映射到 Godot 源码链
4. 做出可验证、可回滚、可讲清楚的工程改动
