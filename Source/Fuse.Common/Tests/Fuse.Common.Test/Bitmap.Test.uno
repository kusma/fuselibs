using FuseTest;
using Fuse.Internal.Bitmaps;

using Uno;
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

		int MajorComponent(float3 rgb)
		{
			var max = Math.Max(rgb.X, Math.Max(rgb.Y, rgb.Z));
			if (rgb.X == max)
				return 0;
			else if (rgb.Y == max)
				return 1;
			else
				return 2;
		}

		[Test]
		[Ignore("Not supported in uBitmap", "CPlusPlus && !Android && !iOS")]
		public void CmykJPG()
		{
			var p = new UX.BitmapTest();

			var cmykJpg = Bitmap.LoadFromFile(p.CmykJPG.File);
			Assert.AreNotEqual(null, cmykJpg);
			Assert.AreEqual(3, cmykJpg.Size.X);
			Assert.AreEqual(2, cmykJpg.Size.Y);

			/* CMYK decoding varies so much from target to target,
			 * that comparing them directly doesn't really work.
			 *
			 * This test isn't really about the decoding precision,
			 * but rather that the image decodes at all, and that
			 * it orders the pixels somewhat correctl. So
			 * let's check the major color component to see if the
			 * colors are correctly ordered instead.
			 */
			Assert.AreEqual(0, MajorComponent(cmykJpg.GetPixel(0, 0).XYZ));
			Assert.AreEqual(1, cmykJpg.GetPixel(0, 0).W);
			Assert.AreEqual(1, MajorComponent(cmykJpg.GetPixel(1, 0).XYZ));
			Assert.AreEqual(1, cmykJpg.GetPixel(1, 0).W);
			Assert.AreEqual(2, MajorComponent(cmykJpg.GetPixel(2, 0).XYZ));
			Assert.AreEqual(1, cmykJpg.GetPixel(2, 0).W);
			Assert.AreEqual(2, MajorComponent(cmykJpg.GetPixel(0, 1).XYZ));
			Assert.AreEqual(1, cmykJpg.GetPixel(0, 1).W);
			Assert.AreEqual(1, MajorComponent(cmykJpg.GetPixel(1, 1).XYZ));
			Assert.AreEqual(1, cmykJpg.GetPixel(1, 1).W);
			Assert.AreEqual(0, MajorComponent(cmykJpg.GetPixel(2, 1).XYZ));
			Assert.AreEqual(1, cmykJpg.GetPixel(2, 1).W);
		}
	}
}
