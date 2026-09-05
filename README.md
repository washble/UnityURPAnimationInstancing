# Animation Instancing

## Reference

I am working on improving Unity Animation Instancing to be available in URP.

* **Animation Instancing Repository:** [Unity-Technologies/Animation-Instancing](https://github.com/Unity-Technologies/Animation-Instancing?utm_source=chatgpt.com)
* **Unity Blog — Animation Instancing for SkinnedMeshRenderer:** [What is an Animation Instancing? Watch Unity Explain](https://blog.unity.com/engine-platform/animation-instancing-for-skinnedmeshrenderer?utm_source=chatgpt.com)


## Environment

* **Unity:** 6000.3.11f1
* **Rendering:** Animation Instancing
* **Animation System:** Animation Instancing
* **Lighting:** Light Probe / Reflection Probe
* **GPU Instancing:** Enabled
* **Addressables:** Not related to this system

## Current Status

* Animation Instancing is currently used for animated character rendering.
* GPU instanced rendering is working through the Animation Instancing RenderLoop.
* Light Probe / Reflection Probe handling has been implemented in the rendering/shader path.
* **Light Probe / Reflection Probe behavior has not yet been experimentally tested and verified.**

## Why

Animation Instancing is used to reduce the rendering cost of multiple animated characters while maintaining compatible animation and lighting behavior.

## Light Probe / Reflection Probe

* Probe lighting is handled through the Animation Instancing rendering/shader path.
* The implementation is currently **experimental and not yet verified in an actual scene**.
* Light Probe and Reflection Probe behavior must be experimentally tested before being considered confirmed.
* Keep probe behavior compatible with the normal Lit rendering path.
* Avoid introducing separate per-character CPU lighting logic.

## Precautions

* Do not disable GPU Instancing to solve visual issues.
* A missing character does **not** necessarily mean it was culled.
* `RenderLoop.Draw / Draw Mesh (instanced)` may still exist even when the character is visually missing.
* When debugging, check **RenderLoop → Draw → Bounds → Shader/Material → Lighting/Probes** separately.
* Do not modify animation/runtime logic to solve a shader or lighting problem.
* Do not mix this system with Addressables work.
* Any Material modification must consider **all relevant Renderer Types**.
* Check the shader, Material properties, lighting/probe behavior, instancing settings, and rendering behavior for each Renderer Type before considering a Material change complete.

## Modification Rules

1. Identify the responsible layer:

   * Animation
   * Instance Data
   * Bounds / Culling
   * Shader / Material
   * Lighting / Probes
   * Renderer Type

2. Make the smallest change at that layer.

3. When modifying Materials, verify compatibility across **all relevant Renderer Types**.

4. Verify that `Draw Mesh (instanced)` is still generated.

5. When modifying Light Probe / Reflection Probe handling, perform actual scene testing before considering the behavior verified.

6. Verify that GPU instancing and performance are preserved.

## Core Rule

> Preserve the existing Animation Instancing architecture.
> Solve lighting/probe issues primarily through the shader/rendering-data path without sacrificing GPU instancing.
> Any Material change must account for all relevant Renderer Types.
> Light Probe / Reflection Probe behavior must be experimentally verified before being considered stable.

## Spawn

For Animation Instancing-based spawning, follow the spawn flow in `AnimationInstancingCloneSpawner.cs`.

```csharp
// 1. Create the clone through the Animation Instancing Manager
GameObject clone = manager.CreateInstance(template.gameObject);

// 2. URPAnimationInstancing on the clone handles Manager registration
//    (AddBoundingSphere / AddInstance)
```

**Key flow:**

`Template → Animation Instancing Manager → CreateInstance → URPAnimationInstancing registration`

