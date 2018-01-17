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
			if defined(OpenGL)
				_glBlitter.Fill(
					localRect, localToClipTransform, color);
			else
				build_error;
		}
	}
}
