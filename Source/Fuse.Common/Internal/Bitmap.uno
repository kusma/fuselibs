using Uno;
using Uno.Compiler.ExportTargetInterop;
using Uno.Graphics;
using Uno.IO;
using Uno.UX;
using OpenGL;

namespace Fuse.Internal.Bitmaps
{
	[Require("Header.Include", "uBase/BufferStream.h")]
	[Require("Header.Include", "uImage/Bitmap.h")]
	[Require("Header.Include", "uImage/Png.h")]
	[Require("Header.Include", "uImage/Jpeg.h")]
	[Require("Header.Include", "Uno/Support.h")]
	extern(CPLUSPLUS) static class CPlusPlusHelpers
	{
		[TargetSpecificType]
		[Set("TypeName", "uImage::Bitmap*")]
		[Set("DefaultValue", "NULL")]
		extern(CPLUSPLUS) internal struct NativeBitmapHandle
		{
		}

		[TargetSpecificType]
		[Set("TypeName", "uBase::Stream*")]
		[Set("DefaultValue", "NULL")]
		extern(CPLUSPLUS) internal struct NativeStreamHandle
		{
		}

		public static NativeStreamHandle NativeStreamFromCppXliStream(CppXliStream stream)
		@{
			return stream->_handle;
		@}

		static NativeBitmapHandle LoadPNGFromStream(NativeStreamHandle stream)
		@{
			try
			{
				uBase::Auto<uImage::ImageReader> ir = uImage::Png::CreateReader(stream);
				return ir->ReadBitmap();
			}
			catch (const uBase::Exception &e)
			{
				U_THROW(@{Uno.Exception(string):New(uStringFromXliString(e.GetMessage()))});
			}
		@}

		static NativeBitmapHandle LoadJPGFromStream(NativeStreamHandle stream)
		@{
			try
			{
				uBase::Auto<uImage::ImageReader> ir = uImage::Jpeg::CreateReader(stream);
				return ir->ReadBitmap();
			}
			catch (const uBase::Exception &e)
			{
				U_THROW(@{Uno.Exception(string):New(uStringFromXliString(e.GetMessage()))});
			}
		@}

		static NativeBitmapHandle Premultiply(NativeBitmapHandle bitmap)
		@{
			if (bitmap->GetFormat() != uImage::FormatRGBA_8_8_8_8_UInt_Normalize)
				return bitmap;

			int width = bitmap->GetWidth(), height = bitmap->GetHeight();
			for (int y = 0; y < height; ++y)
			{
				uint8_t *scanline = bitmap->GetScanlinePtr(y);
				for (int x = 0; x < width; ++x)
				{
					uint8_t *pixel = scanline + x * 4;
					pixel[0] = (pixel[0] * pixel[3]) / 255;
					pixel[1] = (pixel[1] * pixel[3]) / 255;
					pixel[2] = (pixel[2] * pixel[3]) / 255;
				}
			}
			return bitmap;
		@}

		static NativeBitmapHandle LoadFromNativeStream(string pathHint, NativeStreamHandle stream)
		{
			NativeBitmapHandle bitmap = default(NativeBitmapHandle);
			if (pathHint.ToLower().EndsWith(".png"))
			{
				try
				{
					bitmap = LoadPNGFromStream(stream);
				}
				catch (Exception outerException)
				{
					try
					{
						bitmap = LoadJPGFromStream(stream);
					}
					catch (Exception innerException)
					{
						 // both threw, but since the user asked for PNG, answer with the PNG-error
						throw outerException;
					}
				}
			}
			else
			{
				try
				{
					bitmap = LoadJPGFromStream(stream);
				}
				catch (Exception outerException)
				{
					try
					{
						bitmap = LoadPNGFromStream(stream);
					}
					catch (Exception innerException)
					{
						 // both threw, but since the user asked for JPEG, answer with the JPEG-error
						throw outerException;
					}
				}
			}

			return Premultiply(bitmap);
		}

		public static NativeBitmapHandle LoadFromByteArray(string pathHint, byte[] bytes)
		@{
			uBase::Auto<uBase::BufferPtr> buffer = new uBase::BufferPtr(bytes->Ptr(), bytes->Length(), false);
			uBase::Auto<uBase::BufferStream> stream = new uBase::BufferStream(buffer, true, false);
			return @{LoadFromNativeStream(string, NativeStreamHandle):Call(pathHint, stream)};
		@}

		public static NativeBitmapHandle LoadFromXliStream(string pathHint, CppXliStream stream)
		{
			var nativeStream = extern<NativeStreamHandle>(stream)"$0->_handle";
			return LoadFromNativeStream(pathHint, nativeStream);
		}

		public static void Dispose(NativeBitmapHandle nativeBitmap)
		@{
			delete nativeBitmap;
		@}

		static int GetWidth(NativeBitmapHandle nativeBitmap)
		@{
			return nativeBitmap->GetWidth();
		@}

		static int GetHeight(NativeBitmapHandle nativeBitmap)
		@{
			return nativeBitmap->GetHeight();
		@}

		public static int2 GetSize(NativeBitmapHandle nativeBitmap)
		{
			return new int2(GetWidth(nativeBitmap), GetHeight(nativeBitmap));
		}

		public static uint ReadPixel(NativeBitmapHandle nativeBitmap, int x, int y)
		@{
			uBase::Vector4u8 color = nativeBitmap->GetPixelColor(x, y);

			if (color.W > 0)
			{
				// divide out alpha
				color.X = (color.X * 255) / color.W;
				color.Y = (color.Y * 255) / color.W;
				color.Z = (color.Z * 255) / color.W;
			}

			return color.Z | (color.Y << 8) | (color.X << 16) | (color.W << 24); // encode as 0xAARRGGBB
		@}
	}

