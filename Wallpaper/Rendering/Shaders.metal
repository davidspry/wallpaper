//
//  TextureShader.metal
//  Wallpaper
//
//  Created by David Spry on 9/4/22.
//

#include <metal_stdlib>
#include "Shaders.h"

using namespace metal;

#pragma mark Standard Vertex Data

float4 TexturePosition(unsigned int const vertexId) {
    auto const positions = float4x4(float4(-1.0f, -1.0f, 0.0f, 1.0f),
                                    float4( 1.0f, -1.0f, 0.0f, 1.0f),
                                    float4(-1.0f,  1.0f, 0.0f, 1.0f),
                                    float4( 1.0f,  1.0f, 0.0f, 1.0f));
    
    return positions[vertexId];
}

float2 TextureCoordinate(unsigned int const vertexId) {
    auto const textureCoordinates = float4x2(float2(0.0f, 1.0f),
                                             float2(1.0f, 1.0f),
                                             float2(0.0f, 0.0f),
                                             float2(1.0f, 0.0f));
    
    return textureCoordinates[vertexId];
}

#pragma mark Coordinate Transformations

float2 LocalPosition(float2 const textureCoordinate, float const aspectRatio) {
    auto const normalisedCoordinate = textureCoordinate * 2.0f - 1.0f;
    return aspectRatio < 1.0f
        ? float2(normalisedCoordinate.x, normalisedCoordinate.y / aspectRatio)
        : float2(normalisedCoordinate.x * aspectRatio, normalisedCoordinate.y);
}

#pragma mark - Vertex Shader: Standard Texture

vertex VertexOut TextureVertices(Uniforms constant& uniforms [[buffer(0)]],
                                 unsigned int const vertexId [[vertex_id]]) {
    VertexOut outVertex;
    outVertex.position = uniforms.viewProjectionMatrix * TexturePosition(vertexId);
    outVertex.textureCoordinate = TextureCoordinate(vertexId);
    
    return outVertex;
}

#pragma mark Vertex Shader: Instanced Texture

vertex VertexOut InstancedTextureVertices(Uniforms constant& uniforms [[buffer(0)]],
                                          VertexIn constant* instanceData [[buffer(1)]],
                                          float constant& aspectRatio [[buffer(2)]],
                                          unsigned int const vertexId [[vertex_id]],
                                          unsigned int const instanceId [[instance_id]]) {
    auto const modelViewProjection = uniforms.viewProjectionMatrix * instanceData[instanceId].modelMatrix;
    auto const textureCoordinate = TextureCoordinate(vertexId);
    
    VertexOut outVertex;
    outVertex.position = modelViewProjection * TexturePosition(vertexId);
    outVertex.localPosition = LocalPosition(textureCoordinate, aspectRatio);
    outVertex.textureCoordinate = textureCoordinate;
    outVertex.aspectRatio = aspectRatio;
    
    return outVertex;
}

#pragma mark - Fragment Shader: No Mask

fragment float4 SampleTexture(VertexOut const mappingVertex [[stage_in]],
                             texture2d<float, access::sample> const texture [[texture(0)]]) {
    constexpr sampler textureSampler {
        address::clamp_to_edge,
        mag_filter::linear,
        min_filter::linear,
        mip_filter::linear
    };
    
    return texture.sample(textureSampler, mappingVertex.textureCoordinate.xy);
}

#pragma mark Fragment Shader: Square Mask

float inline AlphaValueForSquareMask(float2 const localPosition, float const aspectRatio) {
    auto constexpr square = float4(-1.0f, -1.0f, 1.0f, 1.0f);
    auto const squareStep = step(square.xy, localPosition) * step(localPosition, square.zw);
    
    return 1.0f - squareStep.x * squareStep.y;
}

fragment float4 SampleTextureWithSquareMask(VertexOut const vertexData [[stage_in]],
                                           texture2d<float, access::sample> const texture [[texture(0)]]) {
    constexpr sampler textureSampler {
        address::clamp_to_edge,
        mag_filter::linear,
        min_filter::linear,
        mip_filter::linear
    };
    
    auto constexpr clearColour = float4(0.0f);
    auto const alpha = AlphaValueForSquareMask(vertexData.localPosition, vertexData.aspectRatio);
    auto const sample = texture.sample(textureSampler, vertexData.textureCoordinate);
    
    return mix(sample, clearColour, alpha);
}

#pragma mark Fragment Shader: Circular Mask

float inline AlphaValueForCircularMask(float2 const localPosition, float const aspectRatio) {
    auto const delta = length(localPosition);
    auto const width = fwidth(delta);
    
    return smoothstep(1.0f - width, 1.0f, delta);
}

fragment float4 SampleTextureWithCircularMask(VertexOut const vertexData [[stage_in]],
                                              texture2d<float, access::sample> const texture [[texture(0)]]) {
    constexpr sampler textureSampler {
        address::clamp_to_edge,
        mag_filter::linear,
        min_filter::linear,
        mip_filter::linear
    };
    
    auto constexpr clearColour = float4(0.0f);
    auto const alpha = AlphaValueForCircularMask(vertexData.localPosition, vertexData.aspectRatio);
    auto const sample = texture.sample(textureSampler, vertexData.textureCoordinate);
    
    return mix(sample, clearColour, alpha);
}

#pragma mark Fragment Shader: Hexagonal Mask

auto inline SmoothMin(float const a, float const b, float const smoothingFactor) -> float {
    auto const h = max(smoothingFactor - abs(a - b), 0.0f) / smoothingFactor;
    return min(a, b) - h * h * h * smoothingFactor / 6.0f;
}

auto inline SmoothMax(float const a, float const b, float const smoothingFactor) -> float {
    return -SmoothMin(-a, -b, smoothingFactor);
}

auto inline DistanceFromHexagonCentre(float2 const localPosition, float const roundingFactor) -> float {
    auto const absolutePosition = abs(localPosition);
    return SmoothMax(SmoothMax((absolutePosition.x * 0.866025f + absolutePosition.y * 0.5f), absolutePosition.y, roundingFactor),
                     SmoothMax((absolutePosition.x * 0.866025f - absolutePosition.y * 0.5f), absolutePosition.y - roundingFactor, roundingFactor),
                     roundingFactor);
}

auto inline AlphaValueForHexagonalMask(float2 const localPosition, float const aspectRatio) -> float {
    auto const distanceFromCentre = DistanceFromHexagonCentre(localPosition, 0.05f) * 1.1547005384f;
    auto const delta = fwidth(distanceFromCentre);
    
    return smoothstep(1.0f - delta, 1.0f, distanceFromCentre);
}

fragment float4 SampleTextureWithHexagonalMask(VertexOut const vertexData [[stage_in]],
                                              texture2d<float, access::sample> const texture [[texture(0)]]) {
    constexpr sampler textureSampler {
        address::clamp_to_edge,
        mag_filter::linear,
        min_filter::linear,
        mip_filter::linear
    };
    
    auto constexpr clearColour = float4(0.0f);
    auto const alpha = AlphaValueForHexagonalMask(vertexData.localPosition, vertexData.aspectRatio);
    auto const sample = texture.sample(textureSampler, vertexData.textureCoordinate);
    
    return mix(sample, clearColour, alpha);
}
