using FuseTest;
using Fuse.Internal;
using Fuse.Internal.Bitmaps;
using Fuse.Drawing;

using Uno;
using Uno.IO;
using Uno.Graphics;
using Uno.Testing;
using OpenGL;

namespace Fuse.Test
{
	public class TextureHelperTest : TestBase
	{
		public TestFramebuffer CaptureTextureData(Texture2D texture)
		{
			var ret = new TestFramebuffer(texture.Size);
			GL.BindFramebuffer(GLFramebufferTarget.Framebuffer, ret.Framebuffer.RenderTarget.GLFramebufferHandle);
			GL.ClearColor(0, 0, 0, 0);
			GL.Clear(GLClearBufferMask.ColorBufferBit);
			GL.Viewport(0, 0, texture.Size.X, texture.Size.Y);

			// blit
			var localRect = new Rect(float2(-1), float2(2));
			var localToClipTransform = float4x4.Identity;
			Blitter.Singleton.Blit(texture, localRect, localToClipTransform);

			GL.BindFramebuffer(GLFramebufferTarget.Framebuffer, GLFramebufferHandle.Zero);
			return ret;
		}

		[Test]
		public void UploadBitmap()
		{
			var p = new UX.BitmapTest();

			var basicPng = Bitmap.LoadFromFile(p.BasicPNG.File);
			using (var tex = CaptureTextureData(TextureHelper.UploadBitmap(basicPng)))
			{
				float tolerance = 1.0f / 255;

				tex.AssertTexel(float4(1, 0, 0, 1), int2(0, 0), tolerance);
				tex.AssertTexel(float4(0, 1, 0, 1), int2(1, 0), tolerance);
				tex.AssertTexel(float4(0, 0, 1, 1), int2(2, 0), tolerance);

				tex.AssertTexel(float4(0, 0, 0.5f, 0.5f), int2(0, 1), tolerance);
				tex.AssertTexel(float4(0, 0.5f, 0, 0.5f), int2(1, 1), tolerance);
				tex.AssertTexel(float4(0.5f, 0, 0, 0.5f), int2(2, 1), tolerance);
			}
		}
	}
}