	[extern(CPLUSPLUS) Require("Header.Include", "uImage/Bitmap.h")]
	public sealed class Bitmap : IDisposable
	{
		public void Dispose()
		{
			if defined(CIL)
			{
				_nativeBitmap.Dispose();
				_nativeBitmap = null;
			}
			else if defined(CPLUSPLUS)
			{
				CPlusPlusHelpers.Dispose(_nativeBitmap);
				_nativeBitmap = default(CPlusPlusHelpers.NativeBitmapHandle);
			}
			else
				build_error;
		}

		readonly int2 _size;
		public int2 Size { get { return _size; } }

		extern(CIL) System.Drawing.Bitmap _nativeBitmap;
		extern(CIL) internal System.Drawing.Bitmap NativeBitmap { get { return _nativeBitmap; } }
		extern(CIL) protected Bitmap(System.Drawing.Bitmap nativeBitmap)
		{
			_nativeBitmap = nativeBitmap;
			_size = new int2(nativeBitmap.Width, nativeBitmap.Height);
		}

		extern(CPLUSPLUS) CPlusPlusHelpers.NativeBitmapHandle _nativeBitmap;
		extern(CPLUSPLUS) internal CPlusPlusHelpers.NativeBitmapHandle NativeBitmap { get { return _nativeBitmap; } }
		extern(CPLUSPLUS) protected Bitmap(CPlusPlusHelpers.NativeBitmapHandle nativeBitmap)
		{
			_nativeBitmap = nativeBitmap;
			_size = CPlusPlusHelpers.GetSize(nativeBitmap);
		}

		static Bitmap LoadFromBundleFile(BundleFile bundleFile)
		{
			if defined(CIL)
				return LoadFromStream(bundleFile.OpenRead());
			else if defined(CPLUSPLUS)
			{
				var stream = (CppXliStream)bundleFile.OpenRead();
				var nativeBitmap = CPlusPlusHelpers.LoadFromXliStream(bundleFile.Name, stream);
				return new Bitmap(nativeBitmap);
			}
			else
				build_error;
		}

		extern(CPLUSPLUS) static Bitmap LoadFromByteArray(string pathHint, byte[] data)
		{
			var nativeBitmap = CPlusPlusHelpers.LoadFromByteArray(pathHint, data);
			return new Bitmap(nativeBitmap);
		}

		static extern(CIL) System.Drawing.Bitmap Premultiply(System.Drawing.Bitmap input)
		{
			if (input.PixelFormat == System.Drawing.Imaging.PixelFormat.Format32bppPArgb)
				return input;

			var result = new System.Drawing.Bitmap(input.Width, input.Height, System.Drawing.Imaging.PixelFormat.Format32bppPArgb);
			using (System.Drawing.Graphics gr = System.Drawing.Graphics.FromImage(result))
			{
				gr.DrawImage(input, new System.Drawing.Rectangle(0, 0, result.Width, result.Height));
			}
			return result;
		}

		static extern(CIL) Bitmap LoadFromStream(Stream stream)
		{
			var nativeBitmap = new System.Drawing.Bitmap(stream);
			return new Bitmap(Premultiply(nativeBitmap));
		}

		public static Bitmap LoadFromFile(FileSource fileSource)
		{
			var bundleFileSource = fileSource as BundleFileSource;
			if (bundleFileSource != null)
				return LoadFromBundleFile(bundleFileSource.BundleFile);

			if defined(CIL)
				return LoadFromStream(fileSource.OpenRead());
			else if defined(CPLUSPLUS)
			{
				var data = fileSource.ReadAllBytes();
				return LoadFromByteArray(fileSource.Name, data);
			}
			else
				build_error;
		}

		public float4 GetPixel(int x, int y)
		{
			if (x < 0 || x >= Size.X)
				throw new ArgumentOutOfRangeException(nameof(x));
			if (y < 0 || y >= Size.Y)
				throw new ArgumentOutOfRangeException(nameof(y));

			if defined(CIL)
			{
				var color = NativeBitmap.GetPixel(x, y);
				return float4(color.R / 255.0f, color.G / 255.0f, color.B / 255.0f, color.A / 255.0f);
			}
			else if defined(CPLUSPLUS)
			{
				var color = CPlusPlusHelpers.ReadPixel(NativeBitmap, x, y);
				return Color.FromArgb(color);
			}
			else
				build_error;
		}
	}
}
