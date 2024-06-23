#version 460
layout (location = 0) in vec3 aPos;
layout (location = 1) in vec4 aColor;
layout (location = 2) in vec2 aTexCoord;

uniform vec2 windowSize;

layout (location = 0) out vec4 vColor;
layout (location = 1) out vec2 vTexCoord;
layout (location = 2) out vec2 fill_texture_coord;

/*
Todo(Leo): this is now flipped on y axis, maybe not good, since this
means that quads are also flipped and this is "correcting error with
an error" or "two wrongs dont make a right". Will probably be fixed
when everything is moved here.
*/
const vec2 fill_texture_coords [4] = vec2[4](
    vec2(0,1),
    vec2(1,1),
    vec2(0,0),
    vec2(1,0)
);

void main()
{
    float x = 2 * aPos.x / windowSize.x - 1.0;
    float y = 1.0 - 2 * aPos.y / windowSize.y ;
    
    gl_Position = vec4(x, y, 0.0, 1.0);
    vColor = aColor;
    vTexCoord = aTexCoord;

    fill_texture_coord = fill_texture_coords[gl_VertexID];
}