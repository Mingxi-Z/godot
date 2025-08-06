# Revised Proposal for 2D MSAA Implementation in Godot's GLES3 Renderer (v6)

This document provides a minimal proposal for implementing 2D MSAA in the GLES3 backend. After thorough analysis of the current 3D MSAA implementation and TextureStorage APIs, we found that while the necessary APIs are defined, the core MSAA functionality needs to be implemented in the GLES3 backend.

### 1. Guiding Principles

1. Use existing MSAA infrastructure directly with no new additions
2. Maintain consistent behavior between 2D and 3D MSAA
3. Keep proper abstraction boundaries
4. Follow established patterns in the codebase

### 2. Infrastructure Requirements

The TextureStorage class defines the necessary APIs for MSAA support, but requires implementation:

```cpp
class TextureStorage {
public:
    // MSAA Configuration - Partially implemented
    void render_target_set_msaa(RID p_render_target, RS::ViewportMSAA p_msaa);
    RS::ViewportMSAA render_target_get_msaa(RID p_render_target) const;
    
    // FBO Management - Needs MSAA support
    GLuint render_target_get_fbo(RID p_render_target) const;
    void bind_framebuffer(GLuint framebuffer);
    
    // MSAA Resolve - Needs implementation
    void render_target_do_msaa_resolve(RID p_render_target);

private:
    // Internal methods needing MSAA implementation
    void _update_render_target(RenderTarget *rt);
    void _clear_render_target(RenderTarget *rt);
};
```

Key implementation requirements:
1. MSAA buffer creation in `_update_render_target`
2. MSAA-aware FBO management
3. Complete MSAA resolve implementation
4. Proper cleanup in `_clear_render_target`

### 3. Implementation Approach

The implementation requires changes in both the GLES3 backend and viewport rendering:

1. **GLES3 Backend Implementation**:
```cpp
// In drivers/gles3/storage/texture_storage.cpp
void TextureStorage::_update_render_target(RenderTarget *rt) {
    // ... existing initialization ...

    if (rt->msaa > RS::VIEWPORT_MSAA_DISABLED) {
        // Create MSAA color buffer
        glGenTextures(1, &rt->msaa_color);
        glBindTexture(GL_TEXTURE_2D_MULTISAMPLE, rt->msaa_color);
        glTexImage2DMultisample(GL_TEXTURE_2D_MULTISAMPLE, 
            rt->msaa, rt->color_internal_format,
            rt->width, rt->height, GL_TRUE);

        // Create and set up MSAA FBO
        glGenFramebuffers(1, &rt->msaa_fbo);
        glBindFramebuffer(GL_FRAMEBUFFER, rt->msaa_fbo);
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
            GL_TEXTURE_2D_MULTISAMPLE, rt->msaa_color, 0);

        // Verify FBO completeness
        GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
        ERR_FAIL_COND_MSG(status != GL_FRAMEBUFFER_COMPLETE,
            "MSAA framebuffer creation failed");
    }
}
```

2. **Viewport Integration**:
```cpp
// In servers/rendering/renderer_viewport.cpp
void RendererViewport::_draw_viewport() {
    // ... existing code before 2D drawing ...

    if (can_draw_2d) {
        RS::ViewportMSAA msaa_mode = RSG::texture_storage->
            render_target_get_msaa(p_viewport->render_target);
        bool msaa_2d_active = msaa_mode > RS::VIEWPORT_MSAA_DISABLED;

        if (msaa_2d_active) {
            // Use MSAA FBO for drawing
            RenderTarget *rt = RSG::texture_storage->
                get_render_target(p_viewport->render_target);
            ERR_FAIL_NULL(rt);
            ERR_FAIL_COND(!rt->msaa_fbo);
            
            RSG::texture_storage->bind_framebuffer(rt->msaa_fbo);
        }

        // ... ALL existing 2D drawing logic ...

        if (msaa_2d_active) {
            RSG::texture_storage->render_target_do_msaa_resolve(
                p_viewport->render_target);
        }
    }
}
```

