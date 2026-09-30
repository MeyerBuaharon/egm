shader_type canvas_item;
render_mode unshaded;
varying vec4 vertex_tint;
void vertex() { vertex_tint=COLOR; }
uniform int class_id=0;
uniform int appearance=0;
uniform bool wear_0=false;
uniform bool wear_1=false;
uniform bool wear_2=false;
uniform bool wear_3=false;
uniform vec4 armor_0:source_color=vec4(0.4,0.5,0.65,1.0);
uniform vec4 armor_1:source_color=vec4(0.15,0.25,0.4,1.0);
uniform vec4 armor_2:source_color=vec4(0.4,0.5,0.65,1.0);
uniform vec4 armor_3:source_color=vec4(0.4,0.5,0.65,1.0);
uniform vec2 source_anchor=vec2(210.0,260.0);
uniform vec2 head_at=vec2(220.0,65.0);
uniform vec2 hand_a=vec2(-10000.0);
uniform vec2 hand_b=vec2(-10000.0);
uniform float pixel_scale=0.29;
void fragment() {
	vec4 original=texture(TEXTURE,UV);
	if(original.a<0.5) discard;
	vec3 c=original.rgb;
	vec2 px=UV/TEXTURE_PIXEL_SIZE;
	vec2 body=(px-source_anchor)*pixel_scale;
	float lum=dot(c,vec3(0.3,0.5,0.2));
	float head_distance=length((px-head_at)*pixel_scale/vec2(10.0,12.0));
	float hands=min(distance(px,hand_a),distance(px,hand_b))*pixel_scale;
	bool green=c.g>c.r*1.1 && c.g>c.b*(class_id==1 ? 0.88 : 1.08);
	bool metal=c.b>c.r*0.92 && c.g>c.r*0.9 && lum<0.70;
	bool gold=c.r>c.g*1.06 && c.r<c.g*2.2 && c.g>c.b*1.3 && c.g>0.15;
	bool leather=c.r>c.b*1.2 && c.r>0.08 && c.g>c.r*0.45;
	bool bone=min(c.r,min(c.g,c.b))>0.36 && max(c.r,max(c.g,c.b))-min(c.r,min(c.g,c.b))<0.32;
	bool cloth=class_id==0 ? metal : green;
	// Dye follows the existing painted surfaces. No silhouette deformation or
	// independent limb patches; the authored animation remains unchanged.
	if(appearance>0 && cloth && lum>0.06) {
		vec3 palette=appearance==1 ? vec3(0.40,0.15,0.09) : (appearance==2 ? vec3(0.20,0.39,0.48) : vec3(0.15,0.35,0.20));
		c=mix(c,palette*(0.45+lum*2.0),0.7);
	}
	if(wear_1 && lum>0.06 && cloth && head_distance>1.0 && body.y<-18.0) c=armor_1.rgb*(0.35+lum*1.7);
	if(wear_3 && lum>0.06 && hands>12.0 && body.y>-24.0 && (class_id==3 ? (gold||bone) : (class_id==0 ? (metal||gold) : leather))) c=armor_3.rgb*(0.3+lum*1.9);
	bool waist=abs(body.x)<10.0 && body.y>-35.0 && body.y<-15.0;
	bool glove=class_id==0 ? (gold && head_distance>1.0 && body.y<-22.0 && abs(body.x)>6.0) : (hands<10.0 && !waist && (class_id==3 ? (gold||bone) : ((leather && lum<0.32) || (metal && lum<0.18))));
	if(wear_2 && glove && lum>0.06 && lum<0.85) c=armor_2.rgb*(0.4+lum*1.7);
	if(wear_0 && lum>0.06 && head_distance<1.0 && (class_id==0 ? (metal||gold) : (class_id==3 && bone))) c=armor_0.rgb*(0.45+lum*1.5);
	COLOR=vec4(c,1.0)*vertex_tint;
}
