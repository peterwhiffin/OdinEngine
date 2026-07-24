// Mesh_Uniforms :: struct {
// 	pos:   linalg.Vector4f32,
// 	color: linalg.Vector4f32,
// }

struct mesh_uniforms {
  float4 pos;
  float4 color;
};

struct VSOutput {
  float4 Pos : SV_POSITION;
  float2 UV;
};

[shader("vertex")]
VSOutput vertMain(uint vertex_id: SV_VertexID, mesh_uniforms *mu) {
  float2 pos[3] = {
    float2(-1.0, -1.0),
    float2(3.0, -1.0),
    float2(-1.0, 3.0),
  };

  VSOutput output;
  output.Pos = float4(pos[vertex_id], 0.0, 1.0);
  output.UV = pos[vertex_id] * 0.5 + 0.5;
  return output;
}

float sd_circle(float2 v, float r) { return length(v) - r; }

[shader("fragment")]
float4 fragMain(VSOutput input, mesh_uniforms *mu, float4 pos: SV_Position) {
  float3 final_color = float3(0.0);

  float map = sd_circle(mu.pos.xy - pos.xy, 200.0);

  if (map < 0.001) {
    final_color = float3(1.0);
  }

  return float4(final_color.rgb, 1.0);
}
