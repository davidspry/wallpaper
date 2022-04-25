//
//  Shaders.h
//  Wallpaper
//
//  Created by David Spry on 12/4/22.
//

#pragma once

#include <metal_stdlib>

enum MaskType {
    Rectangle, Square, Circle, Hexagon
};

typedef struct {
    metal::float4x4 viewProjectionMatrix;
} Uniforms;

typedef struct {
    metal::float4x4 modelMatrix;
} VertexIn;

typedef struct {
    float4 position [[position]];
    float2 localPosition;
    float2 textureCoordinate;
    float aspectRatio;
} VertexOut;
