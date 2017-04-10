using Fuse;
using OpenGL;

class CallJSClosure
{
	readonly Context _context;
	readonly Function _func;
	
	public CallJSClosure(Context context, Function func)
	{
		_context = context;
		_func = func;
	}

	object _arg;
	public void Run(object arg)
	{	
		_arg = arg;
		_context.Dispatcher.Invoke(RunInternal);
	}
	
	void RunInternal()
	{
		_func.Call(_arg);
	}
}

public class CapturePanel : Panel
{
	static CapturePanel()
	{
		ScriptClass.Register(typeof(CapturePanel), new ScriptMethod<CapturePanel>("capture", CaptureAsync, ExecutionThread.MainThread));
	}

	static void CaptureAsync(Context ctx, CapturePanel capturePanel, object[] args)
	{
		var callback = args[0] as Function;
		capturePanel.TriggerCapture(ctx, callback);
	}

	CallJSClosure _captureCallback;

	public void TriggerCapture(Context ctx, Function captureCallback)
	{
		_captureCallback = new CallJSClosure(ctx, captureCallback);
		InvalidateVisual();
	}

	string Capture(DrawContext dc)
	{
		if defined (OpenGL)
		{
			var fb = CaptureRegion(dc, new Rect(0, 0, ActualSize.X, ActualSize.Y), float2(0));
			var buffer = new byte[fb.Size.X * fb.Size.Y * 4];

			dc.PushRenderTarget(fb);
			GL.PixelStore(GLPixelStoreParameter.PackAlignment, 1);
			GL.ReadPixels(0, 0, fb.Size.X, fb.Size.Y, GLPixelFormat.Rgba, GLPixelType.UnsignedByte, buffer);
			dc.PopRenderTarget();
			fb.Dispose();
		}

		var filename = "test.png";
		var path = Path.Combine(Directory.GetUserDirectory(UserDirectory.Data), filename);

		if defined(CPlusPlus)
			return SaveAsPng(buffer, size.X, size.Y, path);
		else
			build_error;
	}

	protected override void DrawWithChildren(DrawContext dc)
	{
		if (_captureNextFrame)
		{
			_captureNextFrame = false;

			var callback = _captureCallback;
			_captureCallback = null;

			callback.Run(Capture(dc));
		}

		base.DrawWithChildren(dc);
	}

	extern(CPlusPlus) public void SaveAsPng(byte[] data, int w, int h, string path)
	@{
		try
		{
			uBase::Buffer *buf = uBase::Buffer::CopyFrom(data, w * h * 4);

			uImage::Bitmap *bmp = new uImage::Bitmap(w, h, uImage::FormatRGBA_8_8_8_8_UInt_Normalize);
			int pitch = w * 4;
			// OpenGL stores the bottom scan-line first, PNG stores it last. Flip image while copying to compensate.
			for (int y = 0; y < h; ++y) {
				uint8_t *src = ((uint8_t*)data->Ptr()) + y * pitch;
				uint8_t *dst = bmp->GetScanlinePtr(h - y - 1);
				memcpy(dst, src, pitch);
			}

			uImage::Png::Save(uStringToXliString(path), bmp);
			delete bmp;
		}
		catch (const uBase::Exception &e)
		{
			U_THROW(@{Uno.Exception(string):New(uStringFromXliString(e.GetMessage()))});
		}
	@}
}
