Shader "AnimationInstancing/URPAnimationLitShader"
{
    Properties
    {
		[Header(Base)]
        [MainTexture] _BaseMap("Base Map", 2D) = "white" {}
        [MainColor] _BaseColor("Base Color", Color) = (1,1,1,1)
        [HideInInspector] _MainTex("Legacy Texture", 2D) = "white" {}
        [HideInInspector] _Color("Legacy Color", Color) = (1,1,1,1)
    	
		[Space(20)][Header(Metallic)]
        _Metallic("Metallic", Range(0, 1)) = 0
        [NoScaleOffset] _MetallicGlossMap("Metallic Map", 2D) = "white" {}
        _Smoothness("Smoothness", Range(0, 1)) = 0.5

    	[Space(20)][Header(Normal)]
		[NoScaleOffset][Normal] _BumpMap("Normal Map", 2D) = "bump" {}
        _BumpScale("Normal Scale", Float) = 1
        [HideInInspector] _NormalMap("Legacy Normal Map", 2D) = "bump" {}
        [HideInInspector] _NormalScale("Legacy Normal Scale", Float) = 1

        [Space(20)][Header(Occlusion)]
        [NoScaleOffset] _OcclusionMap("Occlusion Map", 2D) = "white" {}
        _OcclusionStrength("Occlusion Strength", Range(0, 1)) = 1
    	
    	[Space(20)][Header(Emission)]
    	[Toggle(_EMISSION_ON)] _EMISSION_ON("Emission On", Float) = 0
    	[NoScaleOffset] _EmissionMap("Emission Map", 2D) = "black" {}
		[HDR] _EmissionColor("Emission Color", Color) = (0, 0, 0)
    	
	    [HideInInspector][Toggle(_SMOOTHNESS_ON)] _SMOOTHNESS_ON("Legacy Smoothness On", Float) = 0
    	
    	[Space(20)][Header(Ambient)]
    	[Toggle(_AMBIENT_ON)] _AMBIENT_ON("Ambient On", Float) = 0
    	_EnviIntensity("Environment Lighting", Range(0,1)) = 1
    	
        [HideInInspector]_boneTextureBlockWidth("_boneTextureBlockWidth", int) = 0
		[HideInInspector]_boneTextureBlockHeight("_boneTextureBlockHeight", int) = 0
		[HideInInspector]_boneTextureWidth("_boneTextureWidth", int) = 0
		[HideInInspector]_boneTextureHeight("_boneTextureHeight", int) = 0
    }
    SubShader
    {
        Tags{ "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True" }
        LOD 200

        Pass
        {
        	Name "ForwardLit"
			Tags{ "LightMode" = "UniversalForwardOnly" }
        	
            Blend SrcAlpha OneMinusSrcAlpha
			ZWrite On
			ZTest LEqual
			Cull Back
            
            HLSLPROGRAM
			#pragma exclude_renderers gles gles3 glcore
			#pragma target 3.0

            // Universal Pipeline keywords
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
			#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
			#pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
			#pragma multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
			#pragma multi_compile_fragment _ _LIGHT_COOKIES
			#pragma multi_compile _ _LIGHT_LAYERS
			#pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
			#pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
			#pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
			#pragma multi_compile_fragment _ _REFLECTION_PROBE_ATLAS
			#pragma multi_compile_fragment _ REFLECTION_PROBE_ROTATION
			
			#pragma shader_feature_local _NORMALMAP
			#pragma shader_feature_local_fragment _ALPHATEST_ON
			#pragma shader_feature_local_fragment _ALPHAPREMULTIPLY_ON
			#pragma shader_feature_local_fragment _EMISSION
			#pragma shader_feature_local_fragment _METALLICSPECGLOSSMAP
			#pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
			#pragma shader_feature_local_fragment _OCCLUSIONMAP
			//#pragma shader_feature_local _PARALLAXMAP
			//#pragma shader_feature_local _ _DETAIL_MULX2 _DETAIL_SCALED
			#pragma shader_feature_local_fragment _SPECULARHIGHLIGHTS_OFF
			//#pragma shader_feature_local_fragment _ENVIRONMENTREFLECTIONS_OFF
			#pragma shader_feature_local _ENVIRONMENTREFLECTIONS_OFF
			#pragma shader_feature_local_fragment _SPECULAR_SETUP
			//#pragma shader_feature_local _RECEIVE_SHADOWS_OFF

            // -------------------------------------
			// Unity defined keywords
			#pragma multi_compile _ DIRLIGHTMAP_COMBINED
			#pragma multi_compile _ LIGHTMAP_ON
			#pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
			#pragma multi_compile _ SHADOWS_SHADOWMASK
			#pragma multi_compile _ _CLUSTER_LIGHT_LOOP
			#pragma multi_compile_fog
			//--------------------------------------
			// GPU Instancing
			#pragma multi_compile_instancing
			#pragma multi_compile _ DOTS_INSTANCING_ON

            #pragma shader_feature_local _EMISSION_ON
            #pragma shader_feature_local _SMOOTHNESS_ON
            #pragma shader_feature_local _AMBIENT_ON
            
            #pragma vertex vertn
            #pragma fragment frag
            #pragma multi_compile_forwardadd

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
            #include "URPAnimationInstancingBaseCustom.hlsl"

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldPosition : TEXCOORD1;
            	float3 viewDirection : TEXCOORD2;
            	float3 normal   : NORMAL;
                float3 tangent  : TEXCOORD3;
                float3 biTangent    : TEXCOORD4;
            	float4 shadowCoord  : TEXCOORD5;
            	float4 fogCoord : TEXCOORD6;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            v2f vertn (appdata v)
            {
                v2f o;

                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);

            	vert(v);
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
				o.uv = TRANSFORM_TEX(v.texcoord, _BaseMap);
                o.worldPosition = TransformObjectToWorld(v.vertex.xyz);
				o.normal = normalize(TransformObjectToWorldNormal(v.normal));
            	o.viewDirection = normalize(_WorldSpaceCameraPos.xyz - o.worldPosition.xyz);
				o.tangent = normalize(TransformObjectToWorldDir(v.tangent.xyz));
				o.biTangent = normalize(cross(o.normal, o.tangent)) * v.tangent.w;
            	o.shadowCoord = TransformWorldToShadowCoord(o.worldPosition);
            	o.fogCoord = ComputeFogFactor(o.vertex.z);
                
                return o;
            }

            half4 SampleMetallicGloss(float2 uv, half albedoAlpha)
            {
                half4 metallicGloss;

                #if defined(_METALLICSPECGLOSSMAP)
                metallicGloss = SAMPLE_TEXTURE2D(_MetallicGlossMap, sampler_MetallicGlossMap, uv);
                #if defined(_SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A)
                metallicGloss.a = albedoAlpha * _Smoothness;
                #else
                metallicGloss.a *= _Smoothness;
                #endif
                #else
                metallicGloss = half4(_Metallic, _Metallic, _Metallic, _Smoothness);
                #endif

                return metallicGloss;
            }

            half SampleOcclusion(float2 uv)
            {
                #if defined(_OCCLUSIONMAP)
                half occlusion = SAMPLE_TEXTURE2D(_OcclusionMap, sampler_OcclusionMap, uv).g;
                return LerpWhiteTo(occlusion, _OcclusionStrength);
                #else
                return half(1.0);
                #endif
            }
            
            float4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                half4 albedoAlpha = SampleAlbedoAlpha(i.uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));
                SurfaceData surfaceData = (SurfaceData)0;
                surfaceData.alpha = albedoAlpha.a * _BaseColor.a;
                surfaceData.albedo = albedoAlpha.rgb * _BaseColor.rgb;

				half4 metallicGloss = SampleMetallicGloss(i.uv, albedoAlpha.a);
                surfaceData.metallic = metallicGloss.r;
                surfaceData.smoothness = metallicGloss.a;
                surfaceData.specular = half3(0.0h, 0.0h, 0.0h);

				float3 NormalTS = SampleNormal(i.uv, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap), _BumpScale);
                float3x3 tbnMatrix = float3x3(i.tangent, i.biTangent, i.normal);
                float3 normalWS = normalize(mul(NormalTS, tbnMatrix));
                surfaceData.normalTS = NormalTS;
                surfaceData.occlusion = SampleOcclusion(i.uv);
                #if defined(_EMISSION_ON) || defined(_EMISSION)
                surfaceData.emission = SAMPLE_TEXTURE2D(_EmissionMap, sampler_EmissionMap, i.uv).rgb * _EmissionColor.rgb;
                #endif

				BRDFData brdfData;
                InitializeBRDFData(surfaceData, brdfData);

				InputData inputData = (InputData)0;
                inputData.positionWS = i.worldPosition;
                inputData.normalWS = normalWS;
                inputData.viewDirectionWS = SafeNormalize(i.viewDirection);
                inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(i.vertex);
                inputData.shadowCoord = i.shadowCoord;
                inputData.shadowMask = half4(1.0h, 1.0h, 1.0h, 1.0h);
				#if defined(_AMBIENT_ON)
                inputData.bakedGI = SampleSH(normalWS) * _EnviIntensity;
                #endif

				#if defined(_SPECULARHIGHLIGHTS_OFF)
                bool specularHighlightsOff = true;
                #else
                bool specularHighlightsOff = false;
                #endif

				const BRDFData noClearCoat = (BRDFData)0;
				half4 shadowMask = CalculateShadowMask(inputData);
                AmbientOcclusionFactor aoFactor = CreateAmbientOcclusionFactor(inputData, surfaceData);
				uint meshRenderingLayers = GetMeshRenderingLayer();
				Light mainLight = GetMainLight(inputData, shadowMask, aoFactor);
                MixRealtimeAndBakedGI(mainLight, normalWS, inputData.bakedGI);

				half3 lighting = 0;
                #ifdef _LIGHT_LAYERS
                if (IsMatchingLightLayer(mainLight.layerMask, meshRenderingLayers))
                #endif
                {
					lighting += LightingPhysicallyBased(brdfData, noClearCoat, mainLight, normalWS, inputData.viewDirectionWS, 0.0h, specularHighlightsOff);
                }

				half3 addLighting = 0;
				#if defined(_ADDITIONAL_LIGHTS)
				#if USE_CLUSTER_LIGHT_LOOP
				[loop] for (uint lightIndex = 0u; lightIndex < min(URP_FP_DIRECTIONAL_LIGHTS_COUNT, MAX_VISIBLE_LIGHTS); ++lightIndex)
				{
					Light addLight = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);
                    #ifdef _LIGHT_LAYERS
                    if (IsMatchingLightLayer(addLight.layerMask, meshRenderingLayers))
                    #endif
					{
						addLighting += LightingPhysicallyBased(brdfData, noClearCoat, addLight, normalWS, inputData.viewDirectionWS, 0.0h, specularHighlightsOff);
					}
				}
				#endif
				LIGHT_LOOP_BEGIN(GetAdditionalLightsCount())
                {
                    Light addLight = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);
                    #ifdef _LIGHT_LAYERS
                    if (IsMatchingLightLayer(addLight.layerMask, meshRenderingLayers))
                    #endif
                    {
						addLighting += LightingPhysicallyBased(brdfData, noClearCoat, addLight, normalWS, inputData.viewDirectionWS, 0.0h, specularHighlightsOff);
                    }
                }
				LIGHT_LOOP_END
				#endif

				half3 indirectLighting = 0;
				#if defined(_AMBIENT_ON)
				indirectLighting = GlobalIllumination(brdfData, noClearCoat, 0.0h, inputData.bakedGI, surfaceData.occlusion,
					i.worldPosition, normalWS, inputData.viewDirectionWS, inputData.normalizedScreenSpaceUV);
				#endif

				half3 finalColor = lighting + addLighting + indirectLighting + surfaceData.emission;
				return half4(MixFog(finalColor, i.fogCoord.x), surfaceData.alpha);
            }
            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags{ "LightMode" = "ShadowCaster" }
            
            ZWrite On
			ZTest LEqual
			ColorMask 0
			Cull Back
            
            HLSLPROGRAM

            #pragma exclude_renderers gles gles3 glcore
            #pragma target 3.0

            // -------------------------------------
			// Material Keywords
			#pragma shader_feature_local_fragment _ALPHATEST_ON
			#pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            //--------------------------------------
			// GPU Instancing
			#pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON
            
            #pragma vertex vertn
            #pragma fragment frag
            #pragma multi_compile_shadowcaster

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "URPAnimationInstancingBaseCustom.hlsl"

            struct v2f
            {
	            float4 vertex : SV_POSITION;
            };
            
            v2f vertn(appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                vert(v);

            	float3 positionWS = TransformObjectToWorld(v.vertex.xyz);
            	float3 normalWS = TransformObjectToWorldNormal(v.normal.xyz);
            	float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, _MainLightPosition.xyz));

				o.vertex = positionCS;
            	
                return o;
            }
            
            half4 frag(v2f i) : SV_Target
            {
                return 0;
            }

            ENDHLSL
        }
    	
    	Pass
		{
			Name "DepthOnly"
			Tags{"LightMode" = "DepthOnly"}

			ZWrite On
			ColorMask 0
			Cull Back

			HLSLPROGRAM
			#pragma exclude_renderers gles gles3 glcore
			#pragma target 3.0

			#pragma vertex DepthOnlyVertexInstanced
			#pragma fragment DepthOnlyFragmentInstanced

			// -------------------------------------
			// Material Keywords
			#pragma shader_feature_local_fragment _ALPHATEST_ON
			#pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

			//--------------------------------------
			// GPU Instancing
			#pragma multi_compile_instancing
			#pragma multi_compile _ DOTS_INSTANCING_ON

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "URPAnimationInstancingBaseCustom.hlsl"

			struct DepthOnlyVaryings
			{
				float4 positionCS : SV_POSITION;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			DepthOnlyVaryings DepthOnlyVertexInstanced(appdata v)
			{
				DepthOnlyVaryings o = (DepthOnlyVaryings)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				vert(v);
				o.positionCS = TransformObjectToHClip(v.vertex.xyz);
				return o;
			}

			half DepthOnlyFragmentInstanced(DepthOnlyVaryings i) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID(i);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
				return i.positionCS.z;
			}
			
			ENDHLSL
		}
    }
}
