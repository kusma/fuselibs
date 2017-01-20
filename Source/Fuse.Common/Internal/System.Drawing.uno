using Uno;
using Uno.Compiler.ExportTargetInterop;
using System.Drawing.Imaging;

namespace System.Drawing.Imaging
{
	[DotNetType]
	extern(CIL) public enum PixelFormat
	{
		Format32bppPArgb = 925707
	};

	[DotNetType]
	extern(CIL) public enum ImageLockMode
	{
		ReadOnly = 1,
		WriteOnly = 2,
		ReadWrite = 3,
		UserInputBuffer = 4
	}

	[DotNetType]
	extern(CIL) public sealed class BitmapData
	{
		public extern int Height { get; set; }
		public extern PixelFormat PixelFormat { get; set; }
		public extern IntPtr Scan0 { get; set; }
		public extern int Stride { get; set; }
		public extern int Width { get; set; }
	}
}

namespace System.Drawing
{
	[DotNetType]
	extern(CIL) public abstract class Image : IDisposable
	{
		public extern void Dispose();
		public extern int Width { get; }
		public extern int Height { get; }
		public extern PixelFormat PixelFormat { get; }
	}

	[DotNetType, TargetSpecificType]
	extern(CIL) public struct Color
	{
		public extern byte R { get; }
		public extern byte G { get; }
		public extern byte B { get; }
		public extern byte A { get; }
	}

	[DotNetType]
	extern(CIL) public struct Rectangle
	{
		public extern Rectangle(int x, int y, int width, int height);
	}

	[DotNetType]
	extern(CIL) public sealed class Bitmap : Image
	{
		public extern Bitmap(int width, int height, PixelFormat format);
		public extern Bitmap(Uno.IO.Stream stream);
		public extern Color GetPixel(int x, int y);
		public extern BitmapData LockBits(Rectangle rect, ImageLockMode flags, PixelFormat format);
	}

	[DotNetType]
	extern(CIL) public sealed class Graphics : IDisposable
	{
		public extern static Graphics FromImage(Image image);
		public extern void DrawImage(Image image, Rectangle rect);
	}
}