The implementation requires:
1. MSAA buffer creation in render target initialization:
   - Multisampled color texture creation
   - MSAA framebuffer setup and validation
   - Format and sample count handling

2. Buffer management:
   - Proper FBO binding sequence
   - Format compatibility checks
   - Error handling for unsupported configurations

3. Resource cleanup:
   - MSAA texture deletion
   - MSAA FBO cleanup
   - State restoration

### 4. Existing MSAA Components

The MSAA infrastructure is already complete and ready to use:

1. **MSAA Buffer Management (Needs Implementation)**:
- Buffer creation in `_update_render_target` is incomplete
- Resource cleanup exists in `render_target_free` but needs MSAA-specific updates
- Size change handling needs MSAA-specific logic

2. **MSAA State Management (Partially Complete)**:
- MSAA configuration via `render_target_set_msaa` exists but warns "2D MSAA is not yet supported"
- State querying via `render_target_get_msaa` works correctly 
- Buffer allocation/deallocation needs implementation

3. **MSAA Resolve (Needs Implementation)**:
```cpp
// Currently empty in GLES3 backend
void TextureStorage::render_target_do_msaa_resolve(RID p_render_target) {
    // TODO: Implement MSAA resolve
    // Required steps:
    // 1. Get render target and validate MSAA is enabled
    // 2. Bind MSAA framebuffer as read buffer
    // 3. Bind regular framebuffer as draw buffer
    // 4. Use glBlitFramebuffer to resolve:
    //    glBlitFramebuffer(0, 0, width, height,
    //                      0, 0, width, height,
    //                      GL_COLOR_BUFFER_BIT,
    //                      GL_NEAREST);
}
    
### 5. Implementation Details

1. **MSAA Buffer Creation**:
```cpp
void TextureStorage::_update_render_target(RenderTarget *rt) {
    // ... existing initialization ...

    if (rt->msaa > RS::VIEWPORT_MSAA_DISABLED) {
        // Set up MSAA color format
        GLenum internal_format = rt->color_internal_format;
        GLsizei samples = get_msaa_sample_count(rt->msaa);
        
        // Create MSAA texture
        glGenTextures(1, &rt->msaa_color);
        glBindTexture(GL_TEXTURE_2D_MULTISAMPLE, rt->msaa_color);
        glTexImage2DMultisample(GL_TEXTURE_2D_MULTISAMPLE,
            samples, internal_format, rt->width, rt->height, GL_TRUE);
        
        // Create MSAA FBO
        glGenFramebuffers(1, &rt->msaa_fbo);
        glBindFramebuffer(GL_FRAMEBUFFER, rt->msaa_fbo);
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
            GL_TEXTURE_2D_MULTISAMPLE, rt->msaa_color, 0);
            
        // Validate FBO
        GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
        if (status != GL_FRAMEBUFFER_COMPLETE) {
            // Clean up on failure
            glDeleteFramebuffers(1, &rt->msaa_fbo);
            glDeleteTextures(1, &rt->msaa_color);
            rt->msaa_fbo = 0;
            rt->msaa_color = 0;
            rt->msaa = RS::VIEWPORT_MSAA_DISABLED;
            ERR_PRINT("MSAA framebuffer creation failed");
        }
    }
}
```

2. **MSAA Resolve Implementation**:
```cpp
void TextureStorage::render_target_do_msaa_resolve(RID p_render_target) {
    RenderTarget *rt = render_target_owner.get_or_null(p_render_target);
    ERR_FAIL_NULL(rt);
    
    if (rt->msaa <= RS::VIEWPORT_MSAA_DISABLED || !rt->msaa_fbo) {
        return;
    }

    // Store current FBO binding
    GLint current_fbo;
    glGetIntegerv(GL_FRAMEBUFFER_BINDING, &current_fbo);
    
    // Set up resolve
    glBindFramebuffer(GL_READ_FRAMEBUFFER, rt->msaa_fbo);
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, rt->fbo);
    
    // Perform resolve blit
    glBlitFramebuffer(
        0, 0, rt->width, rt->height,
        0, 0, rt->width, rt->height,
        GL_COLOR_BUFFER_BIT, GL_NEAREST
    );
    
    // Restore previous FBO binding
    glBindFramebuffer(GL_FRAMEBUFFER, current_fbo);
}
```

3. **Cleanup Implementation**:
```cpp
void TextureStorage::_clear_render_target(RenderTarget *rt) {
    if (rt->msaa_fbo) {
        glDeleteFramebuffers(1, &rt->msaa_fbo);
        rt->msaa_fbo = 0;
    }
    if (rt->msaa_color) {
        glDeleteTextures(1, &rt->msaa_color);
        rt->msaa_color = 0;
    }
    // ... existing cleanup code ...
}
```

### 6. Integration Points

Key integration points in the engine:

1. **Viewport Configuration**:
```cpp
// In scene/main/viewport.cpp
void Viewport::set_msaa_2d(ViewportMSAA p_msaa) {
    if (p_msaa == msaa_2d) {
        return;
    }
    msaa_2d = p_msaa;
    RS::get_singleton()->viewport_set_msaa_2d(viewport, msaa_2d);
}

