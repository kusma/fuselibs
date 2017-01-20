using FuseTest;
using Fuse.Internal.Bitmaps;
using Uno.IO;
using Uno.Testing;

namespace Fuse.Test
{
	sealed class MemoryFileSource : Uno.UX.FileSource
	{
		readonly byte[] _bytes;

		public MemoryFileSource(string path, byte[] bytes) : base(path)
		{
			_bytes = bytes;
		}

		public override Stream OpenRead()
		{
			return new MemoryStream(_bytes);
		}
	}

	public class BitmapTest : TestBase
	{
		[Test]
		public void Basic()
		{
			var p = new UX.BitmapTest();

			var basicPng = Bitmap.LoadFromFile(p.BasicPNG.File);
			Assert.AreNotEqual(null, basicPng);
			Assert.AreEqual(3, basicPng.Size.X);
			Assert.AreEqual(2, basicPng.Size.Y);
			float eps = 1.0f / 255;
			Assert.AreEqual(new float4(1, 0, 0, 1), basicPng.GetPixel(0, 0), eps);
			Assert.AreEqual(new float4(0, 1, 0, 1), basicPng.GetPixel(1, 0), eps);
			Assert.AreEqual(new float4(0, 0, 1, 1), basicPng.GetPixel(2, 0), eps);
			Assert.AreEqual(new float4(0, 0, 1.0f, 0.5f), basicPng.GetPixel(0, 1), eps);
			Assert.AreEqual(new float4(0, 1.0f, 0, 0.5f), basicPng.GetPixel(1, 1), eps);
			Assert.AreEqual(new float4(1.0f, 0, 0, 0.5f), basicPng.GetPixel(2, 1), eps);

			var basicJpg = Bitmap.LoadFromFile(p.BasicJPG.File);
			Assert.AreNotEqual(null, basicJpg);
			Assert.AreEqual(3, basicJpg.Size.X);
			Assert.AreEqual(2, basicJpg.Size.Y);

			eps = 15.0f / 255; // JPEG is a bit more lossy
			Assert.AreEqual(new float4(1, 0, 0, 1), basicJpg.GetPixel(0, 0), eps);
			Assert.AreEqual(new float4(0, 1, 0, 1), basicJpg.GetPixel(1, 0), eps);
			Assert.AreEqual(new float4(0, 0, 1, 1), basicJpg.GetPixel(2, 0), eps);
			Assert.AreEqual(new float4(0, 0, 1, 1), basicJpg.GetPixel(0, 1), eps);
			Assert.AreEqual(new float4(0, 1, 0, 1), basicJpg.GetPixel(1, 1), eps);
			Assert.AreEqual(new float4(1, 0, 0, 1), basicJpg.GetPixel(2, 1), eps);

		}

		[Test]
		public void FromMemoryFileSource()
		{
			var p = new UX.BitmapTest();

			var basicPng = Bitmap.LoadFromFile(new MemoryFileSource(p.BasicPNG.File.Name, p.BasicPNG.File.ReadAllBytes()));
			Assert.AreNotEqual(null, basicPng);
			Assert.AreEqual(3, basicPng.Size.X);
			Assert.AreEqual(2, basicPng.Size.Y);
		}
	}
}
