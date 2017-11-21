using Uno;
using Uno.Compiler.ExportTargetInterop;
using Uno.Graphics;

using OpenGL;

using System.Drawing;
using System.Drawing.Imaging;

namespace System.Runtime.InteropServices
{
	[DotNetType]
	public extern(CIL) static class Marshal
	{
		public static extern void Copy(IntPtr source, byte[] destination, int start, int length);
	}
}

namespace Fuse.Internal.Bitmaps
{
	[ForeignInclude(Language.Java, "android.graphics.Bitmap", "android.opengl.GLES20", "android.opengl.GLUtils")]
	extern(Android) static class AndroidTextureHelpers
	{
		[Foreign(Language.Java)]
		public static void TexImage2D(int level, Java.Object bitmap, int border)
		@{
			GLUtils.texImage2D(GLES20.GL_TEXTURE_2D, level, (Bitmap)bitmap, border);
		@}
	}

	[Require("Source.Include", "XliPlatform/GL.h")]
	[Require("Source.Include", "CoreGraphics/CoreGraphics.h")]
	extern(iOS) static class IOSTextureHelpers
	{
		public static void TexImage2D(int level, IntPtr image, int border)
		@{
			CGImageRef imageRef = (CGImageRef)image;
			CFDataRef pixelData = CGDataProviderCopyData(CGImageGetDataProvider(imageRef));
			size_t width = CGImageGetWidth(imageRef);
			size_t height = CGImageGetHeight(imageRef);
			glTexImage2D(GL_TEXTURE_2D, level, GL_RGBA, (int)width, (int)height, border, GL_RGBA, GL_UNSIGNED_BYTE, CFDataGetBytePtr(pixelData));
			CFRelease(pixelData);
		@}
	}

	[Require("Header.Include", "uImage/Texture.h")]
	extern(CPLUSPLUS && !Android && !iOS) static class CPPTextureHelpers
	{
		public static GLTextureHandle UploadTexture(CPlusPlusHelpers.NativeBitmapHandle bitmap)
		@{
			uImage::Texture* texture = uImage::Texture::Create(bitmap);
			return uCreateGLTexture(texture, true, NULL);
		@}
	}

	extern(DOTNET) static class DotNetTextureHelpers
	{
		public static void TexImage2D(int level, System.Drawing.Bitmap bitmap, int border)
		{
			int width = bitmap.Width;
			int height = bitmap.Height;

			var data = bitmap.LockBits(new Rectangle(0, 0, width, height), ImageLockMode.ReadOnly, PixelFormat.Format32bppPArgb);

			var lineLength = data.Width * 4;
			var bytes = new byte[lineLength * data.Height];
			for (int y = 0; y < height; ++y)
			{
				var src = IntPtr.Add(data.Scan0, data.Stride * y);
				var lineOffset = lineLength * y;
				System.Runtime.InteropServices.Marshal.Copy(src, bytes, lineOffset, lineLength);
				for (int x = 0; x < width; ++x)
				{
					/* convert BGRA (little-endian ARGB as a byte-array) to RGBA by swapping R and B */
					var tmp = bytes[lineOffset + x * 4 + 0];
					bytes[lineOffset + x * 4 + 0] = bytes[lineOffset + x * 4 + 2];
					bytes[lineOffset + x * 4 + 2] = tmp;
				}
			}

			GL.TexImage2D(GLTextureTarget.Texture2D, level, GLPixelFormat.Rgba, width, height, border, GLPixelFormat.Rgba, GLPixelType.UnsignedByte, bytes);
		}
	}

	extern(OPENGL) public static class TextureHelper
	{
		// TODO: consider making this an extension method somewhere else instead?
		public static Texture2D UploadBitmap(Bitmap bitmap)
		{
			if defined(Android || iOS || DOTNET)
			{
				var textureHandle = GL.CreateTexture();
				GL.BindTexture(GLTextureTarget.Texture2D, textureHandle);
				GL.PixelStore(GLPixelStoreParameter.PackAlignment, 1);

				if defined(Android)
					AndroidTextureHelpers.TexImage2D(0, bitmap.NativeBitmap, 0);
				else if defined(iOS)
					IOSTextureHelpers.TexImage2D(0, bitmap.NativeImage, 0);
				else if defined(DOTNET)
					DotNetTextureHelpers.TexImage2D(0, bitmap.NativeBitmap, 0);
				else
					build_error;

				return new Texture2D(textureHandle, bitmap.Size, 1, Format.RGBA8888);
			}
			else if defined (CPLUSPLUS)
			{
				var textureHandle = CPPTextureHelpers.UploadTexture(bitmap.NativeBitmap);
				return new Texture2D(textureHandle, bitmap.Size, 1, Format.RGBA8888);
			}
			else
				build_error;
		}
	}
}
