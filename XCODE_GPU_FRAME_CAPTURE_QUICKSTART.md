# Xcode GPU Frame Capture Quickstart for Godot

## 目标

这份文档只做一件事:

教你在 macOS 上，用 `Xcode GPU Frame Capture` 抓 Godot 的一帧，并把它变成真正能服务于每个 Sprint 的证据。

它不是 Xcode 全教程。

## 为什么用它

如果你在 macOS 上主要跑的是 Godot 的 Metal 路径，那么默认 GPU 调试工具应该是 `Xcode GPU Frame Capture`。

原因:

1. `RenderDoc` 官方 README 当前公开支持的平台不包含 macOS / Metal
2. `RenderDoc` 的 macOS 跟踪 issue 也明确写了 `Metal or iOS support is not planned at the moment`
3. Apple 官方长期支持 `Xcode` 里的 Metal workload capture

## 先决条件

你至少要有:

1. 已安装 `Xcode`
2. 能在本机运行 Godot 或你编出来的 Godot 二进制
3. 一个能稳定复现当前 Sprint 场景的最小项目

推荐先看:

1. [Godot Xcode docs](https://docs.godotengine.org/en/stable/engine_details/development/configuring_an_ide/xcode.html)
2. [Apple: Capturing a Metal workload in Xcode](https://developer.apple.com/documentation/xcode/capturing-a-metal-workload-in-xcode)
3. [Apple: Capturing Metal commands programmatically](https://developer.apple.com/documentation/metal/capturing-metal-commands-programmatically?changes=_10&language=objc)

## 最简单的工作流

### 路线 A: 先把 Godot 跑进 Xcode

这是最推荐的路线。

1. 按 Godot 官方文档把 Godot 源码工程接进 Xcode
2. 配好可运行的 executable
3. 把目标项目路径作为启动参数传进去
4. 确认你能从 Xcode 正常启动 Godot

如果你已经能在 Xcode 里调试 Godot，这条路最稳。

### 路线 B: 抓一个现成可运行的 Godot app

如果你暂时不想完整接 Xcode 工程，也可以:

1. 先拿一个能在 macOS 上直接运行的 Godot app
2. 用 Xcode 附加或从 Xcode 直接启动它
3. 再做 GPU capture

但从长期看，还是路线 A 更适合做 renderer 学习。

## 第一次 capture 怎么做

下面按最实用的方式来。

1. 在 Xcode 里启动 Godot，并打开你的最小复现场景。
2. 让场景停在你想观察的那一帧附近。
3. 在 Xcode 菜单里使用 GPU capture。
   常见入口是 `Debug` 菜单下的 GPU capture 相关命令，或者 scheme 里开启 GPU Frame Capture。
4. 抓完之后，进入 Xcode 的 GPU capture 视图。

你的第一目标不是看懂所有内容，而是只做这 5 件事:

1. 找到这一帧的 pass 顺序
2. 找到你关心的 render pass
3. 找到相关 color / depth attachment
4. 找到相关 draw call 或 compute dispatch
5. 找到该 pass 读写了哪些资源

## 每个 Sprint 都怎么用

### Sprint 01

你要在 capture 里确认:

1. debug draw 不是重新画场景几何
2. 它是在消费已有 buffer
3. 它最后写回哪个 target

### Sprint 02

你要确认:

1. depth 从哪个 attachment 来
2. 哪个 pass 在消费它
3. 方向、线性化和空间语义错时，结果会怎么表现

### Sprint 03

你要确认:

1. 对象有没有进入错误的 pass
2. before / after 两次 capture 的 pass 级差异

### Sprint 04

你要确认:

1. `Shadow Render` pass 里到底有没有不该存在的 draw
2. 同一对象是否缺席于 `Render Depth Prepass` 或 `Render Opaque`

### Sprint 05

你要确认:

1. 你的新参数或纹理真的进了 GPU 路径
2. 它被哪个 pass 消费

### Sprint 06

你要确认:

1. buffer producer 是谁
2. consumer 是谁
3. temporal 输入和 prev-frame 数据是否干净、是否对齐

### Sprint 08

你要确认:

1. 运行时到底进了哪些 pipeline / pass
2. 某些“膨胀”是不是只停留在生成层，还是已经进入实际运行路径

## 第一次不要做的事

下面这些很容易把自己绕进去:

1. 一上来就试图看懂整帧所有 pass
2. 一上来就看所有 buffer
3. 把 capture 当作“替代源码阅读”
4. 只截图，不记结论

## capture 记录模板

每次至少写这 5 项:

1. 本次工具:
   `Xcode GPU Frame Capture`
2. 本次目标:
   想证明什么
3. 关键 pass:
   名称或你对它的定位
4. 关键资源:
   attachment / texture / buffer
5. 结论:
   这次 capture 证明了什么，没证明什么

## 最低通过线

如果你做完一次 capture，还不能回答下面 3 个问题，就说明还没真正用起来:

1. 这一帧里我关心的问题发生在哪个 pass
2. 这个 pass 在读什么、写什么
3. 这次 capture 到底支持了我哪一个判断

## 参考

1. [Godot Xcode docs](https://docs.godotengine.org/en/stable/engine_details/development/configuring_an_ide/xcode.html)
2. [Apple: Capturing a Metal workload in Xcode](https://developer.apple.com/documentation/xcode/capturing-a-metal-workload-in-xcode)
3. [Apple: Capturing Metal commands programmatically](https://developer.apple.com/documentation/metal/capturing-metal-commands-programmatically?changes=_10&language=objc)
4. [RenderDoc README](https://github.com/baldurk/renderdoc)
5. [RenderDoc macOS tracking issue #1272](https://github.com/baldurk/renderdoc/issues/1272)
