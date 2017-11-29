using Uno;
using Uno.Compiler.ExportTargetInterop;
using Uno.Graphics;
using Uno.IO;
using Uno.UX;
using OpenGL;

namespace Fuse.Internal.Bitmaps
{
	[ForeignInclude(Language.Java,
		"android.graphics.Bitmap", "android.graphics.BitmapFactory",
		"java.io.InputStream", "java.nio.ByteBuffer",
		"com.fuse.android.ByteBufferInputStream",
		"com.uno.UnoBackedByteBuffer")]
	extern(Android) static class AndroidHelpers
	{
		[Foreign(Language.Java)]
		public static void Recycle(Java.Object bitmap)
		@{
			((Bitmap)bitmap).recycle();
		@}

		[Foreign(Language.Java)]
		public static Java.Object DecodeFromBundle(string pathName)
		@{
			try
			{
				InputStream stream = com.fuse.Activity.getRootActivity().getAssets().open(pathName);
				BitmapFactory.Options opts = new BitmapFactory.Options();
				Bitmap ret = android.graphics.BitmapFactory.decodeStream(stream, null, opts);
				if (opts.outMimeType != null && !(opts.outMimeType.equals("image/png") || opts.outMimeType.equals("image/jpeg")))
				{
					@{Fuse.Diagnostics.UserWarning(string, object, string, int, string):Call("Non-portable image-format loaded", null, "", 0, "")};
				}
				return ret;
			}
			catch (Exception e)
			{
				e.printStackTrace();
				return null;
			}
		@}

		[Foreign(Language.Java)]
		public static Java.Object DecodeFromUnoBackedByteBuffer(Java.Object unoBackedByteBuffer)
		@{
			ByteBufferInputStream inputStream = new ByteBufferInputStream((UnoBackedByteBuffer)unoBackedByteBuffer);
			return BitmapFactory.decodeStream(inputStream);
		@}

		[Foreign(Language.Java)]
		public static Java.Object CreateScaledBitmap(Java.Object bitmap, int width, int height, bool filter)
		@{
			return Bitmap.createScaledBitmap((Bitmap)bitmap, width, height, filter);
		@}

		[Foreign(Language.Java)]
		static int GetWidth(Java.Object bitmap)
		@{
			return ((Bitmap)bitmap).getWidth();
		@}

		[Foreign(Language.Java)]
		static int GetHeight(Java.Object bitmap)
		@{
			return ((Bitmap)bitmap).getHeight();
		@}

		public static int2 GetSize(Java.Object bitmap)
		{
			return new int2(GetWidth(bitmap), GetHeight(bitmap));
		}

		[Foreign(Language.Java)]
		public static int GetPixel(Java.Object bitmap, int x, int y)
		@{
			return ((Bitmap)bitmap).getPixel(x, y);
		@}
	}

	[ForeignInclude(Language.ObjC, "ImageIO/ImageIO.h")]
	[ForeignInclude(Language.ObjC, "CoreGraphics/CoreGraphics.h")]
	[Require("Xcode.Framework", "ImageIO")]
	extern(iOS) static class IOSHelpers
	{
		[Foreign(Language.ObjC)]
		public static IntPtr CreateImageFromBundlePath(string path)
		@{
			NSURL* url = [[NSBundle mainBundle] URLForResource:path withExtension:@""];
			CGImageSourceRef imageSource = CGImageSourceCreateWithURL((__bridge CFURLRef)url, NULL);
			return CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
		@}

		[Foreign(Language.ObjC)]
		public static IntPtr CreateImageFromByteArray(byte[] bytes)
		@{
			CFDataRef data = CFDataCreateWithBytesNoCopy(NULL, (const UInt8 *)bytes.unoArray->Ptr(), bytes.unoArray->Length(), kCFAllocatorNull);
			CGImageSourceRef imageSource = CGImageSourceCreateWithData(data, NULL);
			return CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
		@}

		[Foreign(Language.ObjC)]
		static int GetWidth(IntPtr image)
		@{
			return (int)CGImageGetWidth((CGImageRef)image);
		@}

		[Foreign(Language.ObjC)]
		static int GetHeight(IntPtr image)
		@{
			return (int)CGImageGetHeight((CGImageRef)image);
		@}

		public static int2 GetSize(IntPtr image)
		{
			return new int2(GetWidth(image), GetHeight(image));
		}

		[Foreign(Language.ObjC)]
		public static void Release(IntPtr image)
		@{
			CGImageRelease((CGImageRef)image);
		@}

		[Foreign(Language.ObjC)]
		public static uint ReadPixel(IntPtr image, int x, int y)
		@{
			CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
			CGContextRef context = CGBitmapContextCreate(NULL, 1, 1, 8, 0, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrderDefault);

			int width = (int)CGImageGetWidth((CGImageRef)image);
			int height = (int)CGImageGetHeight((CGImageRef)image);
			CGRect rect = CGRectMake(-x, 1 + y - height, width, height);

			CGContextDrawImage(context, rect, (CGImageRef)image);
			const UInt8* pixel = (const UInt8*)CGBitmapContextGetData(context);

			int r = pixel[0];
			int g = pixel[1];
			int b = pixel[2];
			int a = pixel[3];

			if (a > 0)
			{
				// divide out alpha
				r = (r * 255) / a;
				g = (g * 255) / a;
				b = (b * 255) / a;
			}

			CGContextRelease(context);

			return b | (g << 8) | (r << 16) | (a << 24); // encode as 0xAARRGGBB
		@}
	}

