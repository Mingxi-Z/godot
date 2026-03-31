# Sprint 03: 光栅化管线 + 可见性与渲染组织

## 这轮属于 Standard 的哪一块

这轮严格对应:

1. `光栅化管线`
2. `可见性与渲染组织`
3. `为什么没画出来 / 为什么被剔除了 / 为什么这个 pass 根本没跑`

## 本轮唯一项目

### 项目名

`Occlusion Culling Angle Regression`

### 项目定义

围绕真实 bug [#106184](https://github.com/godotengine/godot/issues/106184)，做一次完整的复现、可视化、定位和修复或可回归诊断。

这轮不是做“多记几条 occlusion 日志”，而是要拿到:

1. 稳定复现
2. 屏幕可见或统计可证的证据
3. 能解释错误角度为什么错

## 这轮对应的真实议题

1. [#106184 Occlusion culling doesn't cull objects from all viewing angles](https://github.com/godotengine/godot/issues/106184)

## 为什么第三轮做它

前两轮你已经能:

1. 看懂主链
2. 看懂 depth / buffer / 空间语义

现在该进入真正的 renderer 行为问题:

1. 同一个对象为什么某些角度被正确剔除
2. 为什么换个角度就失效
3. 这到底是 occluder 数据、视角转换、还是可见性组织的问题

## 这轮不允许退化成什么

下面这些不算完成:

1. 只在 `viewport_set_use_occlusion_culling()` 周围打日志
2. 只打印“当前有多少 occluder”
3. 只能复现但没有证据说明错在哪一类角度
4. 把任何临时 instrumentation 都停留在终端文本

## 本轮必须补到位的硬知识

### 1. 光栅化与深度测试

你必须能讲清:

1. 几何什么时候进入 depth 测试
2. 可见性判断和真正 draw call 的关系
3. occlusion culling 不是“材质不对”，而是“对象是否进入后续渲染”

### 2. 可见性系统

你必须搞清:

1. frustum culling
2. occlusion culling
3. light culling
4. LOD / render list

它们分别在什么阶段介入。

## 必读源码顺序

### A. 先看对外开关和 viewport 状态

1. [rendering_server.cpp](servers/rendering/rendering_server.cpp)
2. [renderer_viewport.cpp](servers/rendering/renderer_viewport.cpp)

你要确认:

1. occlusion culling 是怎么开起来的
2. occlusion buffer 什么时候标脏、什么时候更新
3. `VIEWPORT_DEBUG_DRAW_OCCLUDERS` 现成能帮你看到什么

### B. 再看场景裁剪主链

1. [renderer_scene_cull.cpp](servers/rendering/renderer_scene_cull.cpp)
2. [renderer_scene_render.h](servers/rendering/renderer_scene_render.h)

你要确认:

1. `scene_cull_result` 什么时候准备
2. 渲染前哪些实例已经被剔掉了
3. `p_occluder_debug_tex` 是怎么一路传进 renderer 的

### C. 再看 occluder 和场景对象的数据入口

1. [occluder_instance_3d.cpp](scene/3d/occluder_instance_3d.cpp)
2. [viewport.cpp](scene/main/viewport.cpp)

你要确认:

1. 场景里的 occluder 数据怎么进入 RenderingServer
2. viewport 级别的设置如何影响 3D 场景

## 本轮必须画出的 3 张图

### 图 1: 可见性主链图

只画这一条:

`Viewport -> RendererViewport -> scene cull -> scene_cull_result -> render_scene`

### 图 2: 错误视角图

只画:

1. 正常角度
2. 错误角度
3. 相机、occluder、目标物体三者关系

### 图 3: occlusion debug 数据图

只画:

`use_occlusion_culling -> occlusion buffer / debug texture -> final evidence`

## 代码实现任务

### 任务 1: 先建立稳定复现

你必须得到:

1. 一组固定相机轨迹
2. 一组固定 occluder / target 几何
3. 明确哪些角度错误，哪些角度正确

### 任务 2: 再加最小但有用的可视化

可选方向:

1. occluder 覆盖调试图
2. cull result 统计可视化
3. 错误角度对照视图

但必须是屏幕可见或结果可比，不是终端刷屏。

### 任务 3: 最后定位类别

你必须把问题缩到下面三类之一:

1. occluder 数据不对
2. 视角 / 空间转换不对
3. cull 决策或使用条件不对

## 本轮官方文档要求

至少查下面 2 篇:

1. [Internal rendering architecture](https://docs.godotengine.org/en/latest/contributing/development/core_and_modules/internal_rendering_architecture.html)
2. [OccluderInstance3D](https://docs.godotengine.org/en/stable/classes/class_occluderinstance3d.html)

查阅要求:

1. 记录官方如何描述 renderer 的可见性组织和 occluder 的用途
2. 记录文档层的高层模型和你在 `RendererViewport`、`renderer_scene_cull.cpp` 里看到的具体行为之间的差距

## 本轮 GPU Frame Capture 操作

至少做下面 3 件事:

1. 抓一帧“正确剔除”角度
2. 抓一帧“错误剔除或未剔除”角度
3. 对比两帧中与 occlusion / scene visibility 相关的 draw 结果或 debug texture

记录要求:

1. 至少记录 1 个 before / after capture 差异
2. 至少记录 1 个能证明对象是否仍然进入后续渲染的证据
3. 至少写清 GPU frame capture 在这轮能证明什么、不能证明什么

## 本轮验证矩阵

至少覆盖:

1. 相机绕目标旋转
2. 不同 occluder 尺寸
3. 至少两个被遮挡对象位置
4. 开关 occlusion culling 的 before / after

## 本轮面试通过线

你必须能讲清楚:

1. `#106184` 为什么不是“某个材质没画出来”的问题
2. `scene_cull_result` 和最终 draw 之间是什么关系
3. 你为什么把 instrumentation 放在 viewport / cull / debug texture 这一层
4. 你的修复或诊断工具为什么能稳定回归验证
