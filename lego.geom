#version 330 compatibility
#extension GL_EXT_gpu_shader4: enable
#extension GL_EXT_geometry_shader4: enable
layout( triangles )  in;
layout( triangle_strip, max_vertices=204 )  out;

uniform float uQuantize;
uniform int uLevel;
uniform float uLightX;
uniform float uLightY;
uniform float uLightZ;
uniform bool uModelCoords;

in vec3		vNormal[3];
out float	gLightIntensity;

vec3 V0, V01, V02;


float
Quantize( float f )
{
	f *= uQuantize;
	f += .5;		// round-off
	int fi = int( f );
	f = float( fi ) / uQuantize;
	return f;
}

vec3
QuantizedVertex( float s, float t )
{	
	//vec3 tn = V0 + s*V01 + t*V02;
	//tn = normalize(tn);
	vec3 v = V0 + s*V01 + t*V02;		// interpolate the vertex from s and t

	if( uModelCoords == false )
	{
		v = ( gl_ModelViewMatrix * vec4( v, 1 ) ).xyz;
	}
	

	v.x = Quantize( v.x );
	v.y = Quantize( v.y );
	v.z = Quantize( v.z );
	return v;
}


void
ProduceVertex( float s, float t )
{
	vec3 lightPos = vec3( uLightX, uLightY, uLightZ );

	vec3 v = QuantizedVertex( s, t );

	vec3 n = v;

	//vec3 n = ?????	// interpolate the normal from s and t
	//vec3 tnorm = ?????	// transformed normal

	vec3 tnorm = normalize( gl_NormalMatrix * n );

	vec4 ECposition;
	if( uModelCoords ==  true)
	{
		ECposition = gl_ModelViewMatrix * vec4( v, 1. );
	}
	else
	{
		ECposition = vec4( v, 1. );
	}

	gLightIntensity  = abs( dot( normalize(lightPos - ECposition.xyz), tnorm ) );

	gl_Position = gl_ProjectionMatrix * ECposition;
	EmitVertex();
}




void
main( )
{
V01 = ( gl_PositionIn[1] - gl_PositionIn[0] ).xyz;
V02 = ( gl_PositionIn[2] - gl_PositionIn[0] ).xyz;
V0 = gl_PositionIn[0].xyz;
int numLayers = 1 << uLevel;
float dt = 1. / float( numLayers );
float t_top = 1.;
//mputer Graphics
for( int it = 0; it < numLayers; it++ )
{
float t_bot = t_top - dt;
float smax_top = 1. - t_top;
float smax_bot = 1. - t_bot;
int nums = it + 1;
float ds_top = smax_top / float( nums - 1 );
float ds_bot = smax_bot / float( nums );
float s_top = 0.;
float s_bot = 0.;
for( int is = 0; is < nums; is++ )
{
ProduceVertex( s_bot, t_bot );
ProduceVertex( s_top, t_top );
s_top += ds_top;
s_bot += ds_bot;
}
ProduceVertex( s_bot, t_bot );
EndPrimitive( );
t_top = t_bot;
t_bot -= dt;
}
}