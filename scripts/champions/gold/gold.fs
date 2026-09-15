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

const vec3 _lum = vec3(0.212671, 0.715160, 0.072169);

#define USE_PREMULTIPLIED_ALPHA

// CHAMPION CONFIG
const vec3 CHAMPION_COLOR = vec3(0.831, 0.686, 0.216);

// CHAMPION LOGIC
vec4 ChampionLogic(vec4 SourceColor)
{
    vec3 color = CHAMPION_COLOR;
    
    SourceColor = mix(
        vec4(color * dot(SourceColor.rgb, _lum), ChampionColorOut.a),
        vec4(SourceColor.rgb, 1.0),
        (SourceColor.a - 0.50196) * 2.00788
    );
    
    return SourceColor;
}

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
    
    // ---------- Remove empty alpha ----------
    if(SourceColor.a == 0.0)
        discard;
    
    // ---------- Adapt alpha ----------
    bool IgnoreChampionColor = false;

    if(SourceColor.a >= 0.5 && SourceColor.a <= 0.765)
    {
        SourceColor.a = 0.5;

        float value = max(
            SourceColor.r,
            max(SourceColor.g, SourceColor.b)
        );

        float center = 0.5;
        float strength = 0.25;
        
        value = center + (value - center) * strength;
        
        SourceColor.rgb = vec3(value);
    }
    else if(SourceColor.a > 0.765)
    {
        SourceColor.a = 1.0;
        IgnoreChampionColor = true;
    }

    // ---------- Alpha handling ----------
    if(SourceColor.a < 0.5)
    {
        #ifdef USE_PREMULTIPLIED_ALPHA
            SourceColor *= 2.00788;
        #else
            SourceColor.a *= 2.00788;
        #endif
    }
    else
    {
        #ifdef USE_PREMULTIPLIED_ALPHA
            // Despremultiply
            SourceColor.rgb /= SourceColor.a;

            // Apply champion
            if(!IgnoreChampionColor)
                SourceColor = ChampionLogic(SourceColor);

            // Repremultiply
            SourceColor.rgb *= SourceColor.a;
        #else
            SourceColor = ChampionLogic(SourceColor);
        #endif
    }

    // ---------- Final color pipeline ----------
    vec4 Color = Color0 * SourceColor;
    
    vec3 Colorized = mix(
        Color.rgb,
        dot(Color.rgb, _lum) * ColorizeOut.rgb,
        ColorizeOut.a
    );
    
    gl_FragColor = vec4(
        Colorized + ColorOffsetOut * Color.a,
        Color.a
    );

    // ---------- Color reduction ----------
    gl_FragColor.rgb = mix(
        gl_FragColor.rgb,
        gl_FragColor.rgb - mod(gl_FragColor.rgb, 1.0/16.0),
        clamp(PixelationAmountOut, 0.0, 1.0)
    );
}