	[Require("Header.Include", "uBase/BufferStream.h")]
	[Require("Header.Include", "uImage/Bitmap.h")]
	[Require("Header.Include", "uImage/Png.h")]
	[Require("Header.Include", "uImage/Jpeg.h")]
	[Require("Header.Include", "Uno/Support.h")]
	extern(!Android && !iOS && CPLUSPLUS) static class CPlusPlusHelpers
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
			else if defined(Android)
			{
				AndroidHelpers.Recycle(_nativeBitmap);
				_nativeBitmap = null;
			}
			else if defined (iOS)
			{
				IOSHelpers.Release(_nativeImage);
				_nativeImage = IntPtr.Zero;
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

		extern(Android) Java.Object _nativeBitmap;
		extern(Android) internal Java.Object NativeBitmap { get { return _nativeBitmap; } }
		extern(Android) protected Bitmap(Java.Object nativeBitmap)
		{
			_nativeBitmap = nativeBitmap;
			_size = AndroidHelpers.GetSize(nativeBitmap);
		}

		extern(iOS) IntPtr _nativeImage;
		extern(iOS) internal IntPtr NativeImage { get { return _nativeImage; } }
		extern(iOS) protected Bitmap(IntPtr nativeImage)
		{
			_nativeImage = nativeImage;
			_size = IOSHelpers.GetSize(nativeImage);
		}

		extern(!Android && !iOS && CPLUSPLUS) CPlusPlusHelpers.NativeBitmapHandle _nativeBitmap;
		extern(!Android && !iOS && CPLUSPLUS) internal CPlusPlusHelpers.NativeBitmapHandle NativeBitmap { get { return _nativeBitmap; } }
		extern(!Android && !iOS && CPLUSPLUS) protected Bitmap(CPlusPlusHelpers.NativeBitmapHandle nativeBitmap)
		{
			_nativeBitmap = nativeBitmap;
			_size = CPlusPlusHelpers.GetSize(nativeBitmap);
		}

		static Bitmap LoadFromBundleFile(BundleFile bundleFile)
		{
			if defined(CIL)
				return LoadFromStream(bundleFile.OpenRead());
			else if defined(Android)
			{
				var nativeBitmap = AndroidHelpers.DecodeFromBundle(bundleFile.BundlePath);
				return new Bitmap(nativeBitmap);
			}
			else if defined(iOS)
			{
				var nativeImage = IOSHelpers.CreateImageFromBundlePath("data/" + bundleFile.BundlePath);
				return new Bitmap(nativeImage);
			}
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
			if defined(Android)
			{
				var unoBackedByteBuffer = ForeignDataView.Create(data);
				var nativeBitmap = AndroidHelpers.DecodeFromUnoBackedByteBuffer(unoBackedByteBuffer);
				return new Bitmap(nativeBitmap);
			}
			else if defined(iOS)
			{
				var nativeImage = IOSHelpers.CreateImageFromByteArray(data);
				return new Bitmap(nativeImage);
			}
			else
			{
				var nativeBitmap = CPlusPlusHelpers.LoadFromByteArray(pathHint, data);
				return new Bitmap(nativeBitmap);
			}
		}

		static extern(CIL) System.Drawing.Bitmap ToPArgb(System.Drawing.Bitmap input)
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
			return new Bitmap(ToPArgb(nativeBitmap));
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

			if defined(Android)
			{
				var color = AndroidHelpers.GetPixel(NativeBitmap, x, y);
				return Color.FromArgb((uint)color);
			}
			else if defined(iOS)
			{
				var color = IOSHelpers.ReadPixel(NativeImage, x, y);
				return Color.FromArgb((uint)color);
			}
			else if defined(CIL)
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

		public Bitmap ScaleBilinear(int2 size)
		{
			if defined(Android)
				return new Bitmap(AndroidHelpers.CreateScaledBitmap(NativeBitmap, size.X, size.Y, true));
			else
				build_error;
		}
	}
}
