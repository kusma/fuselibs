using Uno;
using Uno.Compiler.ExportTargetInterop;
using Uno.Collections;

namespace OpenGL
{
	public extern(CPLUSPLUS && OPENGL) enum GLSyncCondition
	{
		GPUCommandsComplete = 0x9117
	}

	[Flags]
	public extern(CPLUSPLUS && OPENGL) enum GLFenceSyncFlags
	{
		None = 0
	}

	[Flags]
	public extern(CPLUSPLUS && OPENGL) enum GLWaitSyncFlags
	{
		None = 0,
		FlushCommandsBit = 0x00000001,
	}

	public extern(CPLUSPLUS && OPENGL) enum GLClientWaitSyncResult
	{
		Unsignaled      = 0x9118,
		Signaled        = 0x9119,
		AlreadySignaled = 0x911A,
		TimeoutExpired  = 0x911B
	}

	[TargetSpecificType]
	[Set("TypeName", "void *")] // We don't want to have to make sure the GLsync typedef is present everywhere a GLSyncHandle might be used.
	[Set("DefaultValue", "NULL")]
	public struct GLSyncHandle
	{
	}

	public extern(CPLUSPLUS && OPENGL) static class GLES3
	{
		static bool _initialized;
		static bool _supported;
		public static bool Supported { get { return _supported; } }

		public static void Initialize()
		{
			if (_initialized)
				return;

			var versionString = GL.GetString(GLStringName.Version);
			if (versionString.StartsWith("OpenGL ES "))
			{
				var majorVersionString = versionString.Substring(10).Split(new char[] { '.' })[0];
				try
				{
					_supported = int.Parse(majorVersionString) >= 3;
				}
				catch (FormatException e)
				{
					debug_log "**** Invalid version string: " + versionString;
				}
			}

			if (_supported)
				LoadFunctions();

			_initialized = true;
		}

		[Require("Source.Include", "XliPlatform/GL.h")]
		[Require("Source.Include", "EGL/egl.h")]
		[Require("Header.Declaration", "typedef struct __GLsync *GLsync;")]
		[Require("Header.Declaration", "typedef uint64_t GLuint64;")]
		[Require("Source.Declaration", "typedef GLsync (GL_APIENTRY * PFNGLFENCESYNCPROC) (GLenum, GLbitfield);\nstatic PFNGLFENCESYNCPROC glFenceSync = NULL;")]
		[Require("Source.Declaration", "typedef GLboolean (GL_APIENTRY * PFNGLISSYNCPROC) (GLsync);\nstatic PFNGLISSYNCPROC glIsSync = NULL;")]
		[Require("Source.Declaration", "typedef void (GL_APIENTRY * PFNGLDELETESYNCPROC) (GLsync);\nstatic PFNGLDELETESYNCPROC glDeleteSync = NULL;")]
		[Require("Source.Declaration", "typedef GLenum (GL_APIENTRY * PFNGLCLIENTWAITSYNCPROC) (GLsync, GLbitfield, GLuint64);\nstatic PFNGLCLIENTWAITSYNCPROC glClientWaitSync = NULL;")]
		[Require("Source.Declaration", "typedef void (GL_APIENTRY * PFNGLWAITSYNCPROC) (GLsync, GLbitfield, GLuint64);\nstatic PFNGLWAITSYNCPROC glWaitSync = NULL;")]
		static void LoadFunctions()
		@{
			glFenceSync = (PFNGLFENCESYNCPROC)eglGetProcAddress("glFenceSync");
			glIsSync = (PFNGLISSYNCPROC)eglGetProcAddress("glIsSync");
			glDeleteSync = (PFNGLDELETESYNCPROC)eglGetProcAddress("glDeleteSync");
			glClientWaitSync = (PFNGLCLIENTWAITSYNCPROC)eglGetProcAddress("glClientWaitSync");
			glWaitSync = (PFNGLWAITSYNCPROC)eglGetProcAddress("glWaitSync");
		@}

		public const ulong GLTimeoutIgnored = 0xFFFFFFFFFFFFFFFFL;

		public static GLSyncHandle FenceSync(GLSyncCondition condition, GLFenceSyncFlags flags = GLFenceSyncFlags.None)
		@{
			return glFenceSync($0, $1);
		@}

		public static bool IsSync(GLSyncHandle sync)
		@{
			return glIsSync($0);
		@}

		public static void DeleteSync(GLSyncHandle sync)
		@{
			glDeleteSync($0);
		@}

		public static GLClientWaitSyncResult ClientWaitSync(GLSyncHandle sync, GLWaitSyncFlags flags, ulong timeout)
		@{
			return glClientWaitSync($0, $1, $2);
		@}

		public static void WaitSync(GLSyncHandle sync, GLWaitSyncFlags flags, ulong timeout = GLTimeoutIgnored)
		@{
			glWaitSync($0, $1, $2);
		@}
	}
}
