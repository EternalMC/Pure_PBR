//todo e

vec3 CalculateBokeh(vec2 screenCoord, vec2 offset) {
            const float lod  = 2.0;
            const float lod2 = exp2(lod);

            const float a = tau / LENS_BLADES;
            const mat2 rot = mat2(cos(a), -sin(a), sin(a), cos(a));

            const vec3 size  = 0.4 * vec3(1.0 - vec2(LENS_SHIFT, LENS_SHIFT * 0.5), 1.0);
            const vec3 size0 = size * LENS_SHARPNESS;
            const vec3 size1 = size * LENS_SHARPNESS * 0.8;

            vec2 coord = (screenCoord - offset) * lod2;

            float r = 0.0;

            const vec2 caddv = vec2(sin(LENS_ROTATION), -cos(LENS_ROTATION));
            vec2 addv = caddv;

            vec2 centerOffset = coord - 0.5;

            for(int i = 0; i < LENS_BLADES; ++i) {
                addv = rot * addv;
                r = max(r, dot(addv, centerOffset));
            }

            r = mix(r, fLength(centerOffset) * 0.8, LENS_ROUNDING);

            vec3 bokeh = saturate(1.0 - smoothstep(size0, size, vec3(r)));
                 bokeh = bokeh * (1.0 - saturate(smoothstep(size, size1, vec3(r)) * LENS_BIAS));

            return bokeh;
        }
