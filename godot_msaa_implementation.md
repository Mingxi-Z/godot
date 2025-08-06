I have read the `rasterizer_storage_gles3.cpp` and `rasterizer_scene_gles3.cpp` files. Based on the code and my knowledge of OpenGL, here's how Godot implements 3D MSAA in the GLES3 backend:

### 1. MSAA Buffer Creation and Management

-   **Explicit MSAA Framebuffer:** When MSAA is enabled on a viewport, Godot's GLES3 backend creates a dedicated framebuffer object (FBO) with multisampled attachments. This is handled within the `RasterizerStorageGLES3` class.
-   **Multisampled Textures and Renderbuffers:**
    -   A multisampled color texture (`GL_TEXTURE_2D_MULTISAMPLE`) is created to store the color information for each sample.
    -   A multisampled renderbuffer is created for the depth and stencil buffers using `glRenderbufferStorageMultisample`.
-   **`GLES3::RenderTarget` struct:** The `GLES3::RenderTarget` struct contains all the necessary information for the MSAA framebuffer, including the IDs of the multisampled color texture, the FBO, and the depth/stencil renderbuffers.

The following code from `drivers/gles3/rasterizer_storage_gles3.cpp` shows the creation of the MSAA framebuffer and its attachments:

```cpp
if (rt->msaa > RS::VIEWPORT_MSAA_DISABLED) {
    glGenTextures(1, &rt->msaa_color);
    glBindTexture(GL_TEXTURE_2D_MULTISAMPLE, rt->msaa_color);
    glTexImage2DMultisample(GL_TEXTURE_2D_MULTISAMPLE, rt->msaa, gl_internal_format, rt->width, rt->height, true);

    glGenFramebuffers(1, &rt->msaa_fbo);
    glBindFramebuffer(GL_FRAMEBUFFER, rt->msaa_fbo);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D_MULTISAMPLE, rt->msaa_color, 0);

    glGenRenderbuffers(1, &rt->msaa_depth);
    glBindRenderbuffer(GL_RENDERBUFFER, rt->msaa_depth);
    glRenderbufferStorageMultisample(GL_RENDERBUFFER, rt->msaa, gl_depth_internal_format, rt->width, rt->height);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, rt->msaa_depth);

    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (status != GL_FRAMEBUFFER_COMPLETE) {
        WARN_PRINT("Could not create MSAA FBO!");
        _render_target_clear(rt);
        return;
    }
}
```

### 2. Clearing the MSAA Buffer

-   **Standard `glClear`:** The clearing of the color, depth, and stencil buffers is done using the standard `glClear()` function. When the MSAA FBO is bound, `glClear` automatically clears all the samples within each pixel. This is done at the beginning of the `_render_scene` function.

From `drivers/gles3/rasterizer_scene_gles3.cpp`:

```cpp
if (p_pass_mode == PASS_MODE_COLOR) {
    //clear color/depth/stencil
    glClearColor(p_clear_color.r, p_clear_color.g, p_clear_color.b, p_clear_color.a);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
}
```

### 3. Updating/Rendering to the MSAA Buffer

-   **Direct Rendering:** All 3D objects are rendered directly into the bound MSAA framebuffer. The GPU's rasterizer handles the multisample rendering, running the fragment shader for each covered sample. The draw calls (`glDrawArrays`, `glDrawElements`) target the MSAA FBO. This is handled by the `_render_list` function in `rasterizer_scene_gles3.cpp`.

### 4. Integration into the Rendering Pipeline (Resolve)

-   **Explicit Resolve with `glBlitFramebuffer`:** The "resolve" step, where the multiple samples per pixel are combined into a single color, is performed explicitly using `glBlitFramebuffer`.
-   **`blit_render_targets_to_screen`:** At the end of the frame, `RasterizerGLES3::blit_render_targets_to_screen` is called. This function binds the MSAA framebuffer as the `GL_READ_FRAMEBUFFER` and the default (non-multisampled) framebuffer as the `GL_DRAW_FRAMEBUFFER`.
-   **The Blit Operation:** The call to `glBlitFramebuffer` copies the contents of the read buffer to the draw buffer, and in the process, the GPU resolves the multisampled data into a single-sampled image in the back buffer, which is then presented to the screen.

From `drivers/gles3/rasterizer_gles3.cpp`:

```cpp
void RasterizerGLES3::blit_render_targets_to_screen(RID p_render_target, const Rect2i &p_screen_rect, int p_screen) {
    GLES3::RenderTarget *rt = GLES3::TextureStorage::get_singleton()->get_render_target(p_render_target);
    if (!rt) {
        return;
    }

    if (rt->msaa > RS::VIEWPORT_MSAA_DISABLED) {
        glBindFramebuffer(GL_READ_FRAMEBUFFER, rt->msaa_fbo);
        glReadBuffer(GL_COLOR_ATTACHMENT0);
        glBindFramebuffer(GL_DRAW_FRAMEBUFFER, GLES3::TextureStorage::system_fbo);
        glBlitFramebuffer(0, 0, rt->width, rt->height, p_screen_rect.position.x, p_screen_rect.position.y, p_screen_rect.position.x + p_screen_rect.size.width, p_screen_rect.position.y + p_screen_rect.size.height, GL_COLOR_BUFFER_BIT, GL_NEAREST);
    } else {
        // ... non-msaa blit
    }
}
```

### Detailed Data Flow

Here is a step-by-step breakdown of the data flow for a single frame when 3D MSAA is enabled:

1.  **Initialization (Per Viewport)**:
    *   When a `Viewport` is set up with an MSAA mode (e.g., `VIEWPORT_MSAA_3D_4X`), the `RasterizerStorageGLES3` class allocates the necessary resources.
    *   An FBO is generated specifically for the MSAA render target.
    *   A multisampled 2D texture (`GL_TEXTURE_2D_MULTISAMPLE`) is created for the color buffer.
    *   A multisampled renderbuffer is created for the depth/stencil buffer.
    *   These are attached to the MSAA FBO. This FBO now serves as the primary drawing surface for the 3D scene.

2.  **Rendering the Scene**:
    *   At the beginning of a frame, `RasterizerSceneGLES3::_render_scene` is called.
    *   The MSAA FBO is bound as the active framebuffer.
    *   `glClear` is called to clear the multisampled color, depth, and stencil attachments of the bound FBO.
    *   The renderer iterates through the visible 3D objects. For each object, it sets the appropriate shader, binds uniforms, and issues a draw call (`glDrawArrays` or `glDrawElements`).
    *   The GPU rasterizes the geometry, and for each pixel covered by a primitive, it runs the fragment shader for each of the sub-pixel samples, storing the results in the multisampled color buffer.

3.  **Resolving the MSAA Buffer**:
    *   After all 3D rendering is complete, the `RasterizerGLES3::blit_render_targets_to_screen` function is called.
    *   This function prepares for the MSAA resolve by setting the `GL_READ_FRAMEBUFFER` to the MSAA FBO and the `GL_DRAW_FRAMEBUFFER` to the default window framebuffer (or an intermediate buffer if post-processing is active).
    *   `glBlitFramebuffer` is called. This command instructs the GPU to copy the image from the read framebuffer to the draw framebuffer. Because the source is multisampled and the destination is single-sampled, the GPU automatically performs the "resolve" operation, averaging the samples for each pixel to produce a final, anti-aliased color.

4.  **Final Presentation**:
    *   The resolved, single-sampled image now resides in the window's back buffer.
    *   `DisplayServer::swap_buffers()` is called, which presents this final image to the screen.

This entire process is encapsulated within the renderer and happens automatically whenever 3D MSAA is enabled for a viewport.