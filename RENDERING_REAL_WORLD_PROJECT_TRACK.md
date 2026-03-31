# Rendering Real-World Project Track

## 用法

这份文档是后续 Sprint 的总索引。

它不是另起炉灶的新计划，而是把 [GODOT_RENDERING_CLOSED_LOOP_STANDARD.md](GODOT_RENDERING_CLOSED_LOOP_STANDARD.md) 里的主题拆成真正可执行的项目轨道。

默认规则不变:

1. 真实 bug 优先于纯训练题
2. 每轮都要同时包含硬知识、Godot 代码链、真实项目、验证和面试表达
3. 不能退化成只打日志、只看变量、只改一行 shader

## 与 Standard 的一一对应

1. Sprint 01: `CPU/GPU 心智模型 + 渲染主链`
   任务单: [SPRINT_01_CPU_GPU_RENDER_CHAIN_TASKS.md](SPRINT_01_CPU_GPU_RENDER_CHAIN_TASKS.md)
2. Sprint 02: `坐标空间与变换 + 深度重建语义`
   任务单: [SPRINT_02_DEPTH_SPACE_RECONSTRUCTION_TASKS.md](SPRINT_02_DEPTH_SPACE_RECONSTRUCTION_TASKS.md)
3. Sprint 03: `光栅化管线 + 可见性与渲染组织`
   任务单: [SPRINT_03_OCCLUSION_CULLING_ANGLE_REGRESSION_TASKS.md](SPRINT_03_OCCLUSION_CULLING_ANGLE_REGRESSION_TASKS.md)
4. Sprint 04: `阴影 / GI / Reflection Probe`
   任务单: [SPRINT_04_SHADOW_GI_REFLECTION_PROBE_TASKS.md](SPRINT_04_SHADOW_GI_REFLECTION_PROBE_TASKS.md)
5. Sprint 05: `PBR 与材质 + 光照/BRDF 行为`
   任务单: [SPRINT_04_PBR_SPECULAR_ENERGY_TASKS.md](SPRINT_04_PBR_SPECULAR_ENERGY_TASKS.md)
6. Sprint 06: `Shader 数据通道 + 资源/状态管理`
   任务单: [SPRINT_05_VOLUMETRIC_FOG_DENSITY_MULTIPLIER_TASKS.md](SPRINT_05_VOLUMETRIC_FOG_DENSITY_MULTIPLIER_TASKS.md)
7. Sprint 07: `屏幕后处理、Compositor 与 Temporal 系统`
   任务单: [SPRINT_06_RENDER_SCENE_BUFFERS_RD_COMMON_BUFFER_ACCESS_TASKS.md](SPRINT_06_RENDER_SCENE_BUFFERS_RD_COMMON_BUFFER_ACCESS_TASKS.md)
8. Sprint 08: `多后端与精度问题`
   任务单: [SPRINT_07_MULTI_BACKEND_SHADER_PARITY_TASKS.md](SPRINT_07_MULTI_BACKEND_SHADER_PARITY_TASKS.md)

## 为什么这样排

这条轨道是按依赖顺序排的:

1. 先学会看见 GPU 已经算出来的东西
2. 再学会正确解释空间和深度
3. 再进入 visibility / culling 这种真正影响“画没画出来”的行为问题
4. 再单独吃透 shadow / GI / ReflectionProbe 这些真正的系统级渲染模块
5. 再啃 PBR / BRDF 这种数学和材质链都要懂的问题
6. 再做一条完整 CPU -> GPU 参数链的功能题
7. 再回到 screen-space / compositor / temporal 这种最容易链路断掉的系统
8. 最后把前面的能力推进到多路径、多后端、精度和 shader 生成层面

如果跳过前面直接做后面，大概率会退化成:

1. 只改一处局部
2. 不知道数据链从哪来
3. 讲不清为什么改这一层
4. 无法证明没有引入兼容性和平台风险

## 每轮真实锚点

### Sprint 01

1. [#10396 Access more common buffers in RenderSceneBuffersRD](https://github.com/godotengine/godot-proposals/issues/10396)
2. [#798 Access different viewport buffers through ViewportTextures ("G-buffer")](https://github.com/godotengine/godot-proposals/issues/798)
3. [#90148 Depth texture returned by RenderSceneBuffersRD is upside down and in sRGB colorspace](https://github.com/godotengine/godot/issues/90148)
4. [#85107 Getting depth texture from viewport loses precision](https://github.com/godotengine/godot/issues/85107)

### Sprint 02

1. [#90148 Depth texture returned by RenderSceneBuffersRD is upside down and in sRGB colorspace](https://github.com/godotengine/godot/issues/90148)
2. [#85107 Getting depth texture from viewport loses precision](https://github.com/godotengine/godot/issues/85107)
3. [#798 Access different viewport buffers through ViewportTextures ("G-buffer")](https://github.com/godotengine/godot-proposals/issues/798)

### Sprint 03

1. [#106184 Occlusion culling doesn't cull objects from all viewing angles](https://github.com/godotengine/godot/issues/106184)

### Sprint 04

1. 默认主项目:
   [#116682 Vulkan: Non-emitting GPUParticles3D cause draw call in "Shadow Render" pass](https://github.com/godotengine/godot/issues/116682)
2. 后续深化备选:
   [#106892 Shadow map not updated for billboard sprites when the camera moves](https://github.com/godotengine/godot/issues/106892)
3. probe 方向备选:
   [#113676 Stretch marks and artifacts on environment octmaps](https://github.com/godotengine/godot/issues/113676)

### Sprint 05

1. [#111853 specular highlights of low roughness surfaces break conservation of energy for big light sources](https://github.com/godotengine/godot/issues/111853)

### Sprint 06

1. [#11324 Add a volumetric fog density multiplier texture to better represent high-frequency detail](https://github.com/godotengine/godot-proposals/issues/11324)

### Sprint 07

1. [#10396 Access more common buffers in RenderSceneBuffersRD](https://github.com/godotengine/godot-proposals/issues/10396)
2. [#798 Access different viewport buffers through ViewportTextures ("G-buffer")](https://github.com/godotengine/godot-proposals/issues/798)
3. [#90148 Depth texture returned by RenderSceneBuffersRD is upside down and in sRGB colorspace](https://github.com/godotengine/godot/issues/90148)
4. [#85107 Getting depth texture from viewport loses precision](https://github.com/godotengine/godot/issues/85107)
5. [#115210 Velocity buffer and scene buffer uniform not clean at the first and second frame](https://github.com/godotengine/godot/issues/115210)

### Sprint 08

1. [#112283 Heavy bloat in generated unlit "unshaded" shader (Metal)](https://github.com/godotengine/godot/issues/112283)

## 每轮共同产物

不管做哪一轮，产物都不能缩水:

1. `chain_map.md`
2. `official_docs_note.md`
3. `design_note.md`
4. `patch.diff`
5. `gpu_capture.md`
6. `validation.md`
7. `risk_note.md`
8. `interview_pitch.md`

另外，每轮默认都要满足这两个过程要求:

1. 至少查 2 篇官方文档，并记录它们和源码/issue 的对应关系
2. 至少做 1 次 GPU frame capture，并记录本轮最关键的 pass / attachment / draw 证据

## 最后一句话

后面的 Sprint 不是“后续有空再想”的占位符。

它们现在已经全部按 standard 的主题固定好了，后面默认就沿着这条轨道推进，除非某个更强的真实 issue 明确值得插队。
