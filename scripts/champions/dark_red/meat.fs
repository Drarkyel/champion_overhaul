#ifndef GL_ES
#define lowp
#define mediump
#endif

varying lowp vec4 Color0;
varying mediump vec2 TexCoord0;
varying lowp vec4 ColorizeOut;
varying lowp vec3 ColorOffsetOut;
varying lowp vec2 TextureSizeOut;
varying lowp float PixelationAmountOut;
varying lowp vec3 ClipPlaneOut;
varying lowp vec4 ChampionColorOut;

uniform sampler2D Texture0;

#define USE_PREMULTIPLIED_ALPHA

void main(void)
{
    // ---------- Clip ----------
    if(dot(gl_FragCoord.xy, ClipPlaneOut.xy) < ClipPlaneOut.z)
        discard;

    // ---------- Pixelate ----------
    vec2 pa = vec2(
        1.0 + PixelationAmountOut,
        1.0 + PixelationAmountOut
    ) / TextureSizeOut;

    vec4 SourceColor = texture2D(
        Texture0,
        PixelationAmountOut > 0.0
            ? TexCoord0 - mod(TexCoord0, pa) + pa * 0.5
            : TexCoord0
    );

    // ---------- Empty pixels ----------
    if(SourceColor.a == 0.0)
        discard;

    // ---------- Translucent Champion ----------
    SourceColor.rgb = vec3(0.545, 0.0, 0.0);
    SourceColor.a = 1.0;

    // ---------- Final ----------
    vec4 Color = Color0 * SourceColor;

    gl_FragColor = Color;

    // ---------- Color reduction ----------
    gl_FragColor.rgb = mix(
        gl_FragColor.rgb,
        gl_FragColor.rgb - mod(gl_FragColor.rgb, 1.0 / 16.0),
        clamp(PixelationAmountOut, 0.0, 1.0)
    );
}