// In servers/rendering/renderer_viewport.cpp
void RendererViewport::viewport_set_msaa_2d(RID p_viewport, RS::ViewportMSAA p_msaa) {
    Viewport *viewport = viewport_owner.get_or_null(p_viewport);
    ERR_FAIL_NULL(viewport);
    
    if (viewport->render_target.is_valid()) {
        RSG::texture_storage->render_target_set_msaa(
            viewport->render_target, p_msaa);
    }
}
```

2. **Rendering Pipeline Integration**:
```cpp
// In servers/rendering/renderer_viewport.cpp
void RendererViewport::draw_viewport() {
    // ... 3D rendering ...

    if (can_draw_2d) {
        RenderTarget *rt = RSG::texture_storage->get_render_target(
            viewport->render_target);
        ERR_FAIL_NULL(rt);
        
        if (rt->msaa > RS::VIEWPORT_MSAA_DISABLED && rt->msaa_fbo) {
            // Switch to MSAA FBO for 2D rendering
            RSG::texture_storage->bind_framebuffer(rt->msaa_fbo);
            
            // Clear MSAA buffer if needed
            if (viewport->clear_mode != RS::VIEWPORT_CLEAR_NEVER) {
                glClearColor(0, 0, 0, 0);
                glClear(GL_COLOR_BUFFER_BIT);
            }
        }

        // ... 2D rendering ...

        if (rt->msaa > RS::VIEWPORT_MSAA_DISABLED && rt->msaa_fbo) {
            // Resolve MSAA after 2D pass
            RSG::texture_storage->render_target_do_msaa_resolve(
                viewport->render_target);
        }
    }
}

### 7. Testing Plan

1. **MSAA Buffer Creation**:
   - Verify MSAA texture creation with different sample counts (2x, 4x, 8x)
   - Test format compatibility across different GL implementations
   - Validate FBO completeness checks and error handling
   - Check memory allocation patterns and VRAM usage

2. **2D Rendering Pipeline**:
   - Verify correct FBO binding sequence
   - Test clear color handling with MSAA buffers
   - Validate ordering with canvas item rendering
   - Check alpha blending and transparency
   - Test with different viewport clear modes

3. **MSAA Resolve**:
   - Verify blit operation correctness
   - Test resolve timing and synchronization
   - Check for artifacts at buffer edges
   - Validate state restoration after resolve
   - Profile resolve performance impact

4. **Resource Management**:
   - Test MSAA buffer cleanup on viewport resize
   - Verify memory cleanup on render target destruction
   - Check for resource leaks during rapid MSAA changes
   - Monitor VRAM usage patterns
   - Test proper cleanup during scene changes

5. **Platform Compatibility**:
   - Test on OpenGL ES 3.0 compliant devices
   - Verify behavior on different GPU vendors:
     * NVIDIA (Desktop GL)
     * AMD (Desktop GL)
     * Intel (Desktop GL)
     * Mali (GLES3)
     * Adreno (GLES3)
     * PowerVR (GLES3)
   - Validate MSAA support detection
   - Test fallback behavior when MSAA is unsupported

