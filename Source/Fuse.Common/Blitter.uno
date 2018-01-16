using Uno;
using Uno.Graphics;

namespace Fuse.Common
{
	class Blitter
	{
		[Flags]
		public enum BlitFlags
		{
			None = 0,
			NonPreMultiplied = 1
		}

		internal static Blitter Singleton = new Blitter();

		public void Blit(texture2D texture, Rect rect, float4x4 localToClipTransform, float opacity = 1.0f, bool flipY = false)
		{
			float3x3 textureTransform = float3x3.Identity;
			if (flipY)
			{
				textureTransform.M22 = -1;
				textureTransform.M32 =  1;
			}

			Blit(texture, SamplerState.LinearClamp,
			     new Rect(float2(0, 0), float2(1, 1)), textureTransform,
			     rect, localToClipTransform,
			     float4(1, 1, 1, opacity));
		}

		extern(OpenGL) Internal.GLBlitter _glBlitter = new Internal.GLBlitter();

		public void Blit(Texture2D texture, SamplerState samplerState,
		                 Rect textureRect, float3x3 textureTransform,
		                 Rect localRect, float4x4 localToClipTransform,
		                 float4 color, BlitFlags flags = BlitFlags.None)
		{
			if defined(OpenGL)
				_glBlitter.Blit(
					texture, samplerState,
					textureRect, textureTransform,
					localRect, localToClipTransform,
					color, flags);
			else
				build_error;
		}

		public void Fill(Rect localRect, float4x4 localToClipTransform, float4 color)
		{
			color = float4(color.XYZ * color.W, color.W);

			var positionTranslation = Matrix.Translation(localRect.Minimum.X, localRect.Minimum.Y, 0);
			var positionScaling = Matrix.Scaling(localRect.Size.X, localRect.Size.Y, 1);
			var positionMatrix = Matrix.Mul(Matrix.Mul(positionScaling, positionTranslation), localToClipTransform);

			draw
			{
				BlendEnabled: true;
				BlendSrcRgb: BlendOperand.One;
				BlendDstRgb: BlendOperand.OneMinusSrcAlpha;
				BlendSrcAlpha: BlendOperand.OneMinusDstAlpha;
				BlendDstAlpha: BlendOperand.One;

				CullFace : PolygonFace.None;
				DepthTestEnabled: false;
				float2[] verts: readonly new float2[] {

					float2(0,0),
					float2(1,0),
					float2(1,1),
					float2(0,0),
					float2(1,1),
					float2(0,1)
				};

				float2 v: vertex_attrib(verts);
				ClipPosition: Vector.Transform(v, positionMatrix);
				PixelColor: color;
			};
		}
	}
}