6. **Edge Cases and Error Conditions**:
   - Test rapid viewport resizing with active MSAA
   - Verify behavior with invalid MSAA levels
   - Check error handling for out-of-memory conditions
   - Test with extreme viewport sizes
   - Validate behavior during low memory conditions
   - Check for race conditions in multithreaded rendering

### 8. Implementation Timeline

1. **Phase 1: MSAA Buffer Management** (1 week)
   - Implement MSAA texture creation in `_update_render_target`
   - Add format compatibility checks
   - Implement proper cleanup in `_clear_render_target`
   - Add MSAA state validation
   - Unit test buffer management

2. **Phase 2: MSAA Resolve Implementation** (1 week)
   - Implement `render_target_do_msaa_resolve`
   - Add state management and restoration
   - Implement error handling
   - Add performance monitoring
   - Unit test resolve functionality

3. **Phase 3: Viewport Integration** (1 week)
   - Update viewport MSAA configuration
   - Implement MSAA-aware rendering pipeline
   - Add clear color handling
   - Test viewport resize handling
   - Add viewport state validation

4. **Phase 4: Testing and Optimization** (1 week)
   - Execute comprehensive test plan
   - Profile MSAA performance impact
   - Optimize buffer creation/deletion
   - Test platform compatibility
   - Fix identified issues

5. **Phase 5: Documentation and Examples** (3-4 days)
   - Document MSAA API usage
   - Create example scenes
   - Add implementation notes
   - Document platform limitations
   - Update contributor guidelines

Total estimated time: 4-5 weeks

### 9. Implementation Steps

1. **Update MSAA Configuration**:
```cpp
void TextureStorage::render_target_set_msaa(RID p_render_target, RS::ViewportMSAA p_msaa) {
    RenderTarget *rt = render_target_owner.get_or_null(p_render_target);
    ERR_FAIL_NULL(rt);
    ERR_FAIL_COND(rt->direct_to_screen);
    
    // Check MSAA support
    if (p_msaa != RS::VIEWPORT_MSAA_DISABLED) {
        GLint max_samples;
        glGetIntegerv(GL_MAX_SAMPLES, &max_samples);
        ERR_FAIL_COND_MSG(get_msaa_sample_count(p_msaa) > max_samples,
            "MSAA sample count not supported by hardware");
    }

    if (p_msaa == rt->msaa) {
        return;
    }

    _clear_render_target(rt);
    rt->msaa = p_msaa;
    _update_render_target(rt);
}
```

2. **Add Helper Functions**:
```cpp
// In texture_storage.h
private:
    static GLsizei get_msaa_sample_count(RS::ViewportMSAA p_msaa) {
        switch (p_msaa) {
            case RS::VIEWPORT_MSAA_2X: return 2;
            case RS::VIEWPORT_MSAA_4X: return 4;
            case RS::VIEWPORT_MSAA_8X: return 8;
            case RS::VIEWPORT_MSAA_16X: return 16;
            default: return 0;
        }
    }

    static String get_framebuffer_error(GLenum p_status) {
        switch (p_status) {
            case GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT:
                return "GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT";
            case GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT:
                return "GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT";
            case GL_FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER:
                return "GL_FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER";
            case GL_FRAMEBUFFER_INCOMPLETE_READ_BUFFER:
                return "GL_FRAMEBUFFER_INCOMPLETE_READ_BUFFER";
            case GL_FRAMEBUFFER_UNSUPPORTED:
                return "GL_FRAMEBUFFER_UNSUPPORTED";
            default:
                return "Unknown error";
        }
    }
```

3. **Update RenderTarget Struct**:
```cpp
struct RenderTarget {
    // ... existing members ...
    
    // MSAA state
    GLuint msaa_fbo = 0;
    GLuint msaa_color = 0;
    RS::ViewportMSAA msaa = RS::VIEWPORT_MSAA_DISABLED;
    bool msaa_needs_resolve = false;
    
    // ... rest of struct ...
};
```

This implementation provides a robust foundation for 2D MSAA support in the GLES3 backend with proper error handling, state management, and hardware capability checks.